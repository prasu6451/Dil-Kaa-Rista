from django.urls import path
from .views import (
    MessageListView,
    SendMessageView,
    DeleteConversationView,
    ChatBoxDirectoryView,
)

urlpatterns = [
    path('directory/', ChatBoxDirectoryView.as_view(), name='chat-directory'),
    path('messages/', MessageListView.as_view(), name='chat-messages'),
    path('send/', SendMessageView.as_view(), name='chat-send'),
    path('conversation/<str:other_user_id>/delete/', DeleteConversationView.as_view(), name='delete-conversation'),
]

