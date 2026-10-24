from django.urls import path
from .views import (
    MyProfileView,
    ResubmitProfileView,
    ProfileDetailView,
    ProfilePhotoUploadView,
    ReorderPhotosView,
    PartnerPreferenceView,
    PrivacySettingsView,
    BlockMemberView,
    ReportMisuseView,
)

urlpatterns = [
    path('me/', MyProfileView.as_view(), name='my-profile'),
    path('resubmit/', ResubmitProfileView.as_view(), name='resubmit-profile'),
    path('partner-preferences/', PartnerPreferenceView.as_view(), name='partner-preferences'),
    path('privacy-settings/', PrivacySettingsView.as_view(), name='privacy-settings'),
    path('upload-photo/', ProfilePhotoUploadView.as_view(), name='upload-profile-photo'),
    path('reorder-photos/', ReorderPhotosView.as_view(), name='reorder-photos'),
    path('block/', BlockMemberView.as_view(), name='block-member'),
    path('report/', ReportMisuseView.as_view(), name='report-misuse'),
    path('<uuid:user_id>/', ProfileDetailView.as_view(), name='profile-detail'),
]

