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
