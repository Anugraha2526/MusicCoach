from rest_framework import serializers
from .models import CustomUser

# Registration Serializer
class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'password', 'role']

    def create(self, validated_data):
        # Create user with hashed password
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data.get('role', 'user')
        )
        return user

# Login Serializer
class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, required=True)

# Change Password Serializer
class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)


# Profile Update Serializer
class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'role', 'natural_pitch']
        extra_kwargs = {'email': {'required': True}}

# Password Reset Request Serializer
class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)

# Password Reset Confirm Serializer (OTP-based)
class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    otp = serializers.CharField(max_length=6, required=True)  # OTP sent to email
    new_password = serializers.CharField(required=True, min_length=8)

# -------------------- Admin Dashboard Serializers --------------------

class AdminUserSerializer(serializers.ModelSerializer):
    piano_lessons_completed = serializers.SerializerMethodField()
    vocal_lessons_completed = serializers.SerializerMethodField()

    class Meta:
        model = CustomUser
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 
            'role', 'is_active', 'natural_pitch', 'date_joined',
            'piano_lessons_completed', 'vocal_lessons_completed'
        ]

    def get_piano_lessons_completed(self, obj):
        progress = obj.progress.first()
        if progress:
            return progress.completed_lessons.filter(module__instrument__name__icontains='piano').count()
        return 0

    def get_vocal_lessons_completed(self, obj):
        progress = obj.progress.first()
        if progress:
            return progress.completed_lessons.filter(module__instrument__name__icontains='vocal').count()
        return 0


class AdminUserWriteSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, min_length=8)

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'first_name', 'last_name', 'role', 'is_active', 'password']

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = CustomUser(**validated_data)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance
