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

        # =====================
        # LESSON 3: PLAY AT YOUR OWN PACE (Hot Cross Buns)
        # =====================
        lesson3, created = Lesson.objects.get_or_create(
            module=module,
            order=3,
            defaults={
                'title': 'Play at your own pace',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson3.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {lesson3.title}')
            # Clear existing data
            lesson3.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{lesson3.title}"...')
        
        # Hot Cross Buns notation:
        # E (1 beat), empty bar, EDC-, EDC-, CCDD, EDC-, EDC-, EDC-, CCDD, EDC-
        # Using "-" for rests/holds, they won't be shown in UI but create spacing
        lesson3_sequences = [
            {
                "order": 1, 
                "type": "play", 
                "notes": [
                    "E", "-", "-", "-",  # E held for 1 bar
                    # Empty bar removed
                    "E", "D", "C", "-",  # EDC-
                    "E", "D", "C", "-",  # EDC-
                    "C", "C", "D", "D",  # CCDD
                    "E", "D", "C", "-",  # EDC-
                    "E", "D", "C", "-",  # EDC-
                    "E", "D", "C", "-",  # EDC-
                    "C", "C", "D", "D",  # CCDD
                    "E", "D", "C", "-",  # EDC-
                ],
                "time_signature": "4/4"
            },
        ]

        for seq_data in lesson3_sequences:
            PracticeSequence.objects.create(
                lesson=lesson3,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )

        # =====================
        # LESSON 4: REHEARSAL (Continuous Play)
        # =====================
        lesson4, created = Lesson.objects.get_or_create(
            module=module,
            order=4,
            defaults={
                'title': 'Rehearsal',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson4.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {lesson4.title}')
            # Clear existing data
            lesson4.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{lesson4.title}"...')
        
        # Exact same notes as Lesson 3 ("Hot Cross Buns"), but sequence_type='perform'
        lesson4_sequences = [
            {
                "order": 1, 
                "type": "perform", 
                "notes": [
                    "E", "-", "-", "-",  # E held for 1 bar
                    "E", "D", "C", "-",  # EDC-
                    "E", "D", "C", "-",  # EDC-
                    "C", "C", "D", "D",  # CCDD
                    "E", "D", "C", "-",  # EDC-
                    "E", "D", "C", "-",  # EDC-
                    "E", "D", "C", "-",  # EDC-
                    "C", "C", "D", "D",  # CCDD
                    "E", "D", "C", "-",  # EDC-
                ],
                "time_signature": "4/4"
            },
        ]

        for seq_data in lesson4_sequences:
            PracticeSequence.objects.create(
                lesson=lesson4,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )

        # =====================
        # LESSON 5: PERFORM HOT CROSS BUNS (Stars & Accuracy)
        # =====================
        lesson5, created = Lesson.objects.get_or_create(
            module=module,
            order=5,
            defaults={
                'title': 'Perform Hot Cross Buns',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson5.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {lesson5.title}')
            # Clear existing data
            lesson5.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{lesson5.title}"...')
        
        # Exact same notes as Lesson 3/4, but title/context is different
        lesson5_sequences = [
            {
                "order": 1, 
                "type": "perform", 
                "notes": [
                    "E", "-", "-", "-", 
                    "E", "D", "C", "-", 
                    "E", "D", "C", "-", 
                    "C", "C", "D", "D", 
                    "E", "D", "C", "-", 
                    "E", "D", "C", "-", 
                    "E", "D", "C", "-", 
                    "C", "C", "D", "D", 
                    "E", "D", "C", "-", 
                ],
                "time_signature": "4/4"
            },
        ]

        for seq_data in lesson5_sequences:
            PracticeSequence.objects.create(
                lesson=lesson5,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )



        # ==========================================
        # MODULE 2: LEVEL 2
        # ==========================================
        module2, created = Module.objects.get_or_create(
            order=2,
            defaults={
                'title': 'Level 2',
                'description': 'Advanced Patterns - Challenge your memory and rhythm',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created module: {module2.title}'))
        else:
            self.stdout.write(f'Module already exists: {module2.title}')

        # =====================
        # LEVEL 2 - LESSON 1: PATTERNS (Simon Says)
        # =====================
        l2_lesson1, created = Lesson.objects.get_or_create(
            module=module2,
            order=1,
            defaults={
                'title': 'Memorize the melody',
                'lesson_type': 'theory', # Reusing 'theory' type implies 'Listen' default in frontend map often, or explicitly sequence type
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l2_lesson1.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l2_lesson1.title}')
            l2_lesson1.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l2_lesson1.title}"...')
        
        l2_lesson1_sequences = [
            {"order": 1, "notes": ["D", "D", "D", "C"]},
            {"order": 2, "notes": ["D", "D", "D", "C", "D"]},
            {"order": 3, "notes": ["D", "D", "D", "C", "D", "D"]},
            {"order": 4, "notes": ["D", "D", "D", "C", "D", "D", "D"]},
            {"order": 5, "notes": ["D", "D", "D", "C", "D", "D", "D", "C"]},
        ]

        for seq_data in l2_lesson1_sequences:
            PracticeSequence.objects.create(
                lesson=l2_lesson1,
                order=seq_data['order'],
                sequence_type='listen', # Explicitly Listen mode 
                notes=seq_data['notes']
            )

        # =====================
        # LEVEL 2 - LESSON 2: PLAY AT YOUR OWN PACE (Work Song - Hozier)
        # =====================
        l2_lesson2, created = Lesson.objects.get_or_create(
            module=module2,
            order=2,
            defaults={
                'title': 'Play at your own pace',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l2_lesson2.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l2_lesson2.title}')
            l2_lesson2.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l2_lesson2.title}"...')
        
        # Work Song Sequence
        # D-- -D-D -D-C -DD- DC-- -DD- DC-- -DD- ---- -D-D -D-C -DD-
        l2_lesson2_sequences = [
             {
                "order": 1, 
                "type": "play", 
                "notes": [
                    # 1. D---
                    "D", "-", "-", "-", 
                    # 2. ----
                    "-", "-", "-", "-", 
                    # 3. -D-C
                    "-", "D", "-", "D", 
                    # 4. -D-C
                    "-", "D", "-", "C", 
                    # 5. -DD-
                    "-", "D", "D", "-", 
                    # 6. DC--
                    "D", "C", "-", "-", 
                    # 7. -DD-
                    "-", "D", "D", "-", 
                    # 8. DC--
                    "D", "C", "-", "-", 
                    # 9. -DD-
                    "-", "D", "D", "-", 
                    # 10. ----
                    "-", "-", "-", "-", 
                    # 11. -D-D
                    "-", "D", "-", "D", 
                    # 12. -D-C
                    "-", "D", "-", "C", 
                    # 13. -DD-
                    "-", "D", "D", "-", 
                    # 14. ----
                    "-", "-", "-", "-", 
                ],
                "time_signature": "4/4"
            },
        ]

        for seq_data in l2_lesson2_sequences:
            PracticeSequence.objects.create(
                lesson=l2_lesson2,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )

        self.stdout.write(self.style.SUCCESS(f'Successfully seeded sequences for all lessons.'))
        
        self.stdout.write('')
        self.stdout.write('Summary:')
        self.stdout.write(f'  - Module 1: {module.title}')
        self.stdout.write(f'    - Lesson 1: {lesson.title}')
        self.stdout.write(f'    - Lesson 2: {lesson2.title}')
        self.stdout.write(f'    - Lesson 3: {lesson3.title}')
        self.stdout.write(f'    - Lesson 4: {lesson4.title}')
        self.stdout.write(f'    - Lesson 5: {lesson5.title}')
        self.stdout.write(f'  - Module 2: {module2.title}')
        self.stdout.write(f'    - Lesson 1: {l2_lesson1.title} ({len(l2_lesson1_sequences)} seqs)')
