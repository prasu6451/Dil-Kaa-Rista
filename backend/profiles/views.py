import os
from django.conf import settings
from django.core.files.storage import default_storage
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from .models import (
    Profile,
    PartnerPreference,
    ProfileChangeRequest,
    BlockedMember,
    ReportedMember,
)
from .serializers import (
    ProfileSerializer,
    LimitedScreeningProfileSerializer,
    PartnerPreferenceSerializer,
    ProfileChangeRequestSerializer,
    BlockedMemberSerializer,
    ReportedMemberSerializer,
)


CORE_CR_FIELDS = ['date_of_birth', 'gender', 'marital_status', 'religion']
ALLOWED_PHOTO_EXTS = ['.jpg', '.jpeg', '.png', '.webp']
MAX_PHOTO_SIZE = 5 * 1024 * 1024  # 5 MB


class MyProfileView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def get(self, request):
        profile, _ = Profile.objects.get_or_create(
            user=request.user,
            defaults={
                'full_name': request.user.full_name or 'Member',
                'gender': request.user.gender or 'male',
            }
        )
        serializer = ProfileSerializer(profile)
        data = serializer.data
        data['is_limited_screening_view'] = (profile.verification_status != 'approved')
        return Response(data)

    def put(self, request):
        profile, _ = Profile.objects.get_or_create(
            user=request.user,
            defaults={
                'full_name': request.user.full_name or 'Member',
                'gender': request.user.gender or 'male',
            }
        )

        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)

        # Fallback for empty core fields so validation never fails unexpectedly
        if not data.get('full_name') or not str(data.get('full_name')).strip():
            data['full_name'] = profile.full_name or request.user.full_name or 'Member'
        if not data.get('gender') or not str(data.get('gender')).strip():
            data['gender'] = profile.gender or request.user.gender or 'male'
        if 'height_cm' in data and (data['height_cm'] == '' or data['height_cm'] is None):
            data['height_cm'] = profile.height_cm or 165
        if 'date_of_birth' in data and data['date_of_birth'] == '':
            data['date_of_birth'] = None

        cr_changes_submitted = []

        # Page 2: Core fields requiring Customer Relations review:
        # date of birth, gender, marital status, religion
        if profile.verification_status == 'approved':
            for core_field in CORE_CR_FIELDS:
                if core_field in data:
                    new_val = str(data[core_field])
                    old_val = str(getattr(profile, core_field, '') or '')
                    if new_val != old_val:
                        ProfileChangeRequest.objects.create(
                            profile=profile,
                            field_name=core_field,
                            old_value=old_val,
                            new_value=new_val,
                            status='pending'
                        )
                        cr_changes_submitted.append(core_field)
                    del data[core_field]

        # Free-text 'Other' hobbies subject to review (Page 2)
        if 'hobbies_other' in data and data['hobbies_other'] != profile.hobbies_other:
            profile.hobbies_other_status = 'pending'

        serializer = ProfileSerializer(profile, data=data, partial=True)
        if serializer.is_valid():
            serializer.save()
            resp_data = serializer.data
            if cr_changes_submitted:
                resp_data['cr_review_notice'] = (
                    f"Changes to {', '.join(cr_changes_submitted)} require Customer Relations review "
                    "and will become visible once verified."
                )
            return Response(resp_data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request):
        return self.put(request)


