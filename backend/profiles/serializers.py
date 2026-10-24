from rest_framework import serializers
from .models import (
    Profile,
    PartnerPreference,
    ProfileChangeRequest,
    BlockedMember,
    ReportedMember,
)

class PartnerPreferenceSerializer(serializers.ModelSerializer):
    has_narrow_criteria_warning = serializers.BooleanField(read_only=True)

    class Meta:
        model = PartnerPreference
        fields = [
            'age_min',
            'age_max',
            'height_min_cm',
            'height_max_cm',
            'marital_status',
            'religion',
            'caste',
            'mother_tongue',
            'country',
            'city',
            'education',
            'profession',
            'income_min',
            'income_max',
            'lifestyle_diet',
            'lifestyle_smoking',
            'lifestyle_drinking',
            'must_have_fields',
            'has_narrow_criteria_warning',
            'updated_at',
        ]
        read_only_fields = ['has_narrow_criteria_warning', 'updated_at']


class ProfileChangeRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProfileChangeRequest
        fields = [
            'id',
            'field_name',
            'old_value',
            'new_value',
            'status',
            'rejection_reason',
            'created_at',
            'reviewed_at',
        ]
        read_only_fields = ['id', 'old_value', 'status', 'rejection_reason', 'created_at', 'reviewed_at']


class ProfileSerializer(serializers.ModelSerializer):
    id = serializers.CharField(read_only=True)
    profile_id = serializers.CharField(read_only=True)
    display_name = serializers.CharField(read_only=True)
    age = serializers.IntegerField(read_only=True)
    partner_preference = PartnerPreferenceSerializer(read_only=True)
    screening_message = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = [
            'id',
            'profile_id',
            'full_name',
            'display_name',
            'display_name_format',
            'custom_username',
            'gender',
            'date_of_birth',
            'age',
            'marital_status',
            'height_cm',
            'religion',
            'mother_tongue',
            'caste',
            'gotra',
            'city',
            'state',
            'country',
            'education',
            'occupation',
            'annual_income',
            'about_me',
            'avatar_url',
            'photos',
            'primary_photo_index',
            'photo_privacy',
            'verification_status',
            'is_verified',
            'rejection_reason',
            'estimated_screening_hours',
            'screening_message',
            'hobbies',
            'hobbies_other',
            'hobbies_other_status',
            'horoscope_url',
            'horoscope_privacy',
            'is_hidden',
            'is_photo_locked',
            'membership_tier',
            'chat_status',
            'phone_number',
            'phone_privacy',
            'call_permissions',
            'call_hours_start',
            'call_hours_end',
            'special_case',
            'partner_preference',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'profile_id',
            'display_name',
            'age',
            'verification_status',
            'is_verified',
            'rejection_reason',
            'estimated_screening_hours',
            'screening_message',
            'created_at',
            'updated_at',
        ]

    def get_screening_message(self, obj):
        if obj.verification_status == 'under_review':
            return f"Under review, usually within {obj.estimated_screening_hours} hours."
        elif obj.verification_status == 'rejected':
            return f"Profile review rejected: {obj.rejection_reason or 'Details do not meet guidelines.'} You can update and resubmit."
        return "Profile is verified and active."


class LimitedScreeningProfileSerializer(serializers.ModelSerializer):
    """
    Page 1: Only the profile owner can see their own profile in a limited view
    showing essential information (age, height, marital status, city, education).
    """
    id = serializers.CharField(read_only=True)
    profile_id = serializers.CharField(read_only=True)
    display_name = serializers.CharField(read_only=True)
    age = serializers.IntegerField(read_only=True)
    screening_message = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = [
            'id',
            'profile_id',
            'display_name',
            'age',
            'height_cm',
            'marital_status',
            'city',
            'education',
            'verification_status',
            'rejection_reason',
            'estimated_screening_hours',
            'screening_message',
        ]

    def get_screening_message(self, obj):
        if obj.verification_status == 'under_review':
            return f"Under review, usually within {obj.estimated_screening_hours} hours."
        elif obj.verification_status == 'rejected':
            return f"Profile review rejected: {obj.rejection_reason or 'Details do not meet guidelines.'}"
        return "Profile is active."


class BlockedMemberSerializer(serializers.ModelSerializer):
    blocked_user_email = serializers.ReadOnlyField(source='blocked_user.email')
    blocked_user_name = serializers.ReadOnlyField(source='blocked_user.full_name')

    class Meta:
        model = BlockedMember
        fields = ['id', 'blocked_user', 'blocked_user_email', 'blocked_user_name', 'created_at']
        read_only_fields = ['id', 'created_at']


class ReportedMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReportedMember
        fields = ['id', 'reported_user', 'reason', 'details', 'status', 'created_at']
        read_only_fields = ['id', 'status', 'created_at']

