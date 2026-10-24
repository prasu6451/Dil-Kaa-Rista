from django.contrib import admin
from .models import MatchRequest

@admin.register(MatchRequest)
class MatchRequestAdmin(admin.ModelAdmin):
    list_display = ('sender', 'receiver', 'status', 'created_at', 'updated_at')
    list_filter = ('status', 'created_at')
    search_fields = ('sender__email', 'sender__full_name', 'receiver__email', 'receiver__full_name')
    readonly_fields = ('created_at', 'updated_at')
