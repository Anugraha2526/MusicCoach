"""
Management command to seed Level 2, Lesson 4 (Rehearsal) data.
Sequence: Work Song (Same as Level 2 Lesson 2)
Mode: Perform (Continuous Play)

Run with: python manage.py add_level2_lesson4
"""

from django.core.management.base import BaseCommand
from apps.lessons.models import Module, Lesson, PracticeSequence

class Command(BaseCommand):
    help = 'Seed database with Level 2, Lesson 4 (Rehearsal) content'

    def handle(self, *args, **options):
        self.stdout.write('Seeding Level 2 Lesson 4 data...')

        # 1. basic check for Level 2 Module
        try:
            module2 = Module.objects.get(title='Level 2') 
            # Note: We use title='Level 2' based on seed_lessons.py. 
            # If it was purely by order, we might use order=2, but title is safer if order changed.
        except Module.DoesNotExist:
             self.stdout.write(self.style.ERROR('Module "Level 2" does not exist. Please run seed_lessons first.'))
             return

        self.stdout.write(f'Found Module: {module2.title}')

        # 2. Create Lesson 4: Rehearsal
        lesson4, created = Lesson.objects.get_or_create(
            module=module2,
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
            # Clear existing data to ensure we have the correct sequence
            lesson4.sequences.all().delete()
            self.stdout.write('Cleared existing sequences for lesson.')

        # 3. Create Sequence (Work Song, Perform Mode)
        # Sequence from seed_lessons.py Level 2 Lesson 2
        work_song_notes = [
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
        ]

        PracticeSequence.objects.create(
            lesson=lesson4,
            order=1,
            sequence_type='perform', # KEY DIFFERENCE: perform mode for continuous play
            notes=work_song_notes,
            time_signature='4/4'
        )

        self.stdout.write(self.style.SUCCESS(f'Successfully seeded "Rehearsal" sequence for Level 2 Lesson 4.'))
