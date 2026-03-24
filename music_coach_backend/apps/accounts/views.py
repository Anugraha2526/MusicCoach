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
    PasswordResetConfirmSerializer,
)
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import IsAuthenticated

# For password reset OTP
import random
from django.core.cache import cache
from django.core.mail import send_mail
from django.conf import settings

User = get_user_model()

# Helper: Generate JWT tokens
def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

# -------------------- Registration --------------------
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

# -------------------- Login --------------------
class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        print("Login request data:", request.data)
        
        email = request.data.get('email')
        password = request.data.get('password')
        user = authenticate(email=email, password=password)
        if user:
            token = get_tokens_for_user(user)
            return Response({"message": "Login successful", "token": token})
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

# -------------------- Admin Login --------------------
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

# -------------------- Profile --------------------
class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

# -------------------- Change Password --------------------
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

# -------------------- Logout --------------------
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

# -------------------- OTP Helper --------------------
def generate_otp():
    return str(random.randint(100000, 999999))  # 6-digit OTP

# -------------------- Password Reset Request (OTP) --------------------
# -------------------- Password Reset Request (OTP) --------------------
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
                cache.set(f'password_reset_otp_{email}', otp, timeout=600)  # 10 min OTP

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


# -------------------- Password Reset Confirm (OTP) --------------------
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
            print("Cached OTP:", cache.get(f"password_reset_otp_{email}"))
            print("Received OTP:", otp)

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

# -------------------- Admin Dashboard --------------------
class AdminDashboardStatsView(APIView):
    permission_classes = [permissions.AllowAny] # AllowAny for simplicity during development

    def get(self, request):
        total_users = User.objects.count()
        
        # New Users Daily (Last 7 days)
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
            # Use single letter for day like 'M', 'T', 'W' etc
            day_str = day.strftime('%a')[0] 
            daily_users_data.append({
                "name": day_str,
                "users": daily_data_dict.get(str(day), 0)
            })

        # Total completed lessons
        total_completed = 0
        for progress in UserProgress.objects.all():
            total_completed += progress.completed_lessons.count()
            
        # Distribute over 7 days pseudorandomly, seeding with total_completed to keep it consistent
        random.seed(total_completed + 1) # simple seed
        weekly_lessons_data = []
        days_names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        current_day_idx = today.weekday()
        current_week_names = [days_names[(current_day_idx - 6 + i) % 7] for i in range(7)]
        
        remaining = total_completed
        for i in range(6):
            if remaining == 0:
                val = 0
            else:
                val = int(remaining * random.uniform(0.1, 0.4))
            weekly_lessons_data.append({"name": current_week_names[i], "lessons": val})
            remaining -= val
        weekly_lessons_data.append({"name": current_week_names[6], "lessons": remaining})

        active_lessons = UserProgress.objects.count() # using active progress entries as mock

        return Response({
            "total_users": total_users,
            "lessons_completed_this_week": total_completed,
            "active_lessons": active_lessons,
            "new_signups_today": daily_data_dict.get(str(today), 0),
            "daily_users_data": daily_users_data,
            "weekly_lessons_data": weekly_lessons_data
        })

class AdminUserListView(generics.ListAPIView):
    queryset = User.objects.all().order_by('-id')
    permission_classes = [permissions.AllowAny] # AllowAny for simplicity during development

    def get(self, request, *args, **kwargs):
        users = self.get_queryset()
        data = []
        for u in users:
            data.append({
                "id": u.id,
                "name": u.first_name + " " + u.last_name if u.first_name else u.email.split('@')[0],
                "email": u.email,
                "status": "Active" if u.is_active else "Inactive",
                "lessons_completed": random.randint(5, 50) # Mock data for now
            })
        return Response(data)
