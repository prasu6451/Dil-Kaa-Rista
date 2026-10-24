from django.urls import path
from .views import (
    RegisterView,
    LoginView,
    LogoutView,
    CurrentUserView,
    GeneralSettingsView,
    ActiveSessionsView,
    ChangePasswordView,
    DataDownloadView,
    DeleteAccountView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth-register'),
    path('login/', LoginView.as_view(), name='auth-login'),
    path('logout/', LogoutView.as_view(), name='auth-logout'),
    path('me/', CurrentUserView.as_view(), name='auth-me'),
    path('settings/', GeneralSettingsView.as_view(), name='general-settings'),
    path('sessions/', ActiveSessionsView.as_view(), name='active-sessions'),
    path('active-sessions/', ActiveSessionsView.as_view(), name='active-sessions-alias'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('download-data/', DataDownloadView.as_view(), name='download-data'),
    path('delete-account/', DeleteAccountView.as_view(), name='delete-account'),
]

