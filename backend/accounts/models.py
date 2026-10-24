import uuid
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager

class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email).lower()
        user = self.model(email=email, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    GENDER_CHOICES = (
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, max_length=255, db_index=True)
    full_name = models.CharField(max_length=150)
    gender = models.CharField(max_length=20, choices=GENDER_CHOICES, default='male')
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']

    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.full_name} ({self.email})"


class UserSetting(models.Model):
    LANGUAGE_CHOICES = (
        ('English', 'English'),
        ('Assamese', 'Assamese'),
        ('Hindi', 'Hindi'),
        ('Tamil', 'Tamil'),
        ('Telugu', 'Telugu'),
        ('Marathi', 'Marathi'),
        ('Bengali', 'Bengali'),
        ('Gujarati', 'Gujarati'),
        ('Urdu', 'Urdu'),
    )

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='settings', primary_key=True)
    phone_number = models.CharField(max_length=25, null=True, blank=True)
    two_factor_enabled = models.BooleanField(default=False)
    two_factor_method = models.CharField(max_length=10, choices=(('sms', 'SMS'), ('email', 'Email')), default='email')

    # Notification Preferences (Page 4)
    notification_push = models.BooleanField(default=True)
    notification_email = models.BooleanField(default=True)
    notification_sms = models.BooleanField(default=False)
    notify_new_matches = models.BooleanField(default=True)
    notify_interests = models.BooleanField(default=True)
    notify_messages = models.BooleanField(default=True)
    notify_profile_views = models.BooleanField(default=True)

    # App Experience (Page 4)
    language = models.CharField(max_length=20, choices=LANGUAGE_CHOICES, default='English')
    dark_mode = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_settings'

    def __str__(self):
        return f"Settings for {self.user.email}"


class UserSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sessions')
    device_info = models.CharField(max_length=255, default='Web Browser (Chrome)')
    ip_address = models.CharField(max_length=50, null=True, blank=True, default='127.0.0.1')
    last_active = models.DateTimeField(auto_now=True)
    is_current = models.BooleanField(default=True)

    class Meta:
        db_table = 'user_sessions'
        ordering = ['-last_active']

    def __str__(self):
        return f"{self.user.email} - {self.device_info}"

