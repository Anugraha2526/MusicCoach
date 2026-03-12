"""
Management command to seed Vocal Level 1, Lesson 1 data.

Run with: python manage.py seed_vocal_lessons

This creates:
- 1 Module (Level 1) linked to Vocals instrument
- 1 Lesson (Lesson 1: Singing on 'mum')
- No practice sequences — notes are generated dynamically on the frontend
  based on the user's calibrated natural pitch.
"""

from django.core.management.base import BaseCommand
from apps.lessons.models import Module, Lesson, PracticeSequence
from apps.instruments.models import Instrument


class Command(BaseCommand):
    help = "Seed database with Vocal Level 1, Lesson 1 content"

    def handle(self, *args, **options):
        self.stdout.write('Seeding vocal lesson data...')

        # Find or create Vocals instrument
        vocals_instrument, created = Instrument.objects.get_or_create(
            name='Vocal Lessons',
            defaults={
                'type': 'vocals',
                'image_url': '',
            }
        )

        # Create Module 1 (Vocal Level 1)
        module1, _ = Module.objects.get_or_create(
            order=1,
            instrument=vocals_instrument,
            defaults={'title': 'Level 1', 'description': 'Introduction to Vocals'}
        )
        self.stdout.write(f'Ensured Level 1 module: {module1.title}')

        # Create Module 2 (Vocal Level 2)
        module2, _ = Module.objects.get_or_create(
            order=2,
            instrument=vocals_instrument,
            defaults={'title': 'Level 2', 'description': 'Vocal Warmups'}
        )
        self.stdout.write(f'Ensured Level 2 module: {module2.title}')

        # Create Lesson 1 for Level 1: Ascent & Descent
        lesson1_1, created = Lesson.objects.get_or_create(
            module=module1,
            order=1,
            defaults={'title': "Ascent & Descent", 'lesson_type': 'practice'}
        )
        if not created:
            lesson1_1.title = "Ascent & Descent"
            lesson1_1.save()
            deleted_count = lesson1_1.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 1 Lesson 1')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson1_1.title}'))

        # Create Lesson 2 for Level 1: Swifter
        lesson1_2, created = Lesson.objects.get_or_create(
            module=module1,
            order=2,
            defaults={'title': "Swifter", 'lesson_type': 'practice'}
        )
        if not created:
            lesson1_2.title = "Swifter"
            lesson1_2.save()
            deleted_count = lesson1_2.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 1 Lesson 2')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson1_2.title}'))

        # Create Lesson 3 for Level 1: Pacing Up
        lesson1_3, created = Lesson.objects.get_or_create(
            module=module1,
            order=3,
            defaults={'title': "Pacing Up", 'lesson_type': 'practice'}
        )
        if not created:
            lesson1_3.title = "Pacing Up"
            lesson1_3.save()
            deleted_count = lesson1_3.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 1 Lesson 3')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson1_3.title}'))

        # Create Lesson 4 for Level 1: Double Step
        lesson1_4, created = Lesson.objects.get_or_create(
            module=module1,
            order=4,
            defaults={'title': "Double Step", 'lesson_type': 'practice'}
        )
        if not created:
            lesson1_4.title = "Double Step"
            lesson1_4.save()
            deleted_count = lesson1_4.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 1 Lesson 4')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson1_4.title}'))

        # Create Lesson 5 for Level 1: Chug Along
        lesson1_5, created = Lesson.objects.get_or_create(
            module=module1,
            order=5,
            defaults={'title': "Chug Along", 'lesson_type': 'practice'}
        )
        if not created:
            lesson1_5.title = "Chug Along"
            lesson1_5.save()
            deleted_count = lesson1_5.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 1 Lesson 5')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson1_5.title}'))

        # Create Lesson 1 for Level 2: Singing on "mum"
        lesson2_1, created = Lesson.objects.get_or_create(
            module=module2,
            order=1,
            defaults={'title': "Singing on 'mum'", 'lesson_type': 'practice'}
        )

        if not created:
            lesson2_1.title = "Singing on 'mum'"
            lesson2_1.save()
            deleted_count = lesson2_1.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 2 Lesson 1')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson2_1.title}'))

        self.stdout.write(self.style.SUCCESS(
            "\nSuccessfully seeded vocal lessons.\n"
            "Note: sequences are generated dynamically on the frontend "
            "based on each user's natural pitch."
        ))
