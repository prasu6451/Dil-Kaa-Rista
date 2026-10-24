from django.contrib import admin
from .models import Message

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('sender', 'receiver', 'content_snippet', 'is_read', 'created_at')
    list_filter = ('is_read', 'created_at')
    search_fields = ('sender__email', 'receiver__email', 'content')
    readonly_fields = ('created_at',)

    def content_snippet(self, obj):
        return obj.content[:40] + ('...' if len(obj.content) > 40 else '')
    content_snippet.short_description = 'Content'
