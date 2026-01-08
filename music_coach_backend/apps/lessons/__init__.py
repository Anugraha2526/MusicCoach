"""
Lessons App - Django application for managing music lessons, quizzes, and notation.

This app provides the backend for the Duolingo-style lesson system including:
- Modules (levels) containing multiple lessons
- Lessons with theory, quiz, and practice content
- LessonUnits for text, audio, image, and notation content
- Quizzes (multiple choice and match-the-following)
- Musical notation data for piano exercises
"""

default_app_config = 'apps.lessons.apps.LessonsConfig'
