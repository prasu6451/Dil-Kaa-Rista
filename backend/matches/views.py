from datetime import date
from django.db.models import Q
from django.utils import timezone
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny

from accounts.models import User
from profiles.models import Profile, PartnerPreference, BlockedMember, ReportedMember
from profiles.serializers import ProfileSerializer
from .models import MatchRequest, Shortlist, PhotoOrContactRequest, SavedSearch, SearchHistory
from .serializers import (
    MatchRequestSerializer,
    ShortlistSerializer,
    PhotoOrContactRequestSerializer,
    SavedSearchSerializer,
    SearchHistorySerializer,
)


def get_excluded_user_ids(current_user):
    if not current_user or not current_user.is_authenticated:
        return set()
    blocked_by_me = set(BlockedMember.objects.filter(user=current_user).values_list('blocked_user_id', flat=True))
    blocked_me = set(BlockedMember.objects.filter(blocked_user=current_user).values_list('user_id', flat=True))
    reported = set(ReportedMember.objects.filter(reporter=current_user).values_list('reported_user_id', flat=True))
    return blocked_by_me | blocked_me | reported | {current_user.id}


def build_match_reason(profile, user_profile, pref=None):
    reasons = []
    if pref:
        if pref.city and profile.city and pref.city.lower() in profile.city.lower():
            reasons.append("location")
        if pref.religion and profile.religion in pref.religion:
            reasons.append("religion")
        if pref.education and profile.education in pref.education:
            reasons.append("education")
        if pref.profession and profile.occupation in pref.profession:
            reasons.append("profession")
        if profile.age and pref.age_min and pref.age_max:
            if pref.age_min <= profile.age <= pref.age_max:
                reasons.append("age")
    
    if reasons:
        return f"Matches your {' and '.join(reasons[:2])} preferences"
    return "Matches your partner preferences"


