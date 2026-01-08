"""
Serializers for the Lessons app.

These serializers convert Django model instances to JSON for API responses.
Nested serializers provide complete data in single API calls.
"""

from rest_framework import serializers
from .models import Module, Lesson, PracticeSequence


class PracticeSequenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = PracticeSequence
        fields = ['id', 'order', 'notes']


class LessonSerializer(serializers.ModelSerializer):
    """Serializer for lessons."""
    class Meta:
        model = Lesson
        fields = ['id', 'title', 'lesson_type', 'order']


class LessonListSerializer(serializers.ModelSerializer):
    """Light serializer for lesson lists."""
    class Meta:
        model = Lesson
        fields = ['id', 'title', 'lesson_type', 'order']


class ModuleSerializer(serializers.ModelSerializer):
    """Serializer for modules with nested lessons."""
    lessons = LessonListSerializer(many=True, read_only=True)

    class Meta:
        model = Module
        fields = ['id', 'title', 'description', 'order', 'lessons']
