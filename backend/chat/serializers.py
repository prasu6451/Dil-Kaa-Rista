from rest_framework import serializers
from .models import Message

class MessageSerializer(serializers.ModelSerializer):
    id = serializers.CharField(read_only=True)
    sender_id = serializers.CharField(source='sender.id', read_only=True)
    receiver_id = serializers.CharField(source='receiver.id', read_only=True)

    class Meta:
        model = Message
        fields = [
            'id',
            'sender_id',
            'receiver_id',
            'content',
            'is_read',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']
