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
from apps.instruments.models import Instrument


class Command(BaseCommand):
    help = 'Seed database with Level 1, Lesson 1 content'

    def handle(self, *args, **options):
        self.stdout.write('Seeding lesson data...')
        
        # Get Piano Instrument
        piano_instrument = Instrument.objects.get(type='piano')

        # Create Module (Level 1)
        module, created = Module.objects.get_or_create(
            order=1,
            instrument=piano_instrument,
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
            instrument=piano_instrument,
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

        # =====================
        # LEVEL 2 - LESSON 3: COLORED NOTATION
        # =====================
        l2_lesson3, created = Lesson.objects.get_or_create(
            module=module2,
            order=3,
            defaults={
                'title': 'Colored Notation',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l2_lesson3.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l2_lesson3.title}')
            l2_lesson3.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l2_lesson3.title}"...')
        
        # Two simple units with colored notation
        l2_lesson3_sequences = [
            {
                "order": 1, 
                "type": "read", 
                "notes": ["E", "D", "C", "D"],
                "time_signature": "4/4"
            },
            {
                "order": 2, 
                "type": "read", 
                "notes": ["E", "E", "D", "C"],
                "time_signature": "4/4"
            },
        ]

        for seq_data in l2_lesson3_sequences:
            PracticeSequence.objects.create(
                lesson=l2_lesson3,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )

        # =====================
        # LEVEL 2 - LESSON 4: REHEARSAL (Work Song - Continuous)
        # =====================
        l2_lesson4, created = Lesson.objects.get_or_create(
            module=module2,
            order=4,
            defaults={
                'title': 'Rehearsal',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l2_lesson4.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l2_lesson4.title}')
            l2_lesson4.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l2_lesson4.title}"...')
        
        # Work Song Sequence (Perform Mode - Continuous Play)
        work_song_notes = [
            "D", "-", "-", "-", 
            "-", "-", "-", "-", 
            "-", "D", "-", "D", 
            "-", "D", "-", "C", 
            "-", "D", "D", "-", 
            "D", "C", "-", "-", 
            "-", "D", "D", "-", 
            "D", "C", "-", "-", 
            "-", "D", "D", "-", 
            "-", "-", "-", "-", 
            "-", "D", "-", "D", 
            "-", "D", "-", "C", 
            "-", "D", "D", "-", 
            "-", "-", "-", "-", 
        ]

        PracticeSequence.objects.create(
            lesson=l2_lesson4,
            order=1,
            sequence_type='perform', 
            notes=work_song_notes,
            time_signature='4/4'
        )

        # =====================
        # LEVEL 2 - LESSON 5: PERFORM WORK SONG (Scored)
        # =====================
        l2_lesson5, created = Lesson.objects.get_or_create(
            module=module2,
            order=5,
            defaults={
                'title': 'Perform Work Song',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l2_lesson5.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l2_lesson5.title}')
            l2_lesson5.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l2_lesson5.title}"...')
        
        PracticeSequence.objects.create(
            lesson=l2_lesson5,
            order=1,
            sequence_type='perform', 
            notes=work_song_notes, # Same notes as lesson 4
            time_signature='4/4'
        )

        # ==========================================
        # MODULE 3: LEVEL 3
        # ==========================================
        module3, created = Module.objects.get_or_create(
            order=3,
            instrument=piano_instrument,
            defaults={
                'title': 'Level 3',
                'description': 'Full Octave - Expand your range across more keys',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created module: {module3.title}'))
        else:
            self.stdout.write(f'Module already exists: {module3.title}')

        # =====================
        # LEVEL 3 - LESSON 1: FULL OCTAVE MEMORIZE (Simon Says)
        # =====================
        l3_lesson1, created = Lesson.objects.get_or_create(
            module=module3,
            order=1,
            defaults={
                'title': 'Memorize the melody',
                'lesson_type': 'theory', 
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l3_lesson1.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l3_lesson1.title}')
            l3_lesson1.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l3_lesson1.title}"...')
        
        l3_lesson1_sequences = [
            {"order": 1, "notes": ["E", "D", "C"]},
            {"order": 2, "notes": ["E", "D", "C", "G"]},
            {"order": 3, "notes": ["E", "D", "C", "G", "F"]},
            {"order": 4, "notes": ["E", "D", "C", "G", "F", "E"]},
        ]

        for seq_data in l3_lesson1_sequences:
            PracticeSequence.objects.create(
                lesson=l3_lesson1,
                order=seq_data['order'],
                sequence_type='listen',
                notes=seq_data['notes']
            )

        # =====================
        # LEVEL 3 - LESSON 2: THE NOTES F AND G
        # =====================
        l3_lesson2, created = Lesson.objects.get_or_create(
            module=module3,
            order=2,
            defaults={
                'title': 'The notes F and G',
                'lesson_type': 'practice', 
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l3_lesson2.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l3_lesson2.title}')
            l3_lesson2.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l3_lesson2.title}"...')
        
        l3_lesson2_sequences = [
            {"order": 1, "type": "learn", "notes": ["F"]},
            {"order": 2, "type": "learn", "notes": ["G"]},
            {"order": 3, "type": "tap",   "notes": ["F", "F", "F", "F"]},
            {"order": 4, "type": "tap",   "notes": ["G", "G", "G", "G"]},
            {"order": 5, "type": "identify", "notes": ["C", "E", "F", "G"]},
            {"order": 6, "type": "identify", "notes": ["C", "D", "F", "G"]},
            {"order": 7, "type": "read",     "notes": ["F", "F", "F", "F"]},
            {"order": 8, "type": "read",     "notes": ["G", "G", "G", "G"]},
            {"order": 9, "type": "place",    "notes": ["F"]},
            {"order": 10, "type": "place",   "notes": ["G"]},
        ]

        for seq_data in l3_lesson2_sequences:
            PracticeSequence.objects.create(
                lesson=l3_lesson2,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes']
            )

        # =====================
        # LEVEL 3 - LESSON 3: PLAY AT YOUR OWN PACE (Three Blind Mice)
        # =====================
        l3_lesson3, created = Lesson.objects.get_or_create(
            module=module3,
            order=3,
            defaults={
                'title': "Three Blind Mice",
                'lesson_type': 'practice',
                'description': "Learn to play 'Three Blind Mice' using right hand.",
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l3_lesson3.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l3_lesson3.title}')
            l3_lesson3.title = "Three Blind Mice"
            l3_lesson3.save()
            l3_lesson3.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l3_lesson3.title}"...')
        
        l3_lesson3_sequences = [
             {
                "order": 1, 
                "type": "play", 
                "notes": [
                    "C", "-", "-", "-", 
                    "-", "-", "-", "-", 
                    "E", "D", "C", "-", 
                    "E", "D", "C", "-", 
                    "G", "F", "E", "-", 
                    "G", "F", "E", "-", 
                    "E", "D", "C", "-", 
                    "E", "D", "C", "-", 
                    "G", "F", "E", "-", 
                    "G", "F", "E", "D", 
                    "C", "-", "-", "-", 
                ],
                "time_signature": "4/4"
            },
        ]

        for seq_data in l3_lesson3_sequences:
            PracticeSequence.objects.create(
                lesson=l3_lesson3,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )

        # =====================
        # LEVEL 3 - LESSON 4: REHEARSAL (Three Blind Mice - Continuous)
        # =====================
        l3_lesson4, created = Lesson.objects.get_or_create(
            module=module3,
            order=4,
            defaults={
                'title': 'Rehearsal',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l3_lesson4.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l3_lesson4.title}')
            l3_lesson4.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l3_lesson4.title}"...')
        
        # Three Blind Mice Sequence
        three_blind_mice_notes = [
            "C", "-", "-", "-", 
            "-", "-", "-", "-", 
            "E", "D", "C", "-", 
            "E", "D", "C", "-", 
            "G", "F", "E", "-", 
            "G", "F", "E", "-", 
            "E", "D", "C", "-", 
            "E", "D", "C", "-", 
            "G", "F", "E", "-", 
            "G", "F", "E", "D", 
            "C", "-", "-", "-", 
        ]

        PracticeSequence.objects.create(
            lesson=l3_lesson4,
            order=1,
            sequence_type='perform', 
            notes=three_blind_mice_notes,
            time_signature='4/4'
        )

        # =====================
        # LEVEL 3 - LESSON 5: PERFORM THREE BLIND MICE (Scored)
        # =====================
        l3_lesson5, created = Lesson.objects.get_or_create(
            module=module3,
            order=5,
            defaults={
                'title': "Perform Three Blind Mice",
                'lesson_type': 'practice',
                'description': "Perform Three blind mice using both hands.",
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l3_lesson5.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l3_lesson5.title}')
            l3_lesson5.title = "Perform Three Blind Mice"
            l3_lesson5.save()
            l3_lesson5.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l3_lesson5.title}"...')
        
        PracticeSequence.objects.create(
            lesson=l3_lesson5,
            order=1,
            sequence_type='perform', 
            notes=three_blind_mice_notes,
            time_signature='4/4'
        )

        # ==========================================
        # MODULE 4: LEVEL 4
        # ==========================================
        module4, created = Module.objects.get_or_create(
            order=4,
            instrument=piano_instrument,
            defaults={
                'title': 'Level 4',
                'description': 'Advanced Melodies - Master complex sequences',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created module: {module4.title}'))
        else:
            self.stdout.write(f'Module already exists: {module4.title}')

        # =====================
        # LEVEL 4 - LESSON 1: MEMORIZE (Simon Says)
        # =====================
        l4_lesson1, created = Lesson.objects.get_or_create(
            module=module4,
            order=1,
            defaults={
                'title': 'Memorize the melody',
                'lesson_type': 'theory', 
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l4_lesson1.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l4_lesson1.title}')
            l4_lesson1.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l4_lesson1.title}"...')
        
        l4_lesson1_sequences = [
            {"order": 1, "notes": ["E", "C", "D", "D"]},
            {"order": 2, "notes": ["E", "C", "D", "D", "E"]},
            {"order": 3, "notes": ["E", "C", "D", "D", "E", "C"]},
            {"order": 4, "notes": ["E", "C", "D", "D", "E", "C", "D"]},
            {"order": 5, "notes": ["E", "C", "D", "D", "E", "C", "D", "D"]},
        ]

        for seq_data in l4_lesson1_sequences:
            PracticeSequence.objects.create(
                lesson=l4_lesson1,
                order=seq_data['order'],
                sequence_type='listen',
                notes=seq_data['notes']
            )

        # =====================
        # LEVEL 4 - LESSON 2: PLAY AT YOUR OWN PACE (Cyanics)
        # =====================
        l4_lesson2, created = Lesson.objects.get_or_create(
            module=module4,
            order=2,
            defaults={
                'title': 'Play at your own pace',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l4_lesson2.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l4_lesson2.title}')
            l4_lesson2.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l4_lesson2.title}"...')
        
        l4_lesson2_sequences = [
             {
                "order": 1, 
                "type": "play", 
                "notes": [
                    "C", "-", "-", "-", 
                    "E", "C", "D;D", "-", 
                    "E", "C", "D;D", "-", 
                    "D;D", "D;D", "D", "-", 
                    "D;D", "D;D", "D", "-", 
                    "E", "C", "D;D", "-", 
                    "-", "-", "-", "-", 
                    "E", "C", "D", "-", 
                    "C", "-", "-", "-", 
                ],
                "time_signature": "4/4"
            },
        ]

        for seq_data in l4_lesson2_sequences:
            PracticeSequence.objects.create(
                lesson=l4_lesson2,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )

        # =====================
        # LEVEL 4 - LESSON 3: PRACTICE NOTES (Colored Notation)
        # =====================
        l4_lesson3, created = Lesson.objects.get_or_create(
            module=module4,
            order=3,
            defaults={
                'title': 'Practice Notes',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l4_lesson3.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l4_lesson3.title}')
            l4_lesson3.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l4_lesson3.title}"...')
        
        # Two simple units with colored notation
        l4_lesson3_sequences = [
            {
                "order": 1, 
                "type": "read", 
                "notes": ["F", "F", "G", "G"],
                "time_signature": "4/4"
            },
            {
                "order": 2, 
                "type": "read", 
                "notes": ["G", "F", "E", "E"],
                "time_signature": "4/4"
            },
        ]

        for seq_data in l4_lesson3_sequences:
            PracticeSequence.objects.create(
                lesson=l4_lesson3,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )

        # =====================
        # LEVEL 4 - LESSON 4: REHEARSAL (Cyanide - Continuous)
        # =====================
        l4_lesson4, created = Lesson.objects.get_or_create(
            module=module4,
            order=4,
            defaults={
                'title': 'Rehearsal',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l4_lesson4.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l4_lesson4.title}')
            l4_lesson4.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l4_lesson4.title}"...')
        
        # Cyanide Sequence (Perform Mode - Continuous Play)
        cyanide_notes = [
            "C", "-", "-", "-", 
            "E", "C", "D;D", "-", 
            "E", "C", "D;D", "-", 
            "D;D", "D;D", "D", "-", 
            "D;D", "D;D", "D", "-", 
            "E", "C", "D;D", "-", 
            "-", "-", "-", "-", 
            "E", "C", "D", "-", 
            "C", "-", "-", "-", 
        ]

        PracticeSequence.objects.create(
            lesson=l4_lesson4,
            order=1,
            sequence_type='perform', 
            notes=cyanide_notes,
            time_signature='4/4'
        )

        # =====================
        # LEVEL 4 - LESSON 5: PERFORM CYANIDE (Scored)
        # =====================
        l4_lesson5, created = Lesson.objects.get_or_create(
            module=module4,
            order=5,
            defaults={
                'title': 'Perform Cyanide',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l4_lesson5.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l4_lesson5.title}')
            l4_lesson5.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l4_lesson5.title}"...')
        
        PracticeSequence.objects.create(
            lesson=l4_lesson5,
            order=1,
            sequence_type='perform', 
            notes=cyanide_notes,
            time_signature='4/4'
        )

        # ==========================================
        # MODULE 5: LEVEL 5
        # ==========================================
        module5, created = Module.objects.get_or_create(
            order=5,
            defaults={
                'title': 'Level 5',
                'description': 'Advanced Memory - Build your recall skills further',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created module: {module5.title}'))
        else:
            self.stdout.write(f'Module already exists: {module5.title}')

        # =====================
        # LEVEL 5 - LESSON 1: MEMORIZE (Simon Says)
        # =====================
        l5_lesson1, created = Lesson.objects.get_or_create(
            module=module5,
            order=1,
            defaults={
                'title': 'Memorize the melody',
                'lesson_type': 'theory', 
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l5_lesson1.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l5_lesson1.title}')
            l5_lesson1.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l5_lesson1.title}"...')
        
        l5_lesson1_sequences = [
            {"order": 1, "notes": ["F", "F", "F"]},
            {"order": 2, "notes": ["F", "F", "F", "C"]},
            {"order": 3, "notes": ["F", "F", "F", "C", "D"]},
            {"order": 4, "notes": ["F", "F", "F", "C", "D", "D"]},
            {"order": 5, "notes": ["F", "F", "F", "C", "D", "D", "C"]},
        ]

        for seq_data in l5_lesson1_sequences:
            PracticeSequence.objects.create(
                lesson=l5_lesson1,
                order=seq_data['order'],
                sequence_type='listen',
                notes=seq_data['notes']
            )

        # =====================
        # LEVEL 5 - LESSON 2: PRACTICE NOTES
        # =====================
        l5_lesson2, created = Lesson.objects.get_or_create(
            module=module5,
            order=2,
            defaults={
                'title': 'Practice Notes',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l5_lesson2.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l5_lesson2.title}')
            l5_lesson2.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l5_lesson2.title}"...')
        
        l5_lesson2_sequences = [
            # 1. Read (Colored Notation)
            {"order": 1, "type": "read", "notes": ["D", "G", "G", "G"], "time_signature": "4/4"},
            # 2. Read (Colored Notation)
            {"order": 2, "type": "read", "notes": ["F", "E", "E", "D"], "time_signature": "4/4"},
            # 3. Place (Drag note to notation line)
            {"order": 3, "type": "place", "notes": ["C"]},
            # 4. Place (Drag note to notation line)
            {"order": 4, "type": "place", "notes": ["G"]},
            # 5. Identify (Drag circle to correct key)
            {"order": 5, "type": "identify", "notes": ["C", "D", "F", "G"]},
            # 6. Identify (Drag circle to correct key)
            {"order": 6, "type": "identify", "notes": ["C", "D", "E", "F"]},
        ]

        for seq_data in l5_lesson2_sequences:
            PracticeSequence.objects.create(
                lesson=l5_lesson2,
                order=seq_data['order'],
                sequence_type=seq_data['type'],
                notes=seq_data['notes'],
                time_signature=seq_data.get('time_signature', '4/4')
            )

        # =====================
        # LEVEL 5 - LESSON 3: PLAY AT YOUR OWN PACE (Old MacDonald)
        # =====================
        l5_lesson3, created = Lesson.objects.get_or_create(
            module=module5,
            order=3,
            defaults={
                'title': 'Play at your own pace',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l5_lesson3.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l5_lesson3.title}')
            l5_lesson3.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l5_lesson3.title}"...')
        
        old_macdonald_notes = [
            # Line 1-2
            "F", "-", "-", "-", 
            "-", "-", "-", "-", 
            # Line 3-4
            "F", "F", "F", "C", 
            "D", "D", "C", "_", 
            # Line 5-6
            "A", "A", "G", "G", 
            "F", "_", "-", "C", 
            # Line 7-8
            "F", "F", "F", "C", 
            "D", "D", "C", "_", 
            # Line 9-10
            "A", "A", "G", "G", 
            "F", "_", "-", "-", 
            # Line 11-12
            "F", "F", "F", "-", 
            "F", "F", "F", "-", 
            # Line 13-14
            "F", "-", "F", "-", 
            "F", "F", "F", "C", 
            # Line 15-16
            "F", "F", "F", "C", 
            "D", "D", "C", "_", 
            # Line 17-18
            "A", "A", "G", "G", 
            "F", "_", "-", "-", 
        ]

        PracticeSequence.objects.create(
            lesson=l5_lesson3,
            order=1,
            sequence_type='play', 
            notes=old_macdonald_notes,
            time_signature='4/4'
        )

        # =====================
        # LEVEL 5 - LESSON 4: REHEARSAL (Old MacDonald - Continuous)
        # =====================
        l5_lesson4, created = Lesson.objects.get_or_create(
            module=module5,
            order=4,
            defaults={
                'title': 'Rehearsal',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l5_lesson4.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l5_lesson4.title}')
            l5_lesson4.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l5_lesson4.title}"...')
        
        PracticeSequence.objects.create(
            lesson=l5_lesson4,
            order=1,
            sequence_type='perform', 
            notes=old_macdonald_notes,
            time_signature='4/4'
        )

        # =====================
        # LEVEL 5 - LESSON 5: PERFORM OLD MACDONALD (Scored)
        # =====================
        l5_lesson5, created = Lesson.objects.get_or_create(
            module=module5,
            order=5,
            defaults={
                'title': 'Perform Old MacDonald',
                'lesson_type': 'practice',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {l5_lesson5.title}'))
        else:
            self.stdout.write(f'Lesson already exists: {l5_lesson5.title}')
            l5_lesson5.sequences.all().delete()

        self.stdout.write(f'Seeding sequences for "{l5_lesson5.title}"...')
        
        PracticeSequence.objects.create(
            lesson=l5_lesson5,
            order=1,
            sequence_type='perform', 
            notes=old_macdonald_notes,
            time_signature='4/4'
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
        self.stdout.write(f'    - Lesson 2: {l2_lesson2.title} ({len(l2_lesson2_sequences)} seq)')
        self.stdout.write(f'    - Lesson 3: {l2_lesson3.title} ({len(l2_lesson3_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 4: {l2_lesson4.title}')
        self.stdout.write(f'    - Lesson 5: {l2_lesson5.title}')
        self.stdout.write(f'  - Module 3: {module3.title}')
        self.stdout.write(f'    - Lesson 1: {l3_lesson1.title} ({len(l3_lesson1_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 2: {l3_lesson2.title} ({len(l3_lesson2_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 3: {l3_lesson3.title} ({len(l3_lesson3_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 4: {l3_lesson4.title}')
        self.stdout.write(f'    - Lesson 5: {l3_lesson5.title}')
        self.stdout.write(f'  - Module 4: {module4.title}')
        self.stdout.write(f'    - Lesson 1: {l4_lesson1.title} ({len(l4_lesson1_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 2: {l4_lesson2.title} ({len(l4_lesson2_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 3: {l4_lesson3.title} ({len(l4_lesson3_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 4: {l4_lesson4.title}')
        self.stdout.write(f'    - Lesson 5: {l4_lesson5.title}')
        self.stdout.write(f'  - Module 5: {module5.title}')
        self.stdout.write(f'    - Lesson 1: {l5_lesson1.title} ({len(l5_lesson1_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 2: {l5_lesson2.title} ({len(l5_lesson2_sequences)} seqs)')
        self.stdout.write(f'    - Lesson 3: {l5_lesson3.title} (1 seqs)')
        self.stdout.write(f'    - Lesson 4: {l5_lesson4.title}')
        self.stdout.write(f'    - Lesson 5: {l5_lesson5.title}')