class ResubmitProfileView(APIView):
    """
    Page 1: If screening is rejected, the user receives a notification
    with the rejection reason and a 'Resubmit' option.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        profile = getattr(request.user, 'profile', None)
        if not profile:
            return Response({'error': 'Profile does not exist'}, status=status.HTTP_404_NOT_FOUND)

        if profile.verification_status == 'approved':
            return Response({'message': 'Profile is already approved and active.'}, status=status.HTTP_200_OK)

        profile.verification_status = 'under_review'
        profile.rejection_reason = None
        profile.save()

        return Response({
            'message': 'Profile resubmitted successfully for Customer Relations screening.',
            'profile': ProfileSerializer(profile).data
        }, status=status.HTTP_200_OK)


class ProfileDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, user_id):
        try:
            profile = Profile.objects.select_related('user').get(user__id=user_id)
        except Profile.DoesNotExist:
            return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

        current_user = request.user if request.user.is_authenticated else None

        # Check if hidden or blocked
        if current_user and current_user != profile.user:
            if BlockedMember.objects.filter(user=current_user, blocked_user=profile.user).exists():
                return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)
            if BlockedMember.objects.filter(user=profile.user, blocked_user=current_user).exists():
                return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)
            if ReportedMember.objects.filter(reporter=current_user, reported_user=profile.user).exists():
                return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

        # Page 1: During screening, profile is hidden from public entirely.
        is_owner = (current_user == profile.user)
        is_staff = (current_user and current_user.is_staff)

        if not (is_owner or is_staff):
            if profile.verification_status != 'approved' or profile.is_hidden:
                return Response({'error': 'Profile not found or currently unavailable'}, status=status.HTTP_404_NOT_FOUND)

        # If owner and under review, show limited screening view unless requested otherwise
        if is_owner and profile.verification_status != 'approved':
            return Response(LimitedScreeningProfileSerializer(profile).data)

        data = ProfileSerializer(profile).data

        # Photo privacy enforcement: visible only to contacted and accepted members
        if not (is_owner or is_staff) and profile.photo_privacy == 'contacted_accepted':
            from matches.models import MatchRequest
            is_connected = False
            if current_user:
                is_connected = MatchRequest.objects.filter(
                    status='accepted',
                    sender__in=[current_user, profile.user],
                    receiver__in=[current_user, profile.user]
                ).exists()
            if not is_connected:
                data['photos'] = []
                data['avatar_url'] = None
                data['photo_restricted'] = True

        return Response(data)


class ProfilePhotoUploadView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        file_obj = request.FILES.get('photo')
        if not file_obj:
            return Response({'error': 'No photo provided'}, status=status.HTTP_400_BAD_REQUEST)

        # Page 2 & 6: Max file size 5 MB
        if file_obj.size > MAX_PHOTO_SIZE:
            return Response({'error': 'Maximum photo file size is 5 MB.'}, status=status.HTTP_400_BAD_REQUEST)

        ext = os.path.splitext(file_obj.name)[1].lower() or '.jpg'
        if ext not in ALLOWED_PHOTO_EXTS:
            return Response({
                'error': f'Accepted formats are {", ".join(ALLOWED_PHOTO_EXTS)}.'
            }, status=status.HTTP_400_BAD_REQUEST)

        profile, _ = Profile.objects.get_or_create(
            user=request.user,
            defaults={'full_name': request.user.full_name, 'gender': request.user.gender}
        )

        # Page 2 & 6: Free users up to 5 photos, Premium up to 20 photos
        max_photos = 20 if profile.membership_tier in ('tier_1', 'tier_2') else 5
        current_photos = profile.photos or []
        if len(current_photos) >= max_photos:
            return Response({
                'error': f"Photo limit reached ({max_photos} photos). Upgrade to Premium to upload up to 20 photos."
            }, status=status.HTTP_403_FORBIDDEN)

        # Generate unique filename
        filename = f"avatars/{request.user.id}_{len(current_photos)}_{int(request.user.created_at.timestamp())}{ext}"
        saved_path = default_storage.save(filename, file_obj)
        file_url = request.build_absolute_uri(settings.MEDIA_URL + saved_path)

        if not current_photos:
            profile.avatar_url = file_url
        current_photos.append(file_url)
        profile.photos = current_photos
        profile.save()

        return Response({
            'message': 'Photo uploaded successfully',
            'url': file_url,
            'photos': profile.photos,
            'profile': ProfileSerializer(profile).data
        }, status=status.HTTP_200_OK)


class ReorderPhotosView(APIView):
    """
    Page 2: Users can reorder photos and select a primary photo.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        photos = request.data.get('photos')
        primary_index = request.data.get('primary_photo_index', 0)

        profile = getattr(request.user, 'profile', None)
        if not profile:
            return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

        if isinstance(photos, list):
            profile.photos = photos

        try:
            primary_index = int(primary_index)
            if 0 <= primary_index < len(profile.photos):
                profile.primary_photo_index = primary_index
                profile.avatar_url = profile.photos[primary_index]
        except (ValueError, TypeError):
            pass

        profile.save()
        return Response({
            'message': 'Photos reordered successfully',
            'photos': profile.photos,
            'primary_photo_index': profile.primary_photo_index,
            'avatar_url': profile.avatar_url,
        }, status=status.HTTP_200_OK)