class MatchesFeedView(APIView):
    """
    Page 4 & 5: Matches Tab
    1. Preferred Matches: Exactly match partner preferences
    2. Broader Matches: Match some preferences
    3. Reverse Matches: Members whose preferences match the user's profile
    4. Near Me: Matches in user's current city
    Refine Search Box: photo availability, mother tongue, country, state, city, education, profession.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        current_user = request.user if request.user.is_authenticated else None
        user_profile = getattr(current_user, 'profile', None) if current_user else None
        user_pref = getattr(user_profile, 'partner_preference', None) if user_profile else None

        # Base queryset: only approved and public profiles
        queryset = Profile.objects.select_related('user').filter(
            verification_status='approved',
            is_hidden=False
        )

        # Exclude self, blocked, and reported
        if current_user:
            excluded = get_excluded_user_ids(current_user)
            queryset = queryset.exclude(user__id__in=excluded)

            # Auto opposite gender
            if current_user.gender:
                g = current_user.gender.lower()
                if g == 'male':
                    queryset = queryset.filter(gender__iexact='female')
                elif g == 'female':
                    queryset = queryset.filter(gender__iexact='male')

        category = (request.query_params.get('category') or request.query_params.get('type') or 'preferred').lower()

        # 4. Near Me Tab
        if category == 'near_me':
            city_param = request.query_params.get('city') or (user_profile.city if user_profile else None)
            if city_param:
                queryset = queryset.filter(city__icontains=city_param.strip())

        # 3. Reverse Matches Tab
        elif category == 'reverse' and user_profile:
            # Members whose partner preferences match the current user's profile
            pref_q = Q()
            if user_profile.age:
                pref_q &= Q(user__profile__partner_preference__age_min__lte=user_profile.age) & \
                          Q(user__profile__partner_preference__age_max__gte=user_profile.age)
            if user_profile.religion:
                pref_q &= Q(user__profile__partner_preference__religion__contains=[user_profile.religion])
            queryset = queryset.filter(pref_q)

        # 1. Preferred Matches
        elif category == 'preferred' and user_pref:
            pref_q = Q()
            if user_pref.religion:
                pref_q &= Q(religion__in=user_pref.religion)
            if user_pref.mother_tongue:
                pref_q &= Q(mother_tongue__in=user_pref.mother_tongue)
            if user_pref.city:
                pref_q &= Q(city__icontains=user_pref.city)
            if user_pref.marital_status:
                pref_q &= Q(marital_status__in=user_pref.marital_status)
            queryset = queryset.filter(pref_q)

        # Refine Search Filters (Page 4)
        has_photo = request.query_params.get('has_photo')
        if has_photo in ('true', '1', 'yes'):
            queryset = queryset.exclude(avatar_url__isnull=True).exclude(avatar_url='')

        mother_tongue = request.query_params.get('mother_tongue')
        if mother_tongue:
            queryset = queryset.filter(mother_tongue__iexact=mother_tongue.strip())

        country = request.query_params.get('country')
        if country:
            queryset = queryset.filter(country__icontains=country.strip())

        state = request.query_params.get('state')
        if state:
            queryset = queryset.filter(state__icontains=state.strip())

        city = request.query_params.get('city')
        if city and category != 'near_me':
            queryset = queryset.filter(city__icontains=city.strip())

        education = request.query_params.get('education')
        if education:
            queryset = queryset.filter(education__icontains=education.strip())

        profession = request.query_params.get('profession')
        if profession:
            queryset = queryset.filter(occupation__icontains=profession.strip())

        queryset = queryset.order_by('-created_at')

        # Shortlists and interests lookup
        shortlisted_ids = set()
        if current_user:
            shortlisted_ids = set(Shortlist.objects.filter(user=current_user).values_list('profile_id', flat=True))

        serializer = ProfileSerializer(queryset, many=True)
        results = []
        for item in serializer.data:
            pid = item['id']
            # Compute 'Why am I seeing this match?' (Page 5)
            target_profile = queryset.filter(user__id=pid).first()
            item['match_reason'] = build_match_reason(target_profile, user_profile, user_pref) if target_profile else "Recommended match for you"
            item['is_shortlisted'] = pid in shortlisted_ids
            results.append(item)

        return Response(results)


class SearchView(APIView):
    """
    Page 5: Search Tab
    1. Basic Search: Age, height, marital status, religion, location
    2. Advanced Search: Education, profession, income, lifestyle habits, and separate 'Special Cases' filter
    3. Who is Online: Currently active members
    Sort by: relevance, newest, recently_active. Keyword search in 'About Me'.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        params = request.query_params.dict()
        return self._execute_search(request, params)

    def post(self, request):
        params = {**request.query_params.dict(), **(request.data if isinstance(request.data, dict) else {})}
        return self._execute_search(request, params)

    def _execute_search(self, request, params):
        current_user = request.user if request.user.is_authenticated else None
        queryset = Profile.objects.select_related('user').filter(
            verification_status='approved',
            is_hidden=False
        )

        if current_user:
            excluded = get_excluded_user_ids(current_user)
            queryset = queryset.exclude(user__id__in=excluded)

        # Basic Search
        min_age = params.get('min_age')
        max_age = params.get('max_age')
        today = date.today()
        if max_age:
            try:
                min_dob = date(today.year - int(max_age) - 1, today.month, today.day)
                queryset = queryset.filter(date_of_birth__gte=min_dob)
            except Exception:
                pass
        if min_age:
            try:
                max_dob = date(today.year - int(min_age), today.month, today.day)
                queryset = queryset.filter(date_of_birth__lte=max_dob)
            except Exception:
                pass

        min_height = params.get('min_height')
        if min_height:
            queryset = queryset.filter(height_cm__gte=int(min_height))
        max_height = params.get('max_height')
        if max_height:
            queryset = queryset.filter(height_cm__lte=int(max_height))

        marital_status = params.get('marital_status')
        if marital_status:
            queryset = queryset.filter(marital_status__iexact=str(marital_status).strip())

        religion = params.get('religion')
        if religion:
            queryset = queryset.filter(religion__iexact=str(religion).strip())

        city = params.get('city')
        if city:
            queryset = queryset.filter(city__icontains=str(city).strip())

        state = params.get('state')
        if state:
            queryset = queryset.filter(state__icontains=str(state).strip())

        # Advanced Search
        education = params.get('education')
        if education:
            queryset = queryset.filter(education__icontains=str(education).strip())

        profession = params.get('profession')
        if profession:
            queryset = queryset.filter(occupation__icontains=str(profession).strip())

        # Respectful Special Cases filter (Page 5)
        is_special_case = params.get('special_cases') or params.get('special_case')
        if is_special_case in ('true', '1', 'yes', True) or (is_special_case and is_special_case != 'none'):
            if is_special_case in ('true', '1', 'yes', True):
                queryset = queryset.filter(special_case__isnull=False).exclude(special_case='none').exclude(special_case='')
            else:
                queryset = queryset.filter(special_case__iexact=str(is_special_case).strip())

        # Who is Online filter (Page 5)
        who_is_online = params.get('online_only')
        if who_is_online in ('true', '1', 'yes', True):
            queryset = queryset.filter(chat_status='online')

        # Keyword search in About Me (Page 5)
        keyword = params.get('keyword')
        if keyword:
            queryset = queryset.filter(about_me__icontains=str(keyword).strip())

        # Sorting: relevance, newest, recently_active
        sort_by = str(params.get('sort_by', 'relevance')).lower()
        if sort_by == 'newest':
            queryset = queryset.order_by('-created_at')
        elif sort_by == 'recently_active':
            queryset = queryset.order_by('-updated_at')
        else:
            queryset = queryset.order_by('-created_at')

        # Record in SearchHistory for logged in user (Page 5: last 20)
        if current_user:
            query_str = f"Age: {min_age or 18}-{max_age or 60}, {religion or 'All'}, {city or 'Anywhere'}"
            SearchHistory.objects.create(
                user=current_user,
                query_summary=query_str,
                filters=params
            )
            # Retain only last 20
            history_ids = list(SearchHistory.objects.filter(user=current_user).values_list('id', flat=True)[:20])
            SearchHistory.objects.filter(user=current_user).exclude(id__in=history_ids).delete()

        serializer = ProfileSerializer(queryset, many=True)
        return Response(serializer.data)


class SavedSearchView(APIView):
    """
    Page 5: Save/Star up to 5 search sets. Delete saved search.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        saved = SavedSearch.objects.filter(user=request.user)[:5]
        return Response(SavedSearchSerializer(saved, many=True).data)

    def post(self, request):
        count = SavedSearch.objects.filter(user=request.user).count()
        if count >= 5:
            return Response({'error': 'You can save up to 5 searches. Please delete one to save a new search.'}, status=status.HTTP_400_BAD_REQUEST)

        title = request.data.get('title', f"Search #{count + 1}")
        filters = request.data.get('filters', {})
        saved = SavedSearch.objects.create(user=request.user, title=title, filters=filters)
        return Response(SavedSearchSerializer(saved).data, status=status.HTTP_201_CREATED)

    def delete(self, request, search_id):
        SavedSearch.objects.filter(user=request.user, id=search_id).delete()
        return Response({'message': 'Saved search deleted successfully.'}, status=status.HTTP_200_OK)


class SearchHistoryView(APIView):
    """
    Page 5: Search History (last 20)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        history = SearchHistory.objects.filter(user=request.user)[:20]
        return Response(SearchHistorySerializer(history, many=True).data)

    def delete(self, request):
        SearchHistory.objects.filter(user=request.user).delete()
        return Response({'message': 'Search history cleared.'}, status=status.HTTP_200_OK)


