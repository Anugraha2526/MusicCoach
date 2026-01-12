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
        # =====================
        # LESSON 1: INTRODUCTION (Classic Simon Says)
        # =====================
        self.stdout.write('Seeding sequences for "Introduction to Piano"...')
        # Clear existing
        lesson.sequences.all().delete()
        
        lesson1_sequences = [
            {"order": 1, "notes": ["C", "C", "D", "D"]},
            {"order": 2, "notes": ["C", "C", "D", "D", "E"]},
            {"order": 3, "notes": ["C", "C", "D", "D", "E", "D"]},
            {"order": 4, "notes": ["C", "C", "D", "D", "E", "D", "C"]},
        ]

        for seq_data in lesson1_sequences:
            PracticeSequence.objects.create(
                lesson=lesson,
                order=seq_data['order'],
                sequence_type='listen', # Default type
                notes=seq_data['notes']
            )

        # =====================
        # LESSON 2: NOTES C, D, E (New Types)
        # =====================
        lesson2, created = Lesson.objects.get_or_create(
            module=module,
            order=2,
            defaults={
                'title': 'Notes C, D, E',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson2.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {lesson2.title}')
            # Clear existing data
            lesson2.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{lesson2.title}"...')
        lesson2_sequences = [
            # 1. Learn C (Visual + Mini-map)
            {"order": 1, "type": "learn", "notes": ["C"]},
            # 2. Learn D
            {"order": 2, "type": "learn", "notes": ["D"]},
            # 3. Learn E
            {"order": 3, "type": "learn", "notes": ["E"]},
            # 4. Identify (Drag & Drop) - Targets C, D, E
            {"order": 4, "type": "identify", "notes": ["C", "D", "E"]},
            # 5. Sight Read C (4 Cs)
            {"order": 5, "type": "read", "notes": ["C", "C", "C", "C"]},
            # 6. Sight Read D
            {"order": 6, "type": "read", "notes": ["D", "D", "D", "D"]},
            # 7. Sight Read E
            {"order": 7, "type": "read", "notes": ["E", "E", "E", "E"]},
        ]

        for seq_data in lesson2_sequences:
            PracticeSequence.objects.create(
                lesson=lesson2,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes']
            )

        self.stdout.write(self.style.SUCCESS(f'Successfully seeded sequences for all lessons.'))
        
        self.stdout.write('')
        self.stdout.write('Summary:')
        self.stdout.write(f'  - Module: {module.title}')
        self.stdout.write(f'  - Lesson 1: {lesson.title} ({len(lesson1_sequences)} seqs)')
        self.stdout.write(f'  - Lesson 2: {lesson2.title} ({len(lesson2_sequences)} seqs)')
