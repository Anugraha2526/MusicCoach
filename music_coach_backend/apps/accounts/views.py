from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from .serializers import (
    RegisterSerializer,
    ProfileSerializer,
    ChangePasswordSerializer,
    PasswordResetRequestSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
    AdminUserSerializer,
    AdminUserWriteSerializer,
)
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import IsAuthenticated
from .permissions import IsAdminRole

import random
from django.core.cache import cache
from django.core.mail import send_mail
from django.conf import settings

User = get_user_model()

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token = get_tokens_for_user(user)
            return Response({"user": serializer.data, "token": token}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        user = authenticate(email=email, password=password)
        if user:
            token = get_tokens_for_user(user)
            return Response({"message": "Login successful", "token": token})
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

class AdminLoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        user = authenticate(email=email, password=password)
        if not user:
            return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)
        if user.role != 'admin' and not user.is_staff:
            return Response({"error": "Access denied. Admin only."}, status=status.HTTP_403_FORBIDDEN)
        token = get_tokens_for_user(user)
        return Response({
            "message": "Admin login successful",
            "token": token,
            "user": {
                "id": user.id,
                "email": user.email,
                "username": user.username,
                "is_staff": user.is_staff,
                "role": user.role,
            }
        })

from datetime import date

class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        user = self.request.user
        return user

class UpdateStreakView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        today = date.today()

        if user.last_active_date is None:
            user.last_active_date = today
            user.current_streak = 1
            user.save(update_fields=['last_active_date', 'current_streak'])
        else:
            diff = (today - user.last_active_date).days
            if diff == 1:
                user.current_streak += 1
                user.last_active_date = today
                user.save(update_fields=['last_active_date', 'current_streak'])
            elif diff > 1:
                user.current_streak = 1
                user.last_active_date = today
                user.save(update_fields=['last_active_date', 'current_streak'])
            elif diff == 0 and user.current_streak == 0:
                user.current_streak = 1
                user.save(update_fields=['current_streak'])
                
        return Response({"current_streak": user.current_streak, "last_active_date": user.last_active_date})

class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        user = request.user
        if serializer.is_valid():
            old_password = serializer.validated_data['old_password']
            new_password = serializer.validated_data['new_password']
            if not user.check_password(old_password):
                return Response({"error": "Old password is incorrect"}, status=status.HTTP_400_BAD_REQUEST)
            user.set_password(new_password)
            user.save()
            return Response({"message": "Password changed successfully"})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data["refresh"]
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"message": "Logged out successfully"}, status=status.HTTP_205_RESET_CONTENT)
        except Exception:
            return Response({"error": "Invalid token"}, status=status.HTTP_400_BAD_REQUEST)

def generate_otp():
    return str(random.randint(100000, 999999))

class PasswordResetRequestView(generics.GenericAPIView):
    serializer_class = PasswordResetRequestSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email'].strip().lower()
            try:
                user = User.objects.get(email=email)
                otp = generate_otp()
                cache.set(f'password_reset_otp_{email}', otp, timeout=600)

                send_mail(
                    subject="Your OTP for Password Reset",
                    message=f"Your password reset OTP is: {otp}. It is valid for 10 minutes.",
                    from_email="noreply@musiccoach.com",
                    recipient_list=[user.email],
                )
                return Response({"message": "OTP sent to your email."})
            except User.DoesNotExist:
                return Response({"error": "User with this email does not exist."}, status=status.HTTP_400_BAD_REQUEST)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetConfirmView(generics.GenericAPIView):
    serializer_class = PasswordResetConfirmSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email'].strip().lower()
            otp = str(serializer.validated_data['otp'])
            new_password = serializer.validated_data['new_password']

            cached_otp = cache.get(f'password_reset_otp_{email}')

            if cached_otp is None:
                return Response({"error": "OTP expired or invalid."}, status=status.HTTP_400_BAD_REQUEST)

            if otp != str(cached_otp):
                return Response({"error": "Incorrect OTP."}, status=status.HTTP_400_BAD_REQUEST)

            try:
                user = User.objects.get(email=email)
                user.set_password(new_password)
                user.save()
                cache.delete(f'password_reset_otp_{email}')
                return Response({"message": "Password has been reset successfully."})
            except User.DoesNotExist:
                return Response({"error": "User does not exist."}, status=status.HTTP_400_BAD_REQUEST)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

from django.utils import timezone
from datetime import timedelta
from django.db.models import Count
from django.db.models.functions import TruncDate
from apps.lessons.models import UserProgress
import random

class AdminDashboardStatsView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        total_users = User.objects.count()

        today = timezone.now().date()
        seven_days_ago = today - timedelta(days=6)

        daily_users = User.objects.filter(date_joined__date__gte=seven_days_ago) \
            .annotate(date=TruncDate('date_joined')) \
            .values('date') \
            .annotate(count=Count('id')) \
            .order_by('date')

        daily_data_dict = {str(item['date']): item['count'] for item in daily_users}

        daily_users_data = []
        for i in range(7):
            day = seven_days_ago + timedelta(days=i)
            day_str = day.strftime('%a')[0]
            daily_users_data.append({
                "name": day_str,
                "users": daily_data_dict.get(str(day), 0)
            })

        piano_completed = 0
        vocal_completed = 0
        for progress in UserProgress.objects.prefetch_related('completed_lessons__module__instrument').all():
            for lesson in progress.completed_lessons.all():
                instrument_name = lesson.module.instrument.name if lesson.module.instrument else ''
                if 'piano' in instrument_name.lower():
                    piano_completed += 1
                elif 'vocal' in instrument_name.lower():
                    vocal_completed += 1

        total_completed = piano_completed + vocal_completed

        lesson_breakdown_data = [
            {"name": "Piano", "lessons": piano_completed},
            {"name": "Vocal", "lessons": vocal_completed},
        ]

        return Response({
            "total_users": total_users,
            "total_lessons_completed": total_completed,
            "piano_lessons_completed": piano_completed,
            "vocal_lessons_completed": vocal_completed,
            "new_signups_today": daily_data_dict.get(str(today), 0),
            "daily_users_data": daily_users_data,
            "lesson_breakdown_data": lesson_breakdown_data
        })

class AdminUserListView(generics.ListCreateAPIView):
    queryset = User.objects.all().order_by('-id')
    permission_classes = [IsAdminRole]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return AdminUserWriteSerializer
        return AdminUserSerializer


class AdminUserDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    permission_classes = [IsAdminRole]

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return AdminUserWriteSerializer
        return AdminUserSerializer