class ShortlistView(APIView):
    """
    Page 7: Shortlist Available. Saves profile for later.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        shortlists = Shortlist.objects.filter(user=request.user).select_related('profile')
        return Response(ShortlistSerializer(shortlists, many=True).data)

    def post(self, request):
        profile_id = request.data.get('profile_id')
        if not profile_id:
            return Response({'error': 'profile_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            profile = Profile.objects.get(Q(user__id=profile_id) | Q(profile_id=profile_id))
        except Profile.DoesNotExist:
            return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

        shortlist_item, created = Shortlist.objects.get_or_create(user=request.user, profile=profile)
        msg = 'Profile shortlisted successfully.' if created else 'Profile is already in your shortlist.'
        return Response({'message': msg, 'is_shortlisted': True}, status=status.HTTP_200_OK)

    def delete(self, request, profile_id):
        Shortlist.objects.filter(
            Q(user=request.user) & (Q(profile__user__id=profile_id) | Q(profile__profile_id=profile_id))
        ).delete()
        return Response({'message': 'Removed from shortlist.', 'is_shortlisted': False}, status=status.HTTP_200_OK)


class InboxView(APIView):
    """
    Page 5: Inbox Tab
    1. Interests Received (Accept, Decline, Delete, bulk actions)
    2. Filtered Out (Failed Must-haves)
    3. Requests Tab (Photo & Contact detail requests)
    4. Accepted Members List
    5. Deleted Folder
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        folder = request.query_params.get('folder', 'received').lower()
        user = request.user
        user_pref = getattr(getattr(user, 'profile', None), 'partner_preference', None)
        must_haves = user_pref.must_have_fields if user_pref else []

        if folder == 'accepted':
            # Accepted requests (both incoming and outgoing)
            reqs = MatchRequest.objects.filter(
                (Q(receiver=user) | Q(sender=user)) & Q(status='accepted')
            ).select_related('sender__profile', 'receiver__profile')
            return Response(MatchRequestSerializer(reqs, many=True).data)

        elif folder == 'deleted':
            # Declined, cancelled, or marked deleted
            reqs = MatchRequest.objects.filter(
                Q(receiver=user, is_deleted_by_receiver=True) |
                Q(sender=user, is_deleted_by_sender=True) |
                Q(receiver=user, status__in=['rejected', 'cancelled'])
            ).select_related('sender__profile', 'receiver__profile')
            return Response(MatchRequestSerializer(reqs, many=True).data)

        elif folder == 'filtered_out':
            # Interests that do not meet user's Must-have filters
            all_received = MatchRequest.objects.filter(
                receiver=user,
                status='pending',
                is_deleted_by_receiver=False
            ).select_related('sender__profile')

            filtered_out_reqs = []
            for r in all_received:
                sp = getattr(r.sender, 'profile', None)
                if not sp:
                    continue
                failed_must_have = False
                for field in must_haves:
                    if field == 'religion' and user_pref.religion and sp.religion not in user_pref.religion:
                        failed_must_have = True
                    elif field == 'marital_status' and user_pref.marital_status and sp.marital_status not in user_pref.marital_status:
                        failed_must_have = True
                    elif field == 'age' and sp.age and (sp.age < (user_pref.age_min or 0) or sp.age > (user_pref.age_max or 100)):
                        failed_must_have = True
                    elif field == 'city' and user_pref.city and (not sp.city or user_pref.city.lower() not in sp.city.lower()):
                        failed_must_have = True
                if failed_must_have:
                    filtered_out_reqs.append(r)

            return Response(MatchRequestSerializer(filtered_out_reqs, many=True).data)

        else:
            # Default: Interests Received (standard)
            all_received = MatchRequest.objects.filter(
                receiver=user,
                status='pending',
                is_deleted_by_receiver=False
            ).select_related('sender__profile')

            valid_received = []
            for r in all_received:
                sp = getattr(r.sender, 'profile', None)
                if not sp:
                    continue
                failed_must_have = False
                for field in must_haves:
                    if field == 'religion' and user_pref.religion and sp.religion not in user_pref.religion:
                        failed_must_have = True
                    elif field == 'marital_status' and user_pref.marital_status and sp.marital_status not in user_pref.marital_status:
                        failed_must_have = True
                    elif field == 'age' and sp.age and (sp.age < (user_pref.age_min or 0) or sp.age > (user_pref.age_max or 100)):
                        failed_must_have = True
                    elif field == 'city' and user_pref.city and (not sp.city or user_pref.city.lower() not in sp.city.lower()):
                        failed_must_have = True
                if not failed_must_have:
                    valid_received.append(r)

            return Response(MatchRequestSerializer(valid_received, many=True).data)

    def post(self, request):
        """
        Page 5: Bulk actions (Accept, Decline, Delete)
        """
        action = request.data.get('action')  # accept, decline, delete
        request_ids = request.data.get('request_ids', [])

        if not action or not request_ids:
            return Response({'error': 'action and request_ids are required'}, status=status.HTTP_400_BAD_REQUEST)

        reqs = MatchRequest.objects.filter(id__in=request_ids, receiver=request.user)

        if action == 'accept':
            reqs.update(status='accepted')
            msg = f"{reqs.count()} request(s) accepted."
        elif action in ('decline', 'reject'):
            reqs.update(status='rejected')
            msg = f"{reqs.count()} request(s) declined."
        elif action == 'delete':
            reqs.update(is_deleted_by_receiver=True)
            msg = f"{reqs.count()} request(s) moved to Deleted folder."
        else:
            return Response({'error': 'Unsupported action'}, status=status.HTTP_400_BAD_REQUEST)

        return Response({'message': msg, 'action': action}, status=status.HTTP_200_OK)


