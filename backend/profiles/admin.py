from django.contrib import admin
from django.utils import timezone
from .models import (
    Profile,
    PartnerPreference,
    ProfileChangeRequest,
    BlockedMember,
    ReportedMember,
)

@admin.action(description='Approve selected profiles for public visibility')
def approve_profiles(modeladmin, request, queryset):
    updated = queryset.update(verification_status='approved', is_verified=True, rejection_reason=None)
    modeladmin.message_user(request, f"{updated} profile(s) successfully approved.")

@admin.action(description='Mark selected profiles as Under Review')
def mark_under_review(modeladmin, request, queryset):
    updated = queryset.update(verification_status='under_review', is_verified=False)
    modeladmin.message_user(request, f"{updated} profile(s) moved to Under Review.")

@admin.action(description='Reject selected profiles (Incomplete/Guidelines violation)')
def reject_profiles(modeladmin, request, queryset):
    updated = queryset.update(
        verification_status='rejected',
        is_verified=False,
        rejection_reason='Profile details or photos do not comply with our community guidelines. Please review and resubmit.'
    )
    modeladmin.message_user(request, f"{updated} profile(s) rejected.")


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = (
        'profile_id',
        'display_name',
        'gender',
        'age',
        'verification_status',
        'membership_tier',
        'city',
        'state',
        'is_verified',
        'created_at',
    )
    list_filter = (
        'verification_status',
        'membership_tier',
        'gender',
        'religion',
        'marital_status',
        'is_hidden',
        'is_verified',
    )
    search_fields = (
        'profile_id',
        'full_name',
        'custom_username',
        'user__email',
        'city',
        'state',
        'occupation',
    )
    readonly_fields = ('profile_id', 'created_at', 'updated_at')
    actions = [approve_profiles, mark_under_review, reject_profiles]
    fieldsets = (
        ('Account & Identity', {
            'fields': (
                'user',
                'profile_id',
                'full_name',
                'display_name_format',
                'custom_username',
                'gender',
                'date_of_birth',
                'marital_status',
                'height_cm',
            )
        }),
        ('Screening & Verification (CR Team)', {
            'fields': (
                'verification_status',
                'is_verified',
                'estimated_screening_hours',
                'rejection_reason',
            )
        }),
        ('Cultural & Background', {
            'fields': (
                'religion',
                'mother_tongue',
                'caste',
                'gotra',
                'city',
                'state',
                'country',
            )
        }),
        ('Career & Education', {
            'fields': (
                'education',
                'occupation',
                'annual_income',
                'about_me',
            )
        }),
        ('Media & Photos', {
            'fields': (
                'avatar_url',
                'photos',
                'primary_photo_index',
                'photo_privacy',
                'is_photo_locked',
            )
        }),
        ('Hobbies & Horoscope', {
            'fields': (
                'hobbies',
                'hobbies_other',
                'hobbies_other_status',
                'horoscope_url',
                'horoscope_privacy',
            )
        }),
        ('Privacy, Safety & Premium', {
            'fields': (
                'is_hidden',
                'membership_tier',
                'chat_status',
                'phone_number',
                'phone_privacy',
                'call_permissions',
                'call_hours_start',
                'call_hours_end',
                'special_case',
            )
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(PartnerPreference)
class PartnerPreferenceAdmin(admin.ModelAdmin):
    list_display = ('profile', 'age_min', 'age_max', 'height_min_cm', 'height_max_cm', 'country', 'city', 'must_have_fields')
    search_fields = ('profile__full_name', 'profile__profile_id', 'city')


@admin.action(description='Approve profile change request')
def approve_change_request(modeladmin, request, queryset):
    for req in queryset.filter(status='pending'):
        profile = req.profile
        # Apply change to profile
        setattr(profile, req.field_name, req.new_value)
        profile.save()
        req.status = 'approved'
        req.reviewed_at = timezone.now()
        req.save()
    modeladmin.message_user(request, "Selected change request(s) approved and applied.")


@admin.action(description='Reject profile change request')
def reject_change_request(modeladmin, request, queryset):
    for req in queryset.filter(status='pending'):
        req.status = 'rejected'
        req.rejection_reason = 'Submitted information could not be verified.'
        req.reviewed_at = timezone.now()
        req.save()
    modeladmin.message_user(request, "Selected change request(s) rejected.")


@admin.register(ProfileChangeRequest)
class ProfileChangeRequestAdmin(admin.ModelAdmin):
    list_display = ('profile', 'field_name', 'old_value', 'new_value', 'status', 'created_at', 'reviewed_at')
    list_filter = ('status', 'field_name', 'created_at')
    search_fields = ('profile__full_name', 'profile__profile_id', 'field_name')
    actions = [approve_change_request, reject_change_request]


@admin.register(ReportedMember)
class ReportedMemberAdmin(admin.ModelAdmin):
    list_display = ('reporter', 'reported_user', 'reason', 'status', 'created_at')
    list_filter = ('status', 'reason', 'created_at')
    search_fields = ('reporter__email', 'reported_user__email', 'reason', 'details')


@admin.register(BlockedMember)
class BlockedMemberAdmin(admin.ModelAdmin):
    list_display = ('user', 'blocked_user', 'created_at')
    search_fields = ('user__email', 'blocked_user__email')

