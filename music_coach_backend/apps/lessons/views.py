from django.shortcuts import render, get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
import asyncio

from .models import Module, Lesson, PracticeSequence, UserProgress
from .serializers import (
    ModuleSerializer, 
    LessonSerializer, 
    PracticeSequenceSerializer,
    UserProgressSerializer
)
from rest_framework.permissions import IsAuthenticated


class BaseLessonsView(APIView):
    """
    Base view for fetching all lesson modules.
    """
    def get(self, request):
        instrument_type = request.query_params.get('instrument')
        modules = Module.objects.all()
        if instrument_type:
            modules = modules.filter(instrument__type=instrument_type)
        serializer = ModuleSerializer(modules, many=True)
        return Response(serializer.data)


class LessonDetailView(APIView):
    """
    Fetch details for a specific lesson.
    """
    def get(self, request, lesson_id):
        try:
            lesson = Lesson.objects.get(pk=lesson_id)
            serializer = LessonSerializer(lesson)
            return Response(serializer.data)
        except Lesson.DoesNotExist:
            return Response(
                {"error": "Lesson not found"}, 
                status=status.HTTP_404_NOT_FOUND
            )


class LessonSequencesView(APIView):
    """
    Get all practice sequences for a specific lesson.
    """
    def get(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, pk=lesson_id)
        sequences = PracticeSequence.objects.filter(lesson=lesson)
        serializer = PracticeSequenceSerializer(sequences, many=True)
        return Response(serializer.data)


class GetProgressView(APIView):
    """
    Get the currently logged-in user's completed lessons.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        progress, created = UserProgress.objects.get_or_create(user=request.user)
        serializer = UserProgressSerializer(progress)
        return Response(serializer.data)


class SyncProgressView(APIView):
    """
    Sync lessons from the client to the backend.
    Accepts a list of lesson IDs and adds them to the user's progress.
    After saving, broadcasts updated stats to all admin dashboard WebSocket clients.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        lesson_ids = request.data.get('lesson_ids', [])
        if not isinstance(lesson_ids, list):
            return Response({"error": "lesson_ids must be a list"}, status=status.HTTP_400_BAD_REQUEST)
        
        progress, created = UserProgress.objects.get_or_create(user=request.user)
        
        # Add the lessons to the progress
        valid_lessons = Lesson.objects.filter(id__in=lesson_ids)
        progress.completed_lessons.add(*valid_lessons)
        
        # Broadcast updated stats to all admin WebSocket clients
        self._broadcast_stats()
        
        # Return updated list
        serializer = UserProgressSerializer(progress)
        return Response(serializer.data)

    def _broadcast_stats(self):
        """Compute fresh stats and push to the admin dashboard channel group."""
        try:
            from channels.layers import get_channel_layer
            from asgiref.sync import async_to_sync
            from apps.lessons.consumers import STATS_GROUP
            from django.contrib.auth import get_user_model
            from django.utils import timezone
            from datetime import timedelta
            from django.db.models import Count
            from django.db.models.functions import TruncDate

            User = get_user_model()
            today = timezone.now().date()
            seven_days_ago = today - timedelta(days=6)

            daily_users = (
                User.objects.filter(date_joined__date__gte=seven_days_ago)
                .annotate(date=TruncDate("date_joined"))
                .values("date")
                .annotate(count=Count("id"))
                .order_by("date")
            )
            daily_data_dict = {str(item["date"]): item["count"] for item in daily_users}
            daily_users_data = []
            for i in range(7):
                day = seven_days_ago + timedelta(days=i)
                daily_users_data.append({
                    "name": day.strftime("%a")[0],
                    "users": daily_data_dict.get(str(day), 0),
                })

            piano_completed = 0
            vocal_completed = 0
            for prog in UserProgress.objects.prefetch_related(
                "completed_lessons__module__instrument"
            ).all():
                for lesson in prog.completed_lessons.all():
                    name = (
                        lesson.module.instrument.name
                        if lesson.module.instrument
                        else ""
                    )
                    if "piano" in name.lower():
                        piano_completed += 1
                    elif "vocal" in name.lower():
                        vocal_completed += 1

            total_completed = piano_completed + vocal_completed

            # Per-user lesson counts for the Users page
            from apps.accounts.serializers import AdminUserSerializer
            users_qs = User.objects.prefetch_related(
                'progress__completed_lessons__module__instrument'
            ).all().order_by('-id')
            users_data = AdminUserSerializer(users_qs, many=True).data

            stats_payload = {
                "type": "stats_update",
                "total_users": User.objects.count(),
                "total_lessons_completed": total_completed,
                "piano_lessons_completed": piano_completed,
                "vocal_lessons_completed": vocal_completed,
                "new_signups_today": daily_data_dict.get(str(today), 0),
                "daily_users_data": daily_users_data,
                "lesson_breakdown_data": [
                    {"name": "Piano", "lessons": piano_completed},
                    {"name": "Vocal", "lessons": vocal_completed},
                ],
                "users": list(users_data),
            }

            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                STATS_GROUP,
                {"type": "stats_update", "data": stats_payload},
            )
        except Exception as e:
            # Don't let WS broadcast failure break the API response
            print(f"[WebSocket broadcast error] {e}")