class PartnerPreferenceView(APIView):
    """
    Page 2 & 3: Partner Preferences Tab with Must-have vs Flexible tracking
    and narrow criteria warning.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = Profile.objects.get_or_create(
            user=request.user,
            defaults={'full_name': request.user.full_name, 'gender': request.user.gender}
        )
        pref, _ = PartnerPreference.objects.get_or_create(profile=profile)
        serializer = PartnerPreferenceSerializer(pref)
        data = serializer.data
        if pref.has_narrow_criteria_warning:
            data['warning'] = "Your must-have criteria are very narrow. You may see fewer matches."
        return Response(data)

    def put(self, request):
        profile, _ = Profile.objects.get_or_create(
            user=request.user,
            defaults={'full_name': request.user.full_name, 'gender': request.user.gender}
        )
        pref, _ = PartnerPreference.objects.get_or_create(profile=profile)
        serializer = PartnerPreferenceSerializer(pref, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            data = serializer.data
            if pref.has_narrow_criteria_warning:
                data['warning'] = "Your must-have criteria are very narrow. You may see fewer matches."
            return Response(data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request):
        return self.put(request)


class PrivacySettingsView(APIView):
    """
    Page 3: Privacy and Safety Settings Tab
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = getattr(request.user, 'profile', None)
        if not profile:
            return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

        return Response({
            'is_hidden': profile.is_hidden,
            'display_name_format': profile.display_name_format,
            'custom_username': profile.custom_username,
            'photo_privacy': profile.photo_privacy,
            'phone_privacy': profile.phone_privacy,
            'call_permissions': profile.call_permissions,
            'call_hours_start': str(profile.call_hours_start) if profile.call_hours_start else None,
            'call_hours_end': str(profile.call_hours_end) if profile.call_hours_end else None,
            'horoscope_privacy': profile.horoscope_privacy,
            'chat_status': profile.chat_status,
        })

    def put(self, request):
        profile = getattr(request.user, 'profile', None)
        if not profile:
            return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

        fields = [
            'is_hidden', 'display_name_format', 'custom_username', 'photo_privacy',
            'phone_privacy', 'call_permissions', 'call_hours_start', 'call_hours_end',
            'horoscope_privacy', 'chat_status'
        ]
        for f in fields:
            if f in request.data:
                setattr(profile, f, request.data[f])
        profile.save()
        return self.get(request)

    def patch(self, request):
        return self.put(request)


class BlockMemberView(APIView):
    """
    Page 3: Block Member (Prevents viewing or contacting)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        blocked = BlockedMember.objects.filter(user=request.user)
        serializer = BlockedMemberSerializer(blocked, many=True)
        return Response(serializer.data)

    def post(self, request):
        target_id = request.data.get('user_id')
        if not target_id:
            return Response({'error': 'user_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        if str(request.user.id) == str(target_id):
            return Response({'error': 'Cannot block yourself'}, status=status.HTTP_400_BAD_REQUEST)

        from accounts.models import User
        try:
            target_user = User.objects.get(id=target_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        BlockedMember.objects.get_or_create(user=request.user, blocked_user=target_user)
        return Response({'message': f"Successfully blocked {target_user.full_name}."}, status=status.HTTP_200_OK)

    def delete(self, request):
        target_id = request.data.get('user_id')
        if not target_id:
            return Response({'error': 'user_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        BlockedMember.objects.filter(user=request.user, blocked_user_id=target_id).delete()
        return Response({'message': 'Member unblocked successfully.'}, status=status.HTTP_200_OK)


class ReportMisuseView(APIView):
    """
    Page 3: Report Misuse (Alerts CR team, profile hidden from reporter immediately)
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        target_id = request.data.get('user_id')
        reason = request.data.get('reason')
        details = request.data.get('details', '')

        if not target_id or not reason:
            return Response({'error': 'user_id and reason are required'}, status=status.HTTP_400_BAD_REQUEST)

        from accounts.models import User
        try:
            target_user = User.objects.get(id=target_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        ReportedMember.objects.create(
            reporter=request.user,
            reported_user=target_user,
            reason=reason,
            details=details,
            status='pending'
        )

        return Response({
            'message': 'Report submitted. Our Customer Relations Team has been alerted. This member is now hidden from your view.',
            'reported_user_id': str(target_user.id)
        }, status=status.HTTP_201_CREATED)

