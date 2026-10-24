from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'gender', 'created_at']
        read_only_fields = ['id', 'created_at']


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(max_length=150)
    gender = serializers.CharField(required=False, default='male')

    def validate_gender(self, value):
        val = str(value).strip().lower()
        if val in ('male', 'm', 'groom'):
            return 'male'
        elif val in ('female', 'f', 'bride'):
            return 'female'
        elif val in ('other', 'o'):
            return 'other'
        return 'male'

    def validate_email(self, value):
        val = value.strip().lower()
        if User.objects.filter(email=val).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return val

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            full_name=validated_data['full_name'],
            gender=validated_data.get('gender', 'male'),
        )
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs.get('email', '').strip().lower()
        password = attrs.get('password')

        if email and password:
            user = authenticate(username=email, password=password)
            if not user:
                raise serializers.ValidationError("Invalid email or password.")
            if not user.is_active:
                raise serializers.ValidationError("This account is currently disabled.")
        else:
            raise serializers.ValidationError("Must include both email and password.")

        attrs['user'] = user
        return attrs
