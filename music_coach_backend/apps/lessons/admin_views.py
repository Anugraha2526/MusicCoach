"""
Admin views for managing Lessons, Modules, and PracticeSequences.
All endpoints require admin role authentication.
"""

from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.accounts.permissions import IsAdminRole
from apps.instruments.models import Instrument
from .models import Module, Lesson, PracticeSequence
from .admin_serializers import (
    AdminModuleSerializer,
    AdminLessonSerializer,
    AdminLessonWriteSerializer,
    AdminPracticeSequenceSerializer,
    AdminInstrumentSerializer,
)


class AdminModuleListView(generics.ListCreateAPIView):
    """List all modules or create a new one."""
    queryset = Module.objects.select_related('instrument').prefetch_related('lessons__sequences').all()
    serializer_class = AdminModuleSerializer
    permission_classes = [IsAdminRole]


class AdminModuleDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a module."""
    queryset = Module.objects.select_related('instrument').prefetch_related('lessons__sequences').all()
    serializer_class = AdminModuleSerializer
    permission_classes = [IsAdminRole]


class AdminLessonListView(generics.ListCreateAPIView):
    """List all lessons or create a new one."""
    permission_classes = [IsAdminRole]

    def get_queryset(self):
        qs = Lesson.objects.select_related('module__instrument').prefetch_related('sequences').all()
        module_id = self.request.query_params.get('module')
        if module_id:
            qs = qs.filter(module_id=module_id)
        return qs

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return AdminLessonWriteSerializer
        return AdminLessonSerializer


class AdminLessonDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a lesson and its sequences."""
    queryset = Lesson.objects.select_related('module__instrument').prefetch_related('sequences').all()
    permission_classes = [IsAdminRole]

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return AdminLessonWriteSerializer
        return AdminLessonSerializer


class AdminInstrumentListView(generics.ListAPIView):
    """List all instruments (for dropdowns)."""
    queryset = Instrument.objects.all()
    serializer_class = AdminInstrumentSerializer
    permission_classes = [IsAdminRole]
