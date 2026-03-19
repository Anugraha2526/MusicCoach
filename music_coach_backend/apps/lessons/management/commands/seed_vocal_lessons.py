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
        module1, _ = Module.objects.update_or_create(
            order=1,
            instrument=vocals_instrument,
            defaults={'title': "Level 1: Practicing La's", 'description': 'Introduction to Vocals'}
        )
        self.stdout.write(f'Ensured Level 1 module: {module1.title}')

        # Create Module 2 (Vocal Level 2)
        module2, _ = Module.objects.update_or_create(
            order=2,
            instrument=vocals_instrument,
            defaults={'title': "Level 2: Practicing Mm's", 'description': 'Vocal Warmups'}
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
        module3, _ = Module.objects.update_or_create(
            order=3, instrument=vocals_instrument,
            defaults={'title': "Level 3: Practicing Oh's", 'description': 'Vocal Exercises'}
        )
        module4, _ = Module.objects.update_or_create(
            order=4, instrument=vocals_instrument,
            defaults={'title': 'Level 4: Silent night', 'description': 'Advanced Vocal Exercises'}
        )
        # Update title if module already exists with old name
        if module4.title != 'Level 4: Silent night':
            module4.title = 'Level 4: Silent night'
            module4.save()
        module5, _ = Module.objects.update_or_create(
            order=5, instrument=vocals_instrument,
            defaults={'title': "Level 5: Singing on 'mum'", 'description': 'Vocal Mastery'}
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

        # Create Lesson 2 for Level 4: Soprano Part - Learn it solo (Silent Night)
        lesson4_2, created = Lesson.objects.get_or_create(
            module=module4,
            order=2,
            defaults={'title': "Soprano Part: Learn it solo", 'lesson_type': 'practice'}
        )
        if not created:
            lesson4_2.title = "Soprano Part: Learn it solo"
            lesson4_2.save()
            deleted_count = lesson4_2.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 4 Lesson 2')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson4_2.title}'))

        # Silent Night soprano melody in half-beat resolution (3/4 time)
        # Each beat = 2 half-beats, each bar = 6 half-beats, 26 bars
        # '-' = rest, '=' = hold/sustain previous note
        silent_night_notes = [
            # Bars 1-2: Lead-in rests (2 bars × 6 half-beats)
            '-', '-', '-', '-', '-', '-',
            '-', '-', '-', '-', '-', '-',
            # Bar 3: G3 dotted, A3 passing, G3 quarter ("Si-lent")
            'G3', '=', '=', 'A3', 'G3', '=',
            # Bar 4: E3 held 3 beats ("night")
            'E3', '=', '=', '=', '=', '=',
            # Bar 5: G3 dotted, A3 passing, G3 quarter ("Ho-ly")
            'G3', '=', '=', 'A3', 'G3', '=',
            # Bar 6: E3 held 3 beats ("night")
            'E3', '=', '=', '=', '=', '=',
            # Bar 7: D4 held 2 beats, D4 restrike ("All is")
            'D4', '=', '=', '=', 'D4', '=',
            # Bar 8: B3 held 3 beats ("calm")
            'B3', '=', '=', '=', '=', '=',
            # Bar 9: C4 held 2 beats, C4 new ("All is")
            'C4', '=', '=', '=', 'C4', '=',
            # Bar 10: G3 held 3 beats ("bright")
            'G3', '=', '=', '=', '=', '=',
            # Bar 11: A3 held 3 beats ("Round yon")
            'A3', '=', '=', '=', '=', '=',
            # Bar 12: C4 dotted, B3 passing, A3 quarter ("vir-gin")
            'C4', '=', '=', 'B3', 'A3', '=',
            # Bar 13: G3 dotted, A3 passing, G3 quarter ("mo-ther and")
            'G3', '=', '=', 'A3', 'G3', '=',
            # Bar 14: E3 held 3 beats ("child")
            'E3', '=', '=', '=', '=', '=',
            # Bar 15: A3 held 3 beats ("Ho-ly")
            'A3', '=', '=', '=', 'A3', '=',
            # Bar 16: C4 dotted, B3 passing, A3 quarter ("in-fant so")
            'C4', '=', '=', 'B3', 'A3', '=',
            # Bar 17: G3 dotted, A3 passing, G3 quarter ("ten-der and")
            'G3', '=', '=', 'A3', 'G3', '=',
            # Bar 18: E3 held 3 beats ("mild")
            'E3', '=', '=', '=', '=', '=',
            # Bar 19: D4 held 2 beats, D4 restrike ("Sleep in")
            'D4', '=', '=', '=', 'D4', '=',
            # Bar 20: F4 dotted, D4 passing, B3 quarter ("hea-ven-ly")
            'F4', '=', '=', 'D4', 'B3', '=',
            # Bar 21: C4 held 3 beats ("peace")
            'C4', '=', '=', '=', '=', '=',
            # Bar 22: E4 held 3 beats
            'E4', '=', '=', '=', '=', '=',
            # Bar 23: C4 quarter, G3 quarter, E3 quarter ("Sleep in")
            'C4', '=', 'G3', '=', 'E3', '=',
            # Bar 24: G3 dotted, E3 passing, D3 quarter ("hea-ven-ly")
            'G3', '=', '=', 'E3', 'D3', '=',
            # Bar 25: C3 held 3 beats ("peace")
            'C3', '=', '=', '=', '=', '=',
            # Bar 26: C3 continued from bar 25
            '=', '=', '=', '=', '=', '=',
        ]

        silent_night_lyrics = [
            # Bars 1-2: Lead-in rests (2 bars × 6 half-beats)
            '', '', '', '', '', '',
            '', '', '', '', '', '',
            # Bars 3-4: G3 dotted, A3 passing, G3 quarter ("Si-lent") + E3 held 3 beats ("night")
            'Silent night', 'Silent night', 'Silent night', 'Silent night', 'Silent night', 'Silent night',
            'Silent night', 'Silent night', 'Silent night', 'Silent night', 'Silent night', 'Silent night',
            # Bars 5-6: G3 dotted, A3 passing, G3 quarter ("Ho-ly") + E3 held 3 beats ("night")
            'Holy night', 'Holy night', 'Holy night', 'Holy night', 'Holy night', 'Holy night',
            'Holy night', 'Holy night', 'Holy night', 'Holy night', 'Holy night', 'Holy night',
            # Bars 7-8: D4 held 2 beats, D4 restrike ("All is") + B3 held 3 beats ("calm")
            'All is calm', 'All is calm', 'All is calm', 'All is calm', 'All is calm', 'All is calm',
            'All is calm', 'All is calm', 'All is calm', 'All is calm', 'All is calm', 'All is calm',
            # Bars 9-10: C4 held 2 beats, D4 new ("All is") + G3 held 3 beats ("bright")
            'All is bright', 'All is bright', 'All is bright', 'All is bright', 'All is bright', 'All is bright',
            'All is bright', 'All is bright', 'All is bright', 'All is bright', 'All is bright', 'All is bright',
            # Bars 11-12: A3 held 3 beats ("Round yon") + C4 dotted, B3 passing, A3 quarter ("vir-gin")
            'Round yon virgin', 'Round yon virgin', 'Round yon virgin', 'Round yon virgin', 'Round yon virgin', 'Round yon virgin',
            'Round yon virgin', 'Round yon virgin', 'Round yon virgin', 'Round yon virgin', 'Round yon virgin', 'Round yon virgin',
            # Bars 13-14: G3 dotted, A3 passing, G3 quarter ("mo-ther and") + E3 held 3 beats ("child")
            'mother and child', 'mother and child', 'mother and child', 'mother and child', 'mother and child', 'mother and child',
            'mother and child', 'mother and child', 'mother and child', 'mother and child', 'mother and child', 'mother and child',
            # Bars 15-16: A3 held 3 beats ("Ho-ly") + C4 dotted, B3 passing, A3 quarter ("in-fant so")
            'Holy infant so', 'Holy infant so', 'Holy infant so', 'Holy infant so', 'Holy infant so', 'Holy infant so',
            'Holy infant so', 'Holy infant so', 'Holy infant so', 'Holy infant so', 'Holy infant so', 'Holy infant so',
            # Bars 17-18: G3 dotted, A3 passing, G3 quarter ("ten-der and") + E3 held 3 beats ("mild")
            'tender and mild', 'tender and mild', 'tender and mild', 'tender and mild', 'tender and mild', 'tender and mild',
            'tender and mild', 'tender and mild', 'tender and mild', 'tender and mild', 'tender and mild', 'tender and mild',
            # Bars 19-22: D4 held 2 beats, D4 restrike ("Sleep in") + F4 dotted, D4 passing, B3 quarter ("hea-ven-ly") + C4 held 3 beats ("peace") + E4 held 3 beats
            'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace',
            'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace',
            'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace',
            'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace',
            # Bars 23-26: C4 quarter, G3 quarter, E3 quarter ("Sleep in") + G3 dotted, E3 passing, D3 quarter ("hea-ven-ly") + C3 held 3 beats ("peace") + C3 continued from bar 25
            'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace',
            'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace',
            'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace',
            'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace', 'Sleep in heavenly peace',
        ]

        PracticeSequence.objects.create(
            lesson=lesson4_2,
            order=1,
            sequence_type='perform',
            notes=silent_night_notes,
            lyrics=silent_night_lyrics,
            time_signature='3/4',
        )
        self.stdout.write(self.style.SUCCESS(
            f'Created Silent Night soprano sequence ({len(silent_night_notes)} half-beats)'
        ))

        # Clean up old locations if it exists
        Lesson.objects.filter(module=module1, order=1, title="Singing on 'mum'").delete()
        Lesson.objects.filter(module=module2, order=1, title="Singing on 'mum'").delete()

        # Create Lesson 3 for Level 4: Alto Part - Learn it solo (Silent Night)
        lesson4_3, created = Lesson.objects.get_or_create(
            module=module4,
            order=3,
            defaults={'title': "Alto Part: Learn it solo", 'lesson_type': 'practice'}
        )
        if not created:
            lesson4_3.title = "Alto Part: Learn it solo"
            lesson4_3.save()
            deleted_count = lesson4_3.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 4 Lesson 3')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson4_3.title}'))

        silent_night_alto_notes = [
            # Bars 1-2: Lead-in rests (2 bars × 6 half-beats)
            '-', '-', '-', '-', '-', '-',
            '-', '-', '-', '-', '-', '-',
            # Bar 3: E3 dotted, F3 passing, E3 quarter
            'E3', '=', '=', 'F3', 'E3', '=',
            # Bar 4: C3 held 3 beats
            'C3', '=', '=', '=', '=', '=',
            # Bar 5: E3 dotted, F3 passing, E3 quarter
            'E3', '=', '=', 'F3', 'E3', '=',
            # Bar 6: C3 held 3 beats
            'C3', '=', '=', '=', '=', '=',
            # Bar 7: B3 held 2 beats, B3 restrike
            'F3', '=', '=', '=', 'F3', '=',
            # Bar 8: G3 held 3 beats
            'F3', '=', '=', '=', '=', '=',
            # Bar 9: G3 held 2 beats, G3 new (Sop is C4 C4 G3, Alto can sing G3 G3 E3)
            'E3', '=', '=', '=', 'E3', '=',
            # Bar 10: E3 held 3 beats
            'E3', '=', '=', '=', '=', '=',
            # Bar 11: F3 held 3 beats
            'F3', '=', '=', '=', 'F3', '=',
            # Bar 12: A3 dotted, G3 passing, F3 quarter
            'A3', '=', '=', 'G3', 'F3', '=',
            # Bar 13: E3 dotted, F3 passing, E3 quarter
            'E3', '=', '=', 'F3', 'E3', '=',
            # Bar 14: C3 held 3 beats
            'C3', '=', '=', '=', '=', '=',
            # Bar 15: F3 held 3 beats
            'C3', '=', '=', '=', 'F3', '=',
            # Bar 16: A3 dotted, G3 passing, F3 quarter
            'A3', '=', '=', 'G3', 'F3', '=',
            # Bar 17: E3 dotted, F3 passing, E3 quarter
            'E3', '=', '=', 'F3', 'E3', '=',
            # Bar 18: C3 held 3 beats
            'C3', '=', '=', '=', '=', '=',
            # Bar 19: B3 held 2 beats, B3 restrike
            'F3', '=', '=', '=', 'F3', '=',
            # Bar 20: D4 dotted, B3 passing, G3 quarter
            'F3', '=', '=', 'F3', 'F3', '=',
            # Bar 21: G3 held 3 beats
            'E3', '=', '=', '=', '=', '=',
            # Bar 22: C4 held 3 beats (Sop is E4)
            'G3', '=', '=', '=', '=', '=',
            # Bar 23: G3 quarter, E3 quarter, C3 quarter
            'E3', '=', '=', '=', 'C3', '=',
            # Bar 24: E3 dotted, C3 passing, B2 quarter
            'B2', '=', '=', 'B2', 'B2', '=',
            # Bar 25: C3 held 3 beats
            'C3', '=', '=', '=', '=', '=',
            # Bar 26: C3 continued from bar 25
            '=', '=', '=', '=', '=', '=',
        ]

        PracticeSequence.objects.create(
            lesson=lesson4_3,
            order=1,
            sequence_type='perform',
            notes=silent_night_alto_notes,
            lyrics=silent_night_lyrics,
            time_signature='3/4',
        )
        self.stdout.write(self.style.SUCCESS(
            f'Created Silent Night alto sequence ({len(silent_night_alto_notes)} half-beats)'
        ))

        # Create Lesson 4 for Level 4: Tenor Part - Learn it solo (Silent Night)
        lesson4_4, created = Lesson.objects.get_or_create(
            module=module4,
            order=4,
            defaults={'title': "Tenor Part: Learn it solo", 'lesson_type': 'practice'}
        )
        if not created:
            lesson4_4.title = "Tenor Part: Learn it solo"
            lesson4_4.save()
            deleted_count = lesson4_4.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 4 Lesson 4')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson4_4.title}'))

        silent_night_tenor_notes = [
            '-', '-', '-', '-', '-', '-',
            '-', '-', '-', '-', '-', '-',
            'C3', '=', '=', '=', 'C3', '=',
            'G2', '=', '=', '=', '=', '=',
            'C3', '=', '=', '=', 'C3', '=',
            'G2', '=', '=', '=', '=', '=',
            'B2', '=', '=', '=', 'B2', '=',
            'D3', '=', '=', '=', '=', '=',
            'C3', '=', '=', '=', 'G2', '=',
            'C3', '=', '=', '=', '=', '=',
            'C3', '=', '=', '=', 'C3', '=',
            'A2', '=', '=', 'B2', 'C3', '=',
            'C3', '=', '=', 'C3', 'C3', '=',
            'G2', '=', '=', '=', '=', '=',
            'F3', '=', '=', '=', 'F3', '=',
            'F3', '=', '=', 'F3', 'F3', '=',
            'C3', '=', '=', '=', 'C3', '=',
            'C3', '=', '=', '=', '=', '=',
            'B2', '=', '=', '=', 'B2', '=',
            'D3', '=', '=', 'B2', 'G2', '=',
            'G2', '=', '=', '=', '=', '=',
            'C3', '=', '=', '=', '=', '=',
            'G2', '=', '=', '=', 'G2', '=',
            'G2', '=', '=', 'G2', 'F2', '=',
            'E2', '=', '=', '=', '=', '=',
            'E2', '=', '=', '=', '=', '=',
        ]

        PracticeSequence.objects.create(
            lesson=lesson4_4,
            order=1,
            sequence_type='perform',
            notes=silent_night_tenor_notes,
            lyrics=silent_night_lyrics,
            time_signature='3/4',
        )
        self.stdout.write(self.style.SUCCESS(
            f'Created Silent Night tenor sequence ({len(silent_night_tenor_notes)} half-beats)'
        ))

        # Create Lesson 5 for Level 4: Bass Part - Learn it solo (Silent Night)
        lesson4_5, created = Lesson.objects.get_or_create(
            module=module4,
            order=5,
            defaults={'title': "Bass Part: Learn it solo", 'lesson_type': 'practice'}
        )
        if not created:
            lesson4_5.title = "Bass Part: Learn it solo"
            lesson4_5.save()
            deleted_count = lesson4_5.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 4 Lesson 5')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson4_5.title}'))

        silent_night_bass_notes = [
            '-', '-', '-', '-', '-', '-',
            '-', '-', '-', '-', '-', '-',
            'C3', '=', '=', '=', 'C3', '=',
            'C3', '=', '=', '=', '=', '=',
            'C3', '=', '=', 'C3', 'C3', '=',
            'C3', '=', '=', '=', '=', '=',
            'G3', '=', '=', '=', 'G3', '=',
            'G3', '=', '=', '=', '=', '=',
            'C3', '=', '=', '=', 'C3', '=',
            'C3', '=', '=', '=', '=', '=',
            'F3', '=', '=', '=', 'F3', '=',
            'F3', '=', '=', 'F3', 'F3', '=',
            'C3', '=', '=', 'C3', 'C3', '=',
            'C3', '=', '=', '=', '=', '=',
            'A3', '=', '=', '=', 'C4', '=',
            'A3', '=', '=', 'B3', 'C4', '=',
            'C4', '=', '=', 'C4', 'C4', '=',
            'G3', '=', '=', '=', '=', '=',
            'G3', '=', '=', '=', 'G3', '=',
            'G3', '=', '=', 'G3', 'G3', '=',
            'C3', '=', '=', '=', '=', '=',
            'C3', '=', '=', '=', '=', '=',
            'G3', '=', '=', '=', 'G3', '=',
            'G2', '=', '=', 'G2', 'G2', '=',
            'C3', '=', '=', '=', '=', '=',
            '=', '=', '=', '=', '=', '=',
        ]

        PracticeSequence.objects.create(
            lesson=lesson4_5,
            order=1,
            sequence_type='perform',
            notes=silent_night_bass_notes,
            lyrics=silent_night_lyrics,
            time_signature='3/4',
        )
        self.stdout.write(self.style.SUCCESS(
            f'Created Silent Night bass sequence ({len(silent_night_bass_notes)} half-beats)'
        ))

        # Create Lesson 1 for Level 5: Singing on "mum" (g,e,g,e,g,f,e,d,c pattern)
        lesson5_1, created = Lesson.objects.get_or_create(
            module=module5,
            order=1,
            defaults={'title': "Singing on 'mum'", 'lesson_type': 'practice'}
        )
        if not created:
            lesson5_1.title = "Singing on 'mum'"
            lesson5_1.save()
            deleted_count = lesson5_1.sequences.all().delete()[0]
            self.stdout.write(f'Cleared {deleted_count} old sequence(s) from Level 5 Lesson 1')
        else:
            self.stdout.write(self.style.SUCCESS(f'Created lesson: {lesson5_1.title}'))

        self.stdout.write(self.style.SUCCESS(
            "\nSuccessfully seeded vocal lessons.\n"
            "Note: sequences are generated dynamically on the frontend "
            "based on each user's natural pitch."
        ))

