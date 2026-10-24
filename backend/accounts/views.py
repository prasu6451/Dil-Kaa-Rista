from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from .serializers import RegisterSerializer, LoginSerializer, UserSerializer

class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, _ = Token.objects.get_or_create(user=user)
            
            # Fetch profile
            profile_data = None
            if hasattr(user, 'profile'):
                from profiles.serializers import ProfileSerializer
                profile_data = ProfileSerializer(user.profile).data

            return Response({
                'message': 'Account created successfully',
                'token': token.key,
                'user': UserSerializer(user).data,
                'profile': profile_data,
            }, status=status.HTTP_201_CREATED)
        errors = serializer.errors
        err_msg = 'Registration failed'
        for k, v in errors.items():
            val = v[0] if isinstance(v, list) else str(v)
            err_msg = f"{k.replace('_', ' ').capitalize()}: {val}"
            break
        return Response({'error': err_msg, 'details': errors}, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            token, _ = Token.objects.get_or_create(user=user)
            
            profile_data = None
            if hasattr(user, 'profile'):
                from profiles.serializers import ProfileSerializer
                profile_data = ProfileSerializer(user.profile).data

            return Response({
                'message': 'Login successful',
                'token': token.key,
                'user': UserSerializer(user).data,
                'profile': profile_data,
            }, status=status.HTTP_200_OK)
        return Response({'error': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            request.user.auth_token.delete()
        except Exception:
            pass
        return Response({'message': 'Logged out successfully'}, status=status.HTTP_200_OK)


class CurrentUserView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)


class GeneralSettingsView(APIView):
    """
    Page 4: General Settings Tab (How I use this app)
    Phone, Email, 2FA, Notification Preferences, Language, Dark Mode
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .models import UserSetting
        setting, _ = UserSetting.objects.get_or_create(user=request.user)
        return Response({
            'email': request.user.email,
            'phone_number': setting.phone_number,
            'two_factor_enabled': setting.two_factor_enabled,
            'two_factor_method': setting.two_factor_method,
            'notification_push': setting.notification_push,
            'notification_email': setting.notification_email,
            'notification_sms': setting.notification_sms,
            'notify_new_matches': setting.notify_new_matches,
            'notify_interests': setting.notify_interests,
            'notify_messages': setting.notify_messages,
            'notify_profile_views': setting.notify_profile_views,
            'language': setting.language,
            'dark_mode': setting.dark_mode,
        })

    def put(self, request):
        from .models import UserSetting
        setting, _ = UserSetting.objects.get_or_create(user=request.user)
        fields = [
            'phone_number', 'two_factor_enabled', 'two_factor_method',
            'notification_push', 'notification_email', 'notification_sms',
            'notify_new_matches', 'notify_interests', 'notify_messages',
            'notify_profile_views', 'language', 'dark_mode'
        ]
        for f in fields:
            if f in request.data:
                setattr(setting, f, request.data[f])
        setting.save()
        return self.get(request)

    def patch(self, request):
        return self.put(request)


class ActiveSessionsView(APIView):
    """
    Page 4: Login History and Active Sessions
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .models import UserSession
        sessions = UserSession.objects.filter(user=request.user)
        if not sessions.exists():
            UserSession.objects.create(
                user=request.user,
                device_info='Current Session (Web / Mobile App)',
                ip_address='127.0.0.1',
                is_current=True
            )
            sessions = UserSession.objects.filter(user=request.user)

        res = []
        for s in sessions:
            res.append({
                'id': s.id,
                'device_info': s.device_info,
                'ip_address': s.ip_address,
                'last_active': s.last_active.isoformat(),
                'is_current': s.is_current,
            })
        return Response(res)

    def post(self, request):
        session_id = request.data.get('session_id')
        from .models import UserSession
        UserSession.objects.filter(user=request.user, id=session_id).delete()
        return Response({'message': 'Session logged out remotely successfully.'}, status=status.HTTP_200_OK)


class ChangePasswordView(APIView):
    """
    Page 3 & 4: Change Password
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')

        if not old_password or not new_password:
            return Response({'error': 'Both old_password and new_password are required'}, status=status.HTTP_400_BAD_REQUEST)

        if not request.user.check_password(old_password):
            return Response({'error': 'Current password is incorrect'}, status=status.HTTP_400_BAD_REQUEST)

        request.user.set_password(new_password)
        request.user.save()
        return Response({'message': 'Password changed successfully.'}, status=status.HTTP_200_OK)


class DataDownloadView(APIView):
    """
    Page 4: Request a copy of personal data
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        profile_data = None
        if hasattr(user, 'profile'):
            from profiles.serializers import ProfileSerializer
            profile_data = ProfileSerializer(user.profile).data

        data_export = {
            'account': {
                'id': str(user.id),
                'email': user.email,
                'full_name': user.full_name,
                'gender': user.gender,
                'joined_at': user.created_at.isoformat(),
            },
            'profile': profile_data,
        }
        return Response({
            'message': 'Personal data package generated successfully.',
            'data': data_export,
        }, status=status.HTTP_200_OK)


class DeleteAccountView(APIView):
    """
    Page 4: Permanent account deletion. Clearly distinguished from Hide Profile.
    Requires confirmation step.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        confirmation = request.data.get('confirmation')
        password = request.data.get('password')

        if confirmation != 'DELETE':
            return Response({
                'error': 'Please enter DELETE as confirmation to permanently remove your account.'
            }, status=status.HTTP_400_BAD_REQUEST)

        if not password or not request.user.check_password(password):
            return Response({'error': 'Incorrect password. Account deletion aborted.'}, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        user.delete()
        return Response({'message': 'Your account and all associated data have been permanently deleted.'}, status=status.HTTP_200_OK)

