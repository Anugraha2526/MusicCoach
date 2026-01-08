from django.shortcuts import render, get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Module, Lesson, PracticeSequence
from .serializers import (
    ModuleSerializer, 
    LessonSerializer, 
    PracticeSequenceSerializer
)


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
