import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'musiccoach_api.settings')
django.setup()

import json
from apps.lessons.models import Module, Lesson, PracticeSequence
from django.db import transaction

# Translate midi to note name (matching Flutter's _midiToNoteName)
CHROMATIC_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
def midi_to_note_name(midi):
    note_index = midi % 12
    octave = (midi // 12) - 1
    return f"{CHROMATIC_NAMES[note_index]}{octave}"

def generate_vocal_notes(start_midi, lesson_title, target_level):
    scale_intervals = [0, 2, 4, 5, 7, 9, 11, 12]
    basic_pattern = [0, 1, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3, 2, 1, 0]
    
    all_notes = []
    l_title = lesson_title.lower()
    
    is_swifter = 'swifter' in l_title
    is_pacing_up = 'pacing up' in l_title
    is_lesson4 = 'double' in l_title
    is_chug_along = 'chug' in l_title
    is_l2l1 = 'wave' in l_title or '12321' in l_title
    is_l2l2 = 'further' in l_title or '123454321' in l_title
    is_l2l3 = 'jumps' in l_title or '15151' in l_title
    is_l2l4 = 'ascent (12345)' in l_title or '(12345)' in l_title
    is_l2l5 = 'descent (54321)' in l_title or '(54321)' in l_title
    is_mum = 'mum' in l_title
    
    # Lead in
    if is_mum:
        all_notes.extend(['-'] * 4)
    else:
        all_notes.extend(['-'] * 8)
        
    if is_mum:
        is_level5_mum = target_level == 5
        line_offsets = [0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0]
        if is_level5_mum:
            l5_mum_semitones = [7, 4, 7, 4, 7, 5, 4, 2, 0]
            for line in line_offsets:
                root = start_midi + line
                for p, semitone in enumerate(l5_mum_semitones):
                    midi = root + semitone
                    name = midi_to_note_name(midi)
                    if p < len(l5_mum_semitones) - 1:
                        all_notes.extend([name, '='])
                    else:
                        all_notes.extend([name, '=', '=', '='])
                all_notes.extend(['-', '-', '-', '-'])
        else:
            mum_scale_intervals = [0, 2, 4, 5, 7]
            mum_pattern = [0, 1, 2, 3, 4, 3, 2, 1, 0]
            for line in line_offsets:
                root = start_midi + line
                for p, p_val in enumerate(mum_pattern):
                    midi = root + mum_scale_intervals[p_val]
                    name = midi_to_note_name(midi)
                    if p < len(mum_pattern) - 1:
                        all_notes.extend([name, '='])
                    else:
                        all_notes.extend([name, '=', '=', '='])
                all_notes.extend(['-', '-', '-', '-'])
                
    elif is_l2l1:
        for g in range(8):
            root_midi = start_midi + scale_intervals[g]
            maj_pattern = [0, 2, 4, 2, 0]
            for offset in maj_pattern:
                midi = root_midi + offset
                all_notes.extend([midi_to_note_name(midi), '='])
            all_notes.extend(['-'] * 6)
            
    elif is_l2l2:
        for g in range(5):
            root_midi = start_midi + scale_intervals[g]
            maj_pattern = [0, 2, 4, 5, 7, 5, 4, 2, 0]
            for offset in maj_pattern:
                midi = root_midi + offset
                all_notes.extend([midi_to_note_name(midi), '='])
            all_notes.extend(['-'] * 6)
            
    elif is_l2l3:
        for g in range(5):
            root_midi = start_midi + scale_intervals[g]
            maj_pattern = [0, 7, 0, 7, 0]
            for offset in maj_pattern:
                midi = root_midi + offset
                all_notes.extend([midi_to_note_name(midi), '='])
            all_notes.extend(['-'] * 6)
            
    elif is_l2l4:
        for g in range(5):
            root_midi = start_midi + scale_intervals[g]
            maj_pattern = [0, 2, 4, 5, 7]
            for offset in maj_pattern:
                midi = root_midi + offset
                all_notes.extend([midi_to_note_name(midi), '='])
            all_notes.extend(['-'] * 6)
            
    elif is_l2l5:
        for g in range(5):
            root_midi = start_midi + scale_intervals[g]
            maj_pattern = [7, 5, 4, 2, 0]
            for offset in maj_pattern:
                midi = root_midi + offset
                all_notes.extend([midi_to_note_name(midi), '='])
            all_notes.extend(['-'] * 6)
            
    elif is_chug_along:
        l5_pattern = [0, 1, 2, 3, 4, 4, 3, 2, 1, 0]
        for p_val in l5_pattern:
            midi = start_midi + scale_intervals[p_val]
            name = midi_to_note_name(midi)
            all_notes.extend([name, '=', '-', '-'])
            all_notes.extend([name, '=', '-', '-'])
            all_notes.extend([name, '=', name, '=', name, '=', '-', '-'])
            
    elif is_lesson4:
        l4_pattern = [0, 1, 2, 3, 4, 4, 3, 2, 1, 0]
        for p_val in l4_pattern:
            midi = start_midi + scale_intervals[p_val]
            name = midi_to_note_name(midi)
            for _ in range(2):
                all_notes.extend([name, '='])
                all_notes.extend(['-', '-'])
                
    else: # Basic pattern (Ascent & Descent, Swifter, Pacing Up)
        for p_val in basic_pattern:
            midi = start_midi + scale_intervals[p_val]
            name = midi_to_note_name(midi)
            if is_pacing_up:
                all_notes.extend([name, '='])
            elif is_swifter:
                all_notes.extend([name, '=', '=', '='])
            else:
                all_notes.extend([name, '=', '=', '=', '=', '=', '='])
                all_notes.append('-')
                
    return all_notes

@transaction.atomic
def run():
    print("Migrating dynamic vocal lessons into database sequences...")
    vocal_modules = Module.objects.filter(instrument__type='vocals')
    count = 0
    
    # C3 is MIDI 48
    START_MIDI = 48
    
    for module in vocal_modules:
        # Determine the target level from the module title (e.g. "Level 1: Practicing La's" -> 1)
        target_level = 1
        if 'Level' in module.title:
            try:
                target_level = int(module.title.split('Level ')[1].split(':')[0])
            except:
                pass
                
        for lesson in module.lessons.all():
            # Only generate sequences if it currently has none
            if lesson.sequences.count() == 0:
                print(f"Generating sequence for {module.title} -> {lesson.title}")
                notes = generate_vocal_notes(START_MIDI, lesson.title, target_level)
                
                PracticeSequence.objects.create(
                    lesson=lesson,
                    sequence_type='perform',
                    order=1,
                    notes=notes,
                    lyrics=None,
                    time_signature='4/4'
                )
                count += 1
                
    print(f"Successfully migrated {count} vocal lessons!")

if __name__ == '__main__':
    run()
