from django.db.models.signals import post_save
from django.dispatch import receiver
from django.conf import settings
from .models import Profile, PartnerPreference

@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    if created:
        profile = Profile.objects.create(
            user=instance,
            full_name=instance.full_name or 'Member',
            gender=instance.gender or 'male',
            verification_status='approved',
            is_verified=True,
        )
        PartnerPreference.objects.get_or_create(profile=profile)
    else:
        if hasattr(instance, 'profile'):
            instance.profile.full_name = instance.full_name
            instance.profile.gender = instance.gender
            instance.profile.save()

