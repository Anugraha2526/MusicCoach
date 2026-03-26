"""
Admin-specific serializers for managing Lessons, Modules, and PracticeSequences.
These provide full CRUD capabilities with nested writes for admin dashboard.
"""

from rest_framework import serializers
from .models import Module, Lesson, PracticeSequence
from apps.instruments.models import Instrument


class AdminPracticeSequenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = PracticeSequence
        fields = ['id', 'order', 'sequence_type', 'notes', 'lyrics', 'time_signature']


class AdminLessonSerializer(serializers.ModelSerializer):
    sequences = AdminPracticeSequenceSerializer(many=True, read_only=True)
    module_title = serializers.CharField(source='module.title', read_only=True)
    instrument_name = serializers.CharField(source='module.instrument.name', read_only=True)

    class Meta:
        model = Lesson
        fields = [
            'id', 'module', 'module_title', 'instrument_name',
            'title', 'lesson_type', 'order', 'sequences',
            'created_at', 'updated_at'
        ]


class AdminLessonWriteSerializer(serializers.ModelSerializer):
    """Writable serializer for creating/updating lessons."""
    sequences = AdminPracticeSequenceSerializer(many=True, required=False)

    class Meta:
        model = Lesson
        fields = ['id', 'module', 'title', 'lesson_type', 'order', 'sequences']

    def create(self, validated_data):
        sequences_data = validated_data.pop('sequences', [])
        lesson = Lesson.objects.create(**validated_data)
        for seq_data in sequences_data:
            PracticeSequence.objects.create(lesson=lesson, **seq_data)
        return lesson

    def update(self, instance, validated_data):
        sequences_data = validated_data.pop('sequences', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if sequences_data is not None:
            # Replace all sequences with the new set
            instance.sequences.all().delete()
            for seq_data in sequences_data:
                PracticeSequence.objects.create(lesson=instance, **seq_data)

        return instance


class AdminModuleSerializer(serializers.ModelSerializer):
    lessons = AdminLessonSerializer(many=True, read_only=True)
    instrument_name = serializers.CharField(source='instrument.name', read_only=True)
    lesson_count = serializers.SerializerMethodField()

    class Meta:
        model = Module
        fields = [
            'id', 'title', 'description', 'instrument', 'instrument_name',
            'order', 'lesson_count', 'lessons', 'created_at', 'updated_at'
        ]

    def get_lesson_count(self, obj):
        return obj.lessons.count()


class AdminInstrumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Instrument
        fields = ['id', 'name', 'type']
