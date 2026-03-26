from django.urls import path
from .views import (
    RegisterView, LoginView, AdminLoginView, ProfileView, ChangePasswordView, LogoutView,
    PasswordResetRequestView, PasswordResetConfirmView,
    AdminDashboardStatsView, AdminUserListView, AdminUserDetailView
)
from apps.lessons.admin_views import (
    AdminModuleListView, AdminModuleDetailView,
    AdminLessonListView, AdminLessonDetailView,
    AdminInstrumentListView,
)
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('password-reset/', PasswordResetRequestView.as_view(), name='password-reset'),
    path('password-reset-confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Admin Dashboard URLs
    path('admin/login/', AdminLoginView.as_view(), name='admin-login'),
    path('admin/stats/', AdminDashboardStatsView.as_view(), name='admin-stats'),
    path('admin/users/', AdminUserListView.as_view(), name='admin-users'),
    path('admin/users/<int:pk>/', AdminUserDetailView.as_view(), name='admin-user-detail'),

    # Admin Lesson Management
    path('admin/modules/', AdminModuleListView.as_view(), name='admin-modules'),
    path('admin/modules/<int:pk>/', AdminModuleDetailView.as_view(), name='admin-module-detail'),
    path('admin/lessons/', AdminLessonListView.as_view(), name='admin-lessons'),
    path('admin/lessons/<int:pk>/', AdminLessonDetailView.as_view(), name='admin-lesson-detail'),
    path('admin/instruments/', AdminInstrumentListView.as_view(), name='admin-instruments'),
]
