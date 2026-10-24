from django.urls import path
from .views import (
    MatchesFeedView,
    SearchView,
    SavedSearchView,
    SearchHistoryView,
    ShortlistView,
    InboxView,
    PhotoOrContactRequestView,
    SendInterestView,
    InterestStatusView,
    RespondMatchRequestView,
)

urlpatterns = [
    path('', MatchesFeedView.as_view(), name='matches-feed'),
    path('feed/', MatchesFeedView.as_view(), name='matches-feed-alias'),
    path('search/', SearchView.as_view(), name='matches-search'),
    path('saved-searches/', SavedSearchView.as_view(), name='saved-searches'),
    path('saved-searches/<int:search_id>/', SavedSearchView.as_view(), name='saved-searches-detail'),
    path('search-history/', SearchHistoryView.as_view(), name='search-history'),
    path('shortlists/', ShortlistView.as_view(), name='shortlists'),
    path('shortlists/<str:profile_id>/', ShortlistView.as_view(), name='shortlists-detail'),
    path('inbox/', InboxView.as_view(), name='inbox'),
    path('photo-contact-requests/', PhotoOrContactRequestView.as_view(), name='photo-contact-requests'),
    path('photo-contact-requests/<uuid:request_id>/', PhotoOrContactRequestView.as_view(), name='photo-contact-request-detail'),
    path('send-interest/', SendInterestView.as_view(), name='send-interest'),
    path('interest-status/', InterestStatusView.as_view(), name='interest-status'),
    path('requests/<uuid:request_id>/respond/', RespondMatchRequestView.as_view(), name='respond-request'),
]

