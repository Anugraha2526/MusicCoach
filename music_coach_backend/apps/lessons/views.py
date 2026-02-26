from django.shortcuts import render, get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

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
        modules = Module.objects.all()
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
        
        # Return updated list
        serializer = UserProgressSerializer(progress)
        return Response(serializer.data)
