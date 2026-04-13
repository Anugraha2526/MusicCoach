from django.urls import path
from .views import (
    BaseLessonsView, 
    LessonDetailView,
    LessonSequencesView,
    GetProgressView,
    SyncProgressView,
    PitchHistoryListCreateView,
    PitchHistoryDetailView,
    GenerateFeedbackView,
)

urlpatterns = [
    # List all modules and lessons
    path('', BaseLessonsView.as_view(), name='lessons-list'),
    
    # Lesson Details
    path('<int:lesson_id>/', LessonDetailView.as_view(), name='lesson-detail'),
    
    # Practice Sequences (Interactive Game)
    path('<int:lesson_id>/sequences/', LessonSequencesView.as_view(), name='lesson-sequences'),
    
    # Progress endpoints
    path('progress/', GetProgressView.as_view(), name='lesson-progress-get'),
    path('progress/sync/', SyncProgressView.as_view(), name='lesson-progress-sync'),
    path('progress/feedback/', GenerateFeedbackView.as_view(), name='lesson-feedback'),
    
    # Pitch History
    path('pitch-history/', PitchHistoryListCreateView.as_view(), name='pitch-history'),
    path('pitch-history/<int:pk>/', PitchHistoryDetailView.as_view(), name='pitch-history-detail'),
]
