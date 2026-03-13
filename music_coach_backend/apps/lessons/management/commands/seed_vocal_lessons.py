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

        # Create Lesson 1 for Level 2: Wave Pattern (12321 pattern)
        lesson2_1, created = Lesson.objects.get_or_create(
            module=module2,
            order=1,
            defaults={'title': "Little Steps (12321)", 'lesson_type': 'practice'}
        )
        if not created:
            lesson2_1.title = "Little Steps (12321)"
            lesson2_1.save()
            deleted_count = lesson2_1.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 2 Lesson 1')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson2_1.title}'))

        # Create Lesson 2 for Level 2: Go Further (123454321)
        lesson2_2, created = Lesson.objects.get_or_create(
            module=module2,
            order=2,
            defaults={'title': "Go Further (123454321)", 'lesson_type': 'practice'}
        )
        if not created:
            lesson2_2.title = "Go Further (123454321)"
            lesson2_2.save()
            deleted_count = lesson2_2.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 2 Lesson 2')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson2_2.title}'))

        # Create Lesson 3 for Level 2: Jumps (15151)
        lesson2_3, created = Lesson.objects.get_or_create(
            module=module2,
            order=3,
            defaults={'title': "Jumps (15151)", 'lesson_type': 'practice'}
        )
        if not created:
            lesson2_3.title = "Jumps (15151)"
            lesson2_3.save()
            deleted_count = lesson2_3.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 2 Lesson 3')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson2_3.title}'))

        # Create Lesson 4 for Level 2: Ascent (12345)
        lesson2_4, created = Lesson.objects.get_or_create(
            module=module2,
            order=4,
            defaults={'title': "Ascent (12345)", 'lesson_type': 'practice'}
        )
        if not created:
            lesson2_4.title = "Ascent (12345)"
            lesson2_4.save()
            deleted_count = lesson2_4.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 2 Lesson 4')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson2_4.title}'))

        # Create Lesson 5 for Level 2: Descent (54321)
        lesson2_5, created = Lesson.objects.get_or_create(
            module=module2,
            order=5,
            defaults={'title': "Descent (54321)", 'lesson_type': 'practice'}
        )
        if not created:
            lesson2_5.title = "Descent (54321)"
            lesson2_5.save()
            deleted_count = lesson2_5.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 2 Lesson 5')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson2_5.title}'))

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
        # Create Modules 3, 4, 5
        module3, _ = Module.objects.get_or_create(
            order=3, instrument=vocals_instrument,
            defaults={'title': 'Level 3', 'description': 'Vocal Exercises'}
        )
        module4, _ = Module.objects.get_or_create(
            order=4, instrument=vocals_instrument,
            defaults={'title': 'Level 4', 'description': 'Advanced Vocal Exercises'}
        )
        module5, _ = Module.objects.get_or_create(
            order=5, instrument=vocals_instrument,
            defaults={'title': 'Level 5', 'description': 'Vocal Mastery'}
        )

        # Create Lessons for Level 3 (Same patterns as Level 2 but for "Aa...")
        l3_titles = [
            "Little Steps (12321)",
            "Go Further (123454321)",
            "Jumps (15151)",
            "Ascent (12345)",
            "Descent (54321)"
        ]
        
        for idx, title in enumerate(l3_titles, start=1):
            lesson, created = Lesson.objects.get_or_create(
                module=module3,
                order=idx,
                defaults={'title': title, 'lesson_type': 'practice'}
            )
            if not created:
                lesson.title = title
                lesson.save()
                deleted_count = lesson.sequences.all().delete()[0]
                self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 3 Lesson {idx}')
            else:
                self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson.title}'))

        # Create Lesson 1 for Level 4: Singing on "mum"
        lesson4_1, created = Lesson.objects.get_or_create(
            module=module4,
            order=1,
            defaults={'title': "Singing on 'mum'", 'lesson_type': 'practice'}
        )
        if not created:
            lesson4_1.title = "Singing on 'mum'"
            lesson4_1.save()
            deleted_count = lesson4_1.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 4 Lesson 1')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson4_1.title}'))

        # Clean up old locations if it exists
        Lesson.objects.filter(module=module1, order=1, title="Singing on 'mum'").delete()
        Lesson.objects.filter(module=module2, order=1, title="Singing on 'mum'").delete()
        Lesson.objects.filter(module=module5, order=1, title="Singing on 'mum'").delete()

        self.stdout.write(self.style.SUCCESS(
            "\nSuccessfully seeded vocal lessons.\n"
            "Note: sequences are generated dynamically on the frontend "
            "based on each user's natural pitch."
        ))
