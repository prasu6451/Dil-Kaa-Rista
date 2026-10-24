from datetime import timedelta
from django.utils import timezone
from django.db.models import Q, Max, Count
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import Message
from .serializers import MessageSerializer
from accounts.models import User
from profiles.models import Profile
from profiles.serializers import ProfileSerializer
from matches.models import MatchRequest, Shortlist


class MessageListView(APIView):
    """
    Page 1: Messages are stored for 12 months. Users can delete individual conversations.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        other_user_id = request.query_params.get('other_user_id')
        if not other_user_id:
            return Response({'error': 'other_user_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        # 12-month message retention
        one_year_ago = timezone.now() - timedelta(days=365)

        # Mark unread messages sent to current_user as read
        Message.objects.filter(
            sender__id=other_user_id,
            receiver=request.user,
            is_read=False
        ).update(is_read=True)

        messages = Message.objects.filter(
            ((Q(sender=request.user, is_deleted_by_sender=False) & Q(receiver__id=other_user_id)) |
             (Q(sender__id=other_user_id) & Q(receiver=request.user, is_deleted_by_receiver=False))),
            created_at__gte=one_year_ago
        ).order_by('created_at')

        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)


class SendMessageView(APIView):
    """
    Page 1 & 6: Premium members can initiate chats.
    Free members cannot initiate chats; they see a disabled button with an upgrade prompt.
    Free members CAN reply if the other person already initiated.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        receiver_id = request.data.get('receiver_id')
        content = request.data.get('content', '').strip()

        if not receiver_id:
            return Response({'error': 'receiver_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        if not content:
            return Response({'error': 'content cannot be empty'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            receiver = User.objects.get(Q(id=receiver_id) | Q(profile__profile_id=receiver_id))
        except User.DoesNotExist:
            return Response({'error': 'Receiver user not found'}, status=status.HTTP_404_NOT_FOUND)

        if receiver == request.user:
            return Response({'error': 'Cannot message yourself'}, status=status.HTTP_400_BAD_REQUEST)

        # Check existing conversation
        user_profile = getattr(request.user, 'profile', None)
        user_tier = getattr(user_profile, 'membership_tier', 'free')

        has_existing_conversation = Message.objects.filter(
            (Q(sender=request.user, receiver=receiver) | Q(sender=receiver, receiver=request.user))
        ).exists()

        # If starting a new conversation and user is free tier
        if not has_existing_conversation and user_tier == 'free':
            return Response({
                'error': 'Initiating new conversations requires a Premium membership.',
                'upgrade_prompt': True,
                'tier': 'free'
            }, status=status.HTTP_403_FORBIDDEN)

        message = Message.objects.create(
            sender=request.user,
            receiver=receiver,
            content=content
        )

        return Response(MessageSerializer(message).data, status=status.HTTP_201_CREATED)


class DeleteConversationView(APIView):
    """
    Page 1: Users can delete individual conversations.
    """
    permission_classes = [IsAuthenticated]

    def delete(self, request, other_user_id):
        # Soft delete for sender
        Message.objects.filter(
            sender=request.user,
            receiver__id=other_user_id
        ).update(is_deleted_by_sender=True)

        # Soft delete for receiver
        Message.objects.filter(
            sender__id=other_user_id,
            receiver=request.user
        ).update(is_deleted_by_receiver=True)

        return Response({'message': 'Conversation deleted successfully.'}, status=status.HTTP_200_OK)


class ChatBoxDirectoryView(APIView):
    """
    Page 1 & 5:
    Shows Accepted Members, Shortlists, and Matches who are online.
    Displays unread message count per conversation.
    Also returns badge counts for unread messages and pending interests.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        one_year_ago = timezone.now() - timedelta(days=365)

        # 1. Total Unread Messages Count & Pending Interests Count for badge
        unread_msg_count = Message.objects.filter(
            receiver=user,
            is_read=False,
            is_deleted_by_receiver=False,
            created_at__gte=one_year_ago
        ).count()

        pending_interests_count = MatchRequest.objects.filter(
            receiver=user,
            status='pending',
            is_deleted_by_receiver=False
        ).count()

        # 2. Existing active conversations
        received_messages = Message.objects.filter(
            receiver=user,
            is_deleted_by_receiver=False,
            created_at__gte=one_year_ago
        ).values('sender').distinct()

        sent_messages = Message.objects.filter(
            sender=user,
            is_deleted_by_sender=False,
            created_at__gte=one_year_ago
        ).values('receiver').distinct()

        partner_ids = set([m['sender'] for m in received_messages] + [m['receiver'] for m in sent_messages])
        conversations = []
        for pid in partner_ids:
            try:
                p_user = User.objects.get(id=pid)
                last_msg = Message.objects.filter(
                    ((Q(sender=user, receiver=p_user, is_deleted_by_sender=False)) |
                     (Q(sender=p_user, receiver=user, is_deleted_by_receiver=False))),
                    created_at__gte=one_year_ago
                ).order_by('-created_at').first()

                unread_for_conv = Message.objects.filter(
                    sender=p_user,
                    receiver=user,
                    is_read=False,
                    is_deleted_by_receiver=False
                ).count()

                if last_msg:
                    profile_obj = getattr(p_user, 'profile', None)
                    conversations.append({
                        'user_id': str(p_user.id),
                        'profile_id': getattr(profile_obj, 'profile_id', str(p_user.id)),
                        'name': profile_obj.display_name if profile_obj else p_user.full_name,
                        'avatar_url': getattr(profile_obj, 'avatar_url', None),
                        'chat_status': getattr(profile_obj, 'chat_status', 'offline'),
                        'last_message': last_msg.content,
                        'last_message_time': last_msg.created_at.isoformat(),
                        'unread_count': unread_for_conv,
                    })
            except User.DoesNotExist:
                pass

        conversations.sort(key=lambda x: x['last_message_time'], reverse=True)

        # 3. Accepted Members
        accepted_reqs = MatchRequest.objects.filter(
            (Q(receiver=user) | Q(sender=user)) & Q(status='accepted')
        ).select_related('sender__profile', 'receiver__profile')

        accepted_members = []
        for r in accepted_reqs:
            other = r.receiver if r.sender == user else r.sender
            p = getattr(other, 'profile', None)
            if p:
                accepted_members.append({
                    'user_id': str(other.id),
                    'profile_id': p.profile_id,
                    'name': p.display_name,
                    'avatar_url': p.avatar_url,
                    'chat_status': p.chat_status,
                    'is_online': (p.chat_status == 'online'),
                })

        # 4. Shortlisted Profiles
        shortlists = Shortlist.objects.filter(user=user).select_related('profile')
        shortlist_members = []
        for s in shortlists:
            p = s.profile
            shortlist_members.append({
                'user_id': str(p.user.id),
                'profile_id': p.profile_id,
                'name': p.display_name,
                'avatar_url': p.avatar_url,
                'chat_status': p.chat_status,
                'is_online': (p.chat_status == 'online'),
            })

        # 5. Online Matches
        online_profiles = Profile.objects.filter(
            verification_status='approved',
            is_hidden=False,
            chat_status='online'
        ).exclude(user=user)[:15]

        online_matches = []
        for p in online_profiles:
            online_matches.append({
                'user_id': str(p.user.id),
                'profile_id': p.profile_id,
                'name': p.display_name,
                'avatar_url': p.avatar_url,
                'chat_status': p.chat_status,
                'is_online': True,
            })

        return Response({
            'badge': {
                'unread_message_count': unread_msg_count,
                'pending_interest_count': pending_interests_count,
            },
            'conversations': conversations,
            'accepted_members': accepted_members,
            'shortlist_members': shortlist_members,
            'online_matches': online_matches,
        })