class PhotoOrContactRequestView(APIView):
    """
    Page 5 & 7: Photo Requests & Contact Detail Requests
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        req_type = request.query_params.get('type')  # photo or contact
        folder = request.query_params.get('folder', 'received')  # received or sent
        queryset = PhotoOrContactRequest.objects.select_related('sender__profile', 'receiver__profile')

        if folder == 'sent':
            queryset = queryset.filter(sender=request.user)
        else:
            queryset = queryset.filter(receiver=request.user)

        if req_type in ('photo', 'contact'):
            queryset = queryset.filter(request_type=req_type)

        return Response(PhotoOrContactRequestSerializer(queryset, many=True).data)

    def post(self, request):
        receiver_id = request.data.get('receiver_id')
        request_type = request.data.get('request_type')  # 'photo' or 'contact'

        if not receiver_id or request_type not in ('photo', 'contact'):
            return Response({'error': 'receiver_id and request_type (photo/contact) are required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            receiver = User.objects.get(Q(id=receiver_id) | Q(profile__profile_id=receiver_id))
        except User.DoesNotExist:
            return Response({'error': 'Recipient member not found'}, status=status.HTTP_404_NOT_FOUND)

        req_obj, created = PhotoOrContactRequest.objects.get_or_create(
            sender=request.user,
            receiver=receiver,
            request_type=request_type,
            defaults={'status': 'pending'}
        )

        return Response({
            'message': f"{request_type.capitalize()} request sent successfully.",
            'request': PhotoOrContactRequestSerializer(req_obj).data
        }, status=status.HTTP_201_CREATED)

    def patch(self, request, request_id):
        new_status = request.data.get('status')  # 'accepted' or 'declined'
        if new_status not in ('accepted', 'declined'):
            return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            req_obj = PhotoOrContactRequest.objects.get(id=request_id, receiver=request.user)
            req_obj.status = new_status
            req_obj.save()
            return Response({'message': f"Request {new_status}.", 'status': req_obj.status})
        except PhotoOrContactRequest.DoesNotExist:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)


class SendInterestView(APIView):
    """
    Page 6 & 7: Express Interest (Free to send) & Premium Interest
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        receiver_id = request.data.get('receiver_id')
        is_premium = bool(request.data.get('is_premium_interest', False))

        if not receiver_id:
            return Response({'error': 'receiver_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            receiver = User.objects.get(Q(id=receiver_id) | Q(profile__profile_id=receiver_id))
        except User.DoesNotExist:
            return Response({'error': 'Candidate not found'}, status=status.HTTP_404_NOT_FOUND)

        if receiver == request.user:
            return Response({'error': 'Cannot send interest to yourself'}, status=status.HTTP_400_BAD_REQUEST)

        req, created = MatchRequest.objects.update_or_create(
            sender=request.user,
            receiver=receiver,
            defaults={
                'status': 'pending',
                'is_premium_interest': is_premium,
                'is_deleted_by_receiver': False,
                'is_deleted_by_sender': False,
            }
        )

        return Response({
            'message': 'Interest sent successfully',
            'request_id': str(req.id),
            'status': req.status,
            'is_premium_interest': req.is_premium_interest,
        }, status=status.HTTP_200_OK)


class InterestStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        other_user_id = request.query_params.get('other_user_id')
        if not other_user_id:
            return Response({'status': None})

        try:
            req = MatchRequest.objects.filter(
                (Q(sender=request.user) & (Q(receiver__id=other_user_id) | Q(receiver__profile__profile_id=other_user_id))) |
                ((Q(sender__id=other_user_id) | Q(sender__profile__profile_id=other_user_id)) & Q(receiver=request.user))
            ).first()

            if not req:
                return Response({'status': None})

            if req.status == 'pending':
                res_status = 'sent' if req.sender == request.user else 'received'
            else:
                res_status = req.status

            return Response({'status': res_status, 'request_id': str(req.id)})
        except Exception as e:
            return Response({'status': None, 'error': str(e)})


class RespondMatchRequestView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, request_id):
        new_status = request.data.get('status')
        if new_status not in ('accepted', 'rejected', 'cancelled'):
            return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            req = MatchRequest.objects.get(id=request_id, receiver=request.user)
            req.status = new_status
            req.save()
            return Response({'message': f'Request {new_status} successfully', 'status': req.status})
        except MatchRequest.DoesNotExist:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)

