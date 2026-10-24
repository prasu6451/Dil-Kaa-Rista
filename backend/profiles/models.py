import random
import string
from datetime import date
from django.db import models
from django.conf import settings
from django.contrib.postgres.fields import ArrayField


def generate_profile_id():
    chars = string.ascii_uppercase + string.digits
    return 'DKR' + ''.join(random.choices(chars, k=6))


class Profile(models.Model):
    VERIFICATION_CHOICES = (
        ('under_review', 'Under Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    DISPLAY_NAME_CHOICES = (
        ('full_name', 'Full Name'),
        ('first_name_initial', 'First Name + Last Initial'),
        ('custom_username', 'Custom Username'),
    )

    PHOTO_PRIVACY_CHOICES = (
        ('all_members', 'Visible to All Members'),
        ('contacted_accepted', 'Visible only to contacted and accepted members'),
    )

    HOROSCOPE_PRIVACY_CHOICES = (
        ('all_members', 'Visible to All Members'),
        ('accepted_interested', 'Visible only to accepted or interested members'),
        ('approved_only', 'Visible only to members I approve'),
    )

    MEMBERSHIP_TIER_CHOICES = (
        ('free', 'Free'),
        ('tier_1', 'Tier 1 Premium'),
        ('tier_2', 'Tier 2 Premium'),
    )

    CHAT_STATUS_CHOICES = (
        ('online', 'Online'),
        ('invisible', 'Invisible'),
        ('offline', 'Offline'),
    )

    PHONE_PRIVACY_CHOICES = (
        ('all_premium', 'Visible to all premium members'),
        ('accepted_premium', 'Visible only to accepted premium members'),
    )

    CALL_PERMISSIONS_CHOICES = (
        ('accepted_only', 'Accepted members only'),
        ('all_premium', 'All premium members'),
    )

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        primary_key=True,
        related_name='profile',
        db_column='id'
    )
    profile_id = models.CharField(max_length=15, unique=True, null=True, blank=True, db_index=True)
    full_name = models.CharField(max_length=150)
    gender = models.CharField(max_length=20, null=True, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    marital_status = models.CharField(max_length=50, default='Never Married', blank=True)
    height_cm = models.PositiveIntegerField(null=True, blank=True)
    religion = models.CharField(max_length=60, null=True, blank=True)
    mother_tongue = models.CharField(max_length=60, null=True, blank=True)
    caste = models.CharField(max_length=60, null=True, blank=True)
    gotra = models.CharField(max_length=60, null=True, blank=True)
    city = models.CharField(max_length=80, null=True, blank=True)
    state = models.CharField(max_length=80, null=True, blank=True)
    country = models.CharField(max_length=80, default='India', blank=True)
    education = models.CharField(max_length=150, null=True, blank=True)
    occupation = models.CharField(max_length=150, null=True, blank=True)
    annual_income = models.CharField(max_length=80, null=True, blank=True)
    about_me = models.TextField(null=True, blank=True)
    avatar_url = models.TextField(null=True, blank=True)
    photos = ArrayField(models.TextField(), default=list, blank=True)
    primary_photo_index = models.PositiveIntegerField(default=0)
    photo_privacy = models.CharField(max_length=30, choices=PHOTO_PRIVACY_CHOICES, default='all_members')

    # Verification & Screening (Page 1)
    verification_status = models.CharField(
        max_length=20,
        choices=VERIFICATION_CHOICES,
        default='under_review',
        db_index=True
    )
    is_verified = models.BooleanField(default=False)
    rejection_reason = models.TextField(null=True, blank=True)
    estimated_screening_hours = models.PositiveIntegerField(default=24)

    # Display Name Format (Page 2 & 3)
    display_name_format = models.CharField(
        max_length=30,
        choices=DISPLAY_NAME_CHOICES,
        default='full_name'
    )
    custom_username = models.CharField(max_length=50, null=True, blank=True)

    # Hobbies & Interests (Page 2)
    hobbies = ArrayField(models.CharField(max_length=100), default=list, blank=True)
    hobbies_other = models.CharField(max_length=200, null=True, blank=True)
    hobbies_other_status = models.CharField(
        max_length=20,
        choices=(('pending', 'Pending Review'), ('approved', 'Approved'), ('rejected', 'Rejected')),
        default='approved'
    )

    # Horoscope / Kundli (Page 2 & 7)
    horoscope_url = models.TextField(null=True, blank=True)
    horoscope_privacy = models.CharField(
        max_length=30,
        choices=HOROSCOPE_PRIVACY_CHOICES,
        default='all_members'
    )

    # Privacy & Safety Settings (Page 3)
    is_hidden = models.BooleanField(default=False)
    is_photo_locked = models.BooleanField(default=False)
    chat_status = models.CharField(max_length=20, choices=CHAT_STATUS_CHOICES, default='online')
    phone_number = models.CharField(max_length=25, null=True, blank=True)
    phone_privacy = models.CharField(max_length=30, choices=PHONE_PRIVACY_CHOICES, default='accepted_premium')
    call_permissions = models.CharField(max_length=30, choices=CALL_PERMISSIONS_CHOICES, default='accepted_only')
    call_hours_start = models.TimeField(null=True, blank=True)
    call_hours_end = models.TimeField(null=True, blank=True)

    # Premium & Special Cases (Page 5 & 6)
    membership_tier = models.CharField(max_length=20, choices=MEMBERSHIP_TIER_CHOICES, default='free')
    special_case = models.CharField(max_length=100, null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'profiles'
        verbose_name = 'Matrimonial Profile'
        verbose_name_plural = 'Matrimonial Profiles'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.display_name} ({self.profile_id or self.user.id})"

    def save(self, *args, **kwargs):
        if not self.profile_id:
            new_id = generate_profile_id()
            while Profile.objects.filter(profile_id=new_id).exists():
                new_id = generate_profile_id()
            self.profile_id = new_id
        if self.verification_status == 'approved':
            self.is_verified = True
        else:
            self.is_verified = False
        super().save(*args, **kwargs)

    @property
    def id(self):
        return str(self.user.id)

    @property
    def display_name(self):
        if self.display_name_format == 'first_name_initial':
            parts = (self.full_name or '').strip().split()
            if len(parts) > 1:
                return f"{parts[0]} {parts[-1][0]}."
            elif parts:
                return parts[0]
            return "Member"
        elif self.display_name_format == 'custom_username' and self.custom_username:
            return self.custom_username
        return self.full_name or "Member"

    @property
    def age(self):
        if not self.date_of_birth:
            return None
        today = date.today()
        return today.year - self.date_of_birth.year - (
            (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day)
        )


class PartnerPreference(models.Model):
    profile = models.OneToOneField(
        Profile,
        on_delete=models.CASCADE,
        related_name='partner_preference',
        primary_key=True
    )
    age_min = models.PositiveIntegerField(null=True, blank=True, default=21)
    age_max = models.PositiveIntegerField(null=True, blank=True, default=35)
    height_min_cm = models.PositiveIntegerField(null=True, blank=True, default=150)
    height_max_cm = models.PositiveIntegerField(null=True, blank=True, default=190)
    marital_status = ArrayField(models.CharField(max_length=50), default=list, blank=True)
    religion = ArrayField(models.CharField(max_length=60), default=list, blank=True)
    caste = ArrayField(models.CharField(max_length=60), default=list, blank=True)
    mother_tongue = ArrayField(models.CharField(max_length=60), default=list, blank=True)
    country = models.CharField(max_length=80, null=True, blank=True, default='India')
    city = models.CharField(max_length=80, null=True, blank=True)
    education = ArrayField(models.CharField(max_length=150), default=list, blank=True)
    profession = ArrayField(models.CharField(max_length=150), default=list, blank=True)
    income_min = models.BigIntegerField(null=True, blank=True)
    income_max = models.BigIntegerField(null=True, blank=True)
    lifestyle_diet = ArrayField(models.CharField(max_length=50), default=list, blank=True)
    lifestyle_smoking = models.CharField(max_length=50, null=True, blank=True)
    lifestyle_drinking = models.CharField(max_length=50, null=True, blank=True)
    
    # Must-have criteria tracking (Page 3)
    must_have_fields = ArrayField(models.CharField(max_length=50), default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'partner_preferences'
        verbose_name = 'Partner Preference'
        verbose_name_plural = 'Partner Preferences'

    def __str__(self):
        return f"Preferences for {self.profile.full_name}"

    @property
    def has_narrow_criteria_warning(self):
        return len(self.must_have_fields) >= 5


class ProfileChangeRequest(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='change_requests')
    field_name = models.CharField(max_length=50)
    old_value = models.TextField(null=True, blank=True)
    new_value = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    rejection_reason = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'profile_change_requests'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.profile.display_name} - {self.field_name} change ({self.status})"


class BlockedMember(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='blocked_users')
    blocked_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='blocked_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'blocked_members'
        unique_together = ('user', 'blocked_user')

    def __str__(self):
        return f"{self.user} blocked {self.blocked_user}"


class ReportedMember(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending Review'),
        ('upheld', 'Upheld'),
        ('dismissed', 'Dismissed'),
    )

    reporter = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='filed_reports')
    reported_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='received_reports')
    reason = models.CharField(max_length=100)
    details = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reported_members'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.reporter} reported {self.reported_user} ({self.reason})"

