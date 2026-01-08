"""
Management command to seed Level 1, Lesson 1 data.

Run with: python manage.py seed_lessons

This creates:
- 1 Module (Level 1)
- 1 Lesson (Lesson 1: Introduction to Piano)
- Practice Sequences for interactive lesson
"""

from django.core.management.base import BaseCommand
from apps.lessons.models import Module, Lesson, PracticeSequence


class Command(BaseCommand):
    help = 'Seed database with Level 1, Lesson 1 content'

    def handle(self, *args, **options):
        self.stdout.write('Seeding lesson data...')

        # Create Module (Level 1)
        module, created = Module.objects.get_or_create(
            order=1,
            defaults={
                'title': 'Level 1',
                'description': 'Introduction to Piano - Learn the basics of piano playing',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created module: {module.title}'))
        else:
            self.stdout.write(f'Module already exists: {module.title}')

        # Create Lesson 1
        lesson, created = Lesson.objects.get_or_create(
            module=module,
            order=1,
            defaults={
                'title': 'Introduction to Piano',
                'lesson_type': 'theory',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {lesson.title}')
            # Clear existing data for strict re-seed
            lesson.sequences.all().delete()
            self.stdout.write('Cleared existing sequences for re-seed')

        # =====================
        # DYNAMIC PRACTICE SEQUENCES
        # =====================
        self.stdout.write('Creating practice sequences...')
        sequences = [
            # Part 1: CCDD
            {"order": 1, "notes": ["C", "C", "D", "D"]},
            # Part 2: CCDDE
            {"order": 2, "notes": ["C", "C", "D", "D", "E"]},
            # Part 3: CCDDED
            {"order": 3, "notes": ["C", "C", "D", "D", "E", "D"]},
            # Part 4: CCDDEDC
            {"order": 4, "notes": ["C", "C", "D", "D", "E", "D", "C"]},
        ]

        for seq_data in sequences:
            PracticeSequence.objects.create(
                lesson=lesson,
                order=seq_data['order'],
                notes=seq_data['notes']
            )

        self.stdout.write(self.style.SUCCESS(f'Successfully seeded sequences for "{lesson.title}"'))
        
        self.stdout.write('')
        self.stdout.write('Summary:')
        self.stdout.write(f'  - 1 Module (Level 1)')
        self.stdout.write(f'  - 1 Lesson (Introduction to Piano)')
        self.stdout.write(f'  - {len(sequences)} Practice Sequences')
