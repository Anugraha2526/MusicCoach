from django.urls import path
from .views import (
    BaseLessonsView, 
    LessonDetailView,
    LessonSequencesView
)

urlpatterns = [
    # List all modules and lessons
    path('', BaseLessonsView.as_view(), name='lessons-list'),
    
    # Lesson Details
    path('<int:lesson_id>/', LessonDetailView.as_view(), name='lesson-detail'),
    
    # Practice Sequences (Interactive Game)
    path('<int:lesson_id>/sequences/', LessonSequencesView.as_view(), name='lesson-sequences'),
]
