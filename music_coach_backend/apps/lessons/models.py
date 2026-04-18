
from django.db import models


class Module(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    instrument = models.ForeignKey('instruments.Instrument', on_delete=models.CASCADE, related_name='modules', null=True, blank=True)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'modules'
        ordering = ['order']

    def __str__(self):
        return f"Module {self.order}: {self.title}"


class Lesson(models.Model):
    LESSON_TYPES = [
        ('theory', 'Theory'),
        ('quiz', 'Quiz'),
        ('practice', 'Practice'),
    ]

    module = models.ForeignKey(Module, on_delete=models.CASCADE, related_name='lessons')
    title = models.CharField(max_length=200)
    lesson_type = models.CharField(max_length=20, choices=LESSON_TYPES, default='theory')
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'lessons'
        ordering = ['module__order', 'order']

    def __str__(self):
        return f"Lesson {self.order}: {self.title} ({self.module.title})"


class PracticeSequence(models.Model):
    SEQUENCE_TYPES = [
        ('listen', 'Listen & Repeat'),
        ('learn', 'Learn Note'),
        ('identify', 'Identify Note'),
        ('read', 'Sight Reading'),
        ('play', 'Play Mode'),
        ('perform', 'Perform (Scored)'),
        ('tap', 'Tap Mode'),
        ('place', 'Place Note'),
    ]

    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='sequences')
    order = models.PositiveIntegerField(default=1)
    sequence_type = models.CharField(max_length=20, choices=SEQUENCE_TYPES, default='listen')
    notes = models.JSONField()
    lyrics = models.JSONField(null=True, blank=True)
    time_signature = models.CharField(max_length=10, default="4/4")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'practice_sequences'
        ordering = ['order']

    def __str__(self):
        return f"Sequence {self.order} for {self.lesson.title}"


class UserProgress(models.Model):
    from django.conf import settings
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='progress')
    completed_lessons = models.ManyToManyField(Lesson, related_name='completed_by', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_progress'

    def __str__(self):
        return f"Progress for {self.user.username}"


class PitchHistory(models.Model):
    from django.conf import settings
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='pitch_history')
    duration_seconds = models.FloatField()
    pitch_data = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'pitch_history'
        ordering = ['-created_at']

    def __str__(self):
        return f"Pitch History for {self.user.username} on {self.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
