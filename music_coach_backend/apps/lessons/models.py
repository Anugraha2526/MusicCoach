"""
Lessons Models - Core data models for the lesson system.

Models:
- Module: Represents a level (e.g., Level 1, Level 2)
- Lesson: Individual lessons within a module
- PracticeSequence: Dynamic note sequences for interactive piano lessons

To add new lessons:
1. Create a Module for the level
2. Add Lessons to the module
3. Add PracticeSequence records for the interactive game
"""

from django.db import models


class Module(models.Model):
    """
    Represents a learning module/level (e.g., Level 1, Level 2).
    Each module contains multiple lessons.
    """
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    order = models.PositiveIntegerField(default=0, help_text="Display order of the module")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'modules'
        ordering = ['order']

    def __str__(self):
        return f"Module {self.order}: {self.title}"


class Lesson(models.Model):
    """
    Individual lesson within a module.
    Types: theory, quiz, practice (determines lesson focus)
    """
    LESSON_TYPES = [
        ('theory', 'Theory'),
        ('quiz', 'Quiz'),
        ('practice', 'Practice'),
    ]

    module = models.ForeignKey(Module, on_delete=models.CASCADE, related_name='lessons')
    title = models.CharField(max_length=200)
    lesson_type = models.CharField(max_length=20, choices=LESSON_TYPES, default='theory')
    order = models.PositiveIntegerField(default=0, help_text="Order within the module")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'lessons'
        ordering = ['module__order', 'order']

    def __str__(self):
        return f"Lesson {self.order}: {self.title} ({self.module.title})"


class PracticeSequence(models.Model):
    """
    Dynamic note sequence for interactive piano lessons.
    Example: ["C", "C", "D", "D"]
    """
    SEQUENCE_TYPES = [
        ('listen', 'Listen & Repeat'),
        ('learn', 'Learn Note'),
        ('identify', 'Identify Note'),
        ('read', 'Sight Reading'),
    ]

    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='sequences')
    order = models.PositiveIntegerField(default=1, help_text="Part number (1, 2, 3...)")
    sequence_type = models.CharField(max_length=20, choices=SEQUENCE_TYPES, default='listen', help_text="Type of interaction")
    notes = models.JSONField(help_text="List of notes, e.g. ['C', 'D', 'E']")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'practice_sequences'
        ordering = ['order']

    def __str__(self):
        return f"Sequence {self.order} for {self.lesson.title}"
