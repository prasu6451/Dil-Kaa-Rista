from rest_framework import serializers
from .models import MatchRequest, Shortlist, PhotoOrContactRequest, SavedSearch, SearchHistory
from profiles.serializers import ProfileSerializer

class MatchRequestSerializer(serializers.ModelSerializer):
    sender_id = serializers.CharField(source='sender.id', read_only=True)
    receiver_id = serializers.CharField(source='receiver.id', read_only=True)
    sender_profile = ProfileSerializer(source='sender.profile', read_only=True)
    receiver_profile = ProfileSerializer(source='receiver.profile', read_only=True)

    class Meta:
        model = MatchRequest
        fields = [
            'id',
            'sender_id',
            'receiver_id',
            'status',
            'message',
            'is_premium_interest',
            'is_deleted_by_sender',
            'is_deleted_by_receiver',
            'created_at',
            'updated_at',
            'sender_profile',
            'receiver_profile',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ShortlistSerializer(serializers.ModelSerializer):
    profile = ProfileSerializer(read_only=True)
    profile_id = serializers.CharField(source='profile.profile_id', read_only=True)

    class Meta:
        model = Shortlist
        fields = ['id', 'user', 'profile', 'profile_id', 'created_at']
        read_only_fields = ['id', 'created_at']


class PhotoOrContactRequestSerializer(serializers.ModelSerializer):
    sender_id = serializers.CharField(source='sender.id', read_only=True)
    receiver_id = serializers.CharField(source='receiver.id', read_only=True)
    sender_profile = ProfileSerializer(source='sender.profile', read_only=True)
    receiver_profile = ProfileSerializer(source='receiver.profile', read_only=True)

    class Meta:
        model = PhotoOrContactRequest
        fields = [
            'id',
            'sender_id',
            'receiver_id',
            'sender_profile',
            'receiver_profile',
            'request_type',
            'status',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SavedSearchSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedSearch
        fields = ['id', 'title', 'filters', 'created_at']
        read_only_fields = ['id', 'created_at']


class SearchHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SearchHistory
        fields = ['id', 'query_summary', 'filters', 'created_at']
        read_only_fields = ['id', 'created_at']

