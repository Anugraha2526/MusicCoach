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
    UserProgressSerializer,
    PitchHistorySerializer
)
from rest_framework.permissions import IsAuthenticated


class BaseLessonsView(APIView):
    def get(self, request):
        instrument_type = request.query_params.get('instrument')
        modules = Module.objects.all()
        if instrument_type:
            modules = modules.filter(instrument__type=instrument_type)
        serializer = ModuleSerializer(modules, many=True)
        return Response(serializer.data)


class PitchHistoryListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .models import PitchHistory
        history = PitchHistory.objects.filter(user=request.user)
        serializer = PitchHistorySerializer(history, many=True)
        return Response(serializer.data)

    def post(self, request):
        from .models import PitchHistory
        serializer = PitchHistorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PitchHistoryDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        from .models import PitchHistory
        history = get_object_or_404(PitchHistory, pk=pk, user=request.user)
        history.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class LessonDetailView(APIView):
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
    def get(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, pk=lesson_id)
        sequences = PracticeSequence.objects.filter(lesson=lesson)
        serializer = PracticeSequenceSerializer(sequences, many=True)
        return Response(serializer.data)


class GetProgressView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        progress = UserProgress.objects.filter(user=request.user).first()
        if not progress:
            progress = UserProgress.objects.create(user=request.user)

        from apps.lessons.models import Lesson
        completed_ids = list(Lesson.objects.filter(completed_by__user=request.user).distinct().values_list('id', flat=True))
        return Response({'completed_lesson_ids': completed_ids})


class SyncProgressView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        lesson_ids = request.data.get('lesson_ids', [])
        if not isinstance(lesson_ids, list):
            return Response({"error": "lesson_ids must be a list"}, status=status.HTTP_400_BAD_REQUEST)

        progress = UserProgress.objects.filter(user=request.user).first()
        if not progress:
            progress = UserProgress.objects.create(user=request.user)

        valid_lessons = Lesson.objects.filter(id__in=lesson_ids)
        progress.completed_lessons.add(*valid_lessons)

        self._broadcast_stats()

        from apps.lessons.models import Lesson as L
        completed_ids = list(L.objects.filter(completed_by__user=request.user).distinct().values_list('id', flat=True))
        return Response({'completed_lesson_ids': completed_ids})

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
            
            from apps.lessons.models import Lesson
            users = User.objects.all()
            for u in users:
                piano_completed += Lesson.objects.filter(completed_by__user=u, module__instrument__name__icontains='piano').distinct().count()
                vocal_completed += Lesson.objects.filter(completed_by__user=u, module__instrument__name__icontains='vocal').distinct().count()

            total_completed = piano_completed + vocal_completed

            # Per-user data for admin
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
        except Exception:
            pass


class GenerateFeedbackView(APIView):
    permission_classes = [IsAuthenticated]

    FALLBACKS = {
        3: [
            "Absolutely flawless, you nailed it! Every practice session is paying off beautifully.",
            "Perfect performance! You are proving that dedication truly makes a difference.",
            "Incredible work, a flawless run! Keep this momentum going and great things await you.",
        ],
        2: [
            "Great effort, you are really getting better! A bit more practice and those 3 stars are yours.",
            "Solid performance! Keep pushing and perfection is just around the corner for you.",
            "You are so close to perfect! Great job, keep practicing to nail every note.",
        ],
        1: [
            "You completed it and that is what matters! Every attempt makes you a stronger musician.",
            "Great persistence finishing the lesson! Keep at it and you will improve each time.",
            "You did it! Progress takes time so keep practising and you will see big improvements soon.",
        ],
        None: [
            "Fantastic work completing this lesson! Keep up the momentum and you will master it.",
            "Great job finishing the lesson! Every step forward in music is worth celebrating.",
            "Well done on completing another lesson! You are making real progress, keep it up.",
            "Lesson complete! Your dedication to learning is truly inspiring, keep going!",
            "Excellent work today! Each lesson you finish brings you closer to becoming a musician.",
        ],
    }

    def post(self, request):
        import random as _random
        import json
        import http.client
        from django.conf import settings

        stars = request.data.get("stars", None)

        try:
            star_label = {3: "3 out of 3 (perfect)", 2: "2 out of 3", 1: "1 out of 3"}.get(stars, "some")
            instrument = request.data.get("instrument", "music")
            prompt = (
                f"Write exactly one short, enthusiastic, and motivating sentence of feedback "
                f"for a {instrument} student who just finished a lesson and earned {star_label} stars. "
                f"Do not include any extra commentary, just the sentence itself."
            )

            api_key = getattr(settings, 'HUGGINGFACE_API_KEY', '')
            payload = json.dumps({
                "model": "Qwen/Qwen2.5-7B-Instruct-Turbo",
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 80,
                "temperature": 0.85
            }).encode("utf-8")

            req_headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            }

            conn = http.client.HTTPSConnection("router.huggingface.co", timeout=5)
            conn.request("POST", "/together/v1/chat/completions", payload, req_headers)
            res = conn.getresponse()
            body = res.read().decode("utf-8")
            conn.close()

            if res.status == 200:
                data = json.loads(body)
                generated_message = data["choices"][0]["message"]["content"].strip()
                if generated_message and len(generated_message) > 5:
                    return Response({"message": generated_message, "source": "ai"})
        except Exception:
            pass

        # Fallback to local randomized lists based on performance
        fallback_list = self.FALLBACKS.get(stars, self.FALLBACKS[None])
        message = _random.choice(fallback_list)

        return Response({"message": message, "source": "fallback"})

