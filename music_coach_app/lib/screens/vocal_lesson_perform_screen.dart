import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../models/lesson_models.dart';
import '../services/lesson_service.dart';
import '../services/progress_service.dart';
import '../services/auth_service.dart';

class VocalLessonPerformScreen extends StatefulWidget {
  final int lessonId;
  final String? lessonTitle;
  
  final int? targetLevel;
  final int? targetLessonIndex;
  final List<LessonModule>? allModules;

  const VocalLessonPerformScreen({
    super.key,
    required this.lessonId,
    this.lessonTitle,
    this.targetLevel,
    this.targetLessonIndex,
    this.allModules,
  });

  @override
  State<VocalLessonPerformScreen> createState() => _VocalLessonPerformScreenState();
}

class PitchFrame {
  final double? midi;
  final double timeMs;
  PitchFrame(this.midi, this.timeMs);
}

class _VocalLessonPerformScreenState extends State<VocalLessonPerformScreen> with SingleTickerProviderStateMixin {
  // Note names for MIDI mapping (A# used instead of Bb to match generated notes)
  final List<String> _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  bool _isPlaying = false;
  Timer? _pollingTimer;
  Timer? _songTimer;
  
  final List<PitchFrame> _pitchHistory = []; 
  final int maxPoints = 200;  
  
  final _audioCapture = FlutterAudioCapture();
  // Buffer size 2048 for faster pitch detection (was 4096)
  final _pitchDetector = PitchDetector(audioSampleRate: 44100, bufferSize: 2048);
  bool _micGranted = false;
  
  double? _currentMidiVal;
  double? _smoothedMidiVal;
  
  // Center MIDI for the graph view — updated dynamically from natural pitch
  double _currentCenterMidi = 55.0;

  // Note name lookup table
  static const List<String> _chromaticNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  /// Convert a MIDI number to an octave-qualified note name, e.g. 45 → "A2"
  String _midiToNoteName(int midi) {
    final int noteIndex = midi % 12;
    final int octave = (midi ~/ 12) - 1;
    return '${_chromaticNames[noteIndex]}$octave';
  }

  /// Generate the full note list for vocal lessons.
  /// Same C-to-C major scale pattern, but duration varies by lesson:
  /// - "Ascent & Descent": 3.5 beat notes, 0.5 beat rest between
  /// - "Swifter": 2 beat (half) notes, no rest between
  List<String> _generateVocalNotes(double naturalPitchMidi) {
    final int startMidi = naturalPitchMidi.round();
    // Major-scale intervals: 1, 2, 3, 4, 5, 6, 7, 8 (octave)
    const scaleIntervals = [0, 2, 4, 5, 7, 9, 11, 12];
    const pattern = [0, 1, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3, 2, 1, 0];

    final List<String> allNotes = [];
    final bool isSwifter = widget.lessonTitle?.toLowerCase().contains('swifter') ?? false;
    final bool isPacingUp = widget.lessonTitle?.toLowerCase().contains('pacing up') ?? false;
    final String lTitle = widget.lessonTitle?.toLowerCase() ?? '';
    final bool isLesson4 = lTitle.contains('double');
    final bool isChugAlong = lTitle.contains('chug');
    final bool isL2L1 = lTitle.contains('wave') || lTitle.contains('12321');
    final bool isL2L2 = lTitle.contains('further') || lTitle.contains('123454321');
    final bool isL2L3 = lTitle.contains('jumps') || lTitle.contains('15151');
    final bool isL2L4 = lTitle.contains('ascent (12345)') || lTitle.contains('(12345)');
    final bool isL2L5 = lTitle.contains('descent (54321)') || lTitle.contains('(54321)');
    final bool isMumLesson = lTitle.contains('mum');

    // 4 beats of lead-in rest (8 half-beats since we need 0.5 resolution)
    // Exception: mum lesson uses 2-beat lead-in (4 half-beats)
    if (isMumLesson) {
      allNotes.addAll(List.filled(4, '-'));
    } else {
      allNotes.addAll(List.filled(8, '-'));
    }

    if (isMumLesson) {
      // Level 5 Lesson 1: "Singing on mum"
      // Pattern per line: 1-2-3-4-5-4-3-2-1 using major scale degrees
      // 11 lines shifting by half-steps: up 5 then back down
      const mumScaleIntervals = [0, 2, 4, 5, 7]; // Major scale degrees 1-5
      const mumPattern = [0, 1, 2, 3, 4, 3, 2, 1, 0]; // 1-2-3-4-5-4-3-2-1
      const lineOffsets = [0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0]; // 11 lines

      for (int line = 0; line < lineOffsets.length; line++) {
        final int root = startMidi + lineOffsets[line];
        for (int p = 0; p < mumPattern.length; p++) {
          final int midi = root + mumScaleIntervals[mumPattern[p]];
          final String name = _midiToNoteName(midi);
          if (p < mumPattern.length - 1) {
            // Quarter note = 2 half-beats
            allNotes.addAll([name, '=']);
          } else {
            // Last note — half note = 4 half-beats
            allNotes.addAll([name, '=', '=', '=']);
          }
        }
        // 2-beat rest gap = 4 half-beats
        allNotes.addAll(['-', '-', '-', '-']);
      }
    } else if (isL2L1) {
      // Level 2 Lesson 1: 12321 wave pattern stepping up the scale
      // Groups: start at degree 0,1,2,3... up to 7 (octave jump)
      // Each group uses a MAJOR 12321 shape relative to the root note
      for (int g = 0; g <= 7; g++) {
        final int rootMidi = startMidi + scaleIntervals[g];
        final majPattern = [0, 2, 4, 2, 0]; // Major scale 1-2-3-2-1 semitones
        for (int semitoneOffset in majPattern) {
          final int midi = rootMidi + semitoneOffset;
          final String name = _midiToNoteName(midi);
          // Quarter note = 2 half-beats
          allNotes.addAll([name, '=']);
        }
        // 3 quarter-beat gaps = 6 half-beats
        allNotes.addAll(List.filled(6, '-'));
      }
    } else if (isL2L2) {
      // Level 2 Lesson 2: 123454321 pattern stepping up the scale, up to the 5th scale degree (g=4)
      for (int g = 0; g <= 4; g++) {
        final int rootMidi = startMidi + scaleIntervals[g];
        final majPattern = [0, 2, 4, 5, 7, 5, 4, 2, 0]; // Major scale 1-2-3-4-5-4-3-2-1 semitones
        for (int semitoneOffset in majPattern) {
          final int midi = rootMidi + semitoneOffset;
          final String name = _midiToNoteName(midi);
          // Quarter note = 2 half-beats
          allNotes.addAll([name, '=']);
        }
        // 3 quarter-beat gaps = 6 half-beats
        allNotes.addAll(List.filled(6, '-'));
      }
    } else if (isL2L3) {
      // Level 2 Lesson 3: 15151 jump pattern stepping up the scale, up to the 5th scale degree (g=4)
      for (int g = 0; g <= 4; g++) {
        final int rootMidi = startMidi + scaleIntervals[g];
        final majPattern = [0, 7, 0, 7, 0]; // Major scale 1st and 5th (+7 semitones)
        for (int semitoneOffset in majPattern) {
          final int midi = rootMidi + semitoneOffset;
          final String name = _midiToNoteName(midi);
          // Quarter note = 2 half-beats
          allNotes.addAll([name, '=']);
        }
        // 3 quarter-beat gaps = 6 half-beats
        allNotes.addAll(List.filled(6, '-'));
      }
    } else if (isL2L4) {
      // Level 2 Lesson 4: 12345 ascent pattern stepping up the scale, up to the 5th scale degree (g=4)
      for (int g = 0; g <= 4; g++) {
        final int rootMidi = startMidi + scaleIntervals[g];
        final majPattern = [0, 2, 4, 5, 7]; // Major scale 1-2-3-4-5 semitones
        for (int semitoneOffset in majPattern) {
          final int midi = rootMidi + semitoneOffset;
          final String name = _midiToNoteName(midi);
          // Quarter note = 2 half-beats
          allNotes.addAll([name, '=']);
        }
        // 3 quarter-beat gaps = 6 half-beats
        allNotes.addAll(List.filled(6, '-'));
      }
    } else if (isL2L5) {
      // Level 2 Lesson 5: 54321 descent pattern stepping up the scale, up to the 5th scale degree (g=4)
      for (int g = 0; g <= 4; g++) {
        final int rootMidi = startMidi + scaleIntervals[g];
        final majPattern = [7, 5, 4, 2, 0]; // Major scale 5-4-3-2-1 semitones
        for (int semitoneOffset in majPattern) {
          final int midi = rootMidi + semitoneOffset;
          final String name = _midiToNoteName(midi);
          // Quarter note = 2 half-beats
          allNotes.addAll([name, '=']);
        }
        // 3 quarter-beat gaps = 6 half-beats
        allNotes.addAll(List.filled(6, '-'));
      }
    } else if (isChugAlong) {
      // Lesson 5: note, gap, note, gap, note, note, note, gap — up to 5th and back
      const l5Pattern = [0, 1, 2, 3, 4, 4, 3, 2, 1, 0];
      for (int p = 0; p < l5Pattern.length; p++) {
        final int midi = startMidi + scaleIntervals[l5Pattern[p]];
        final String name = _midiToNoteName(midi);
        // note, gap, note, gap, note, note, note, gap
        // note = quarter (2 half-beats), gap = quarter (2 half-beats)
        allNotes.addAll([name, '=', '-', '-']); // note, gap
        allNotes.addAll([name, '=', '-', '-']); // note, gap
        allNotes.addAll([name, '=', name, '=', name, '=', '-', '-']); // note, note, note, gap
      }
    } else if (isLesson4) {
      // Lesson 4: quarter note, gap, quarter note, gap — up to 5th degree and back
      // Only use first 5 scale degrees: [0, 2, 4, 5, 7]
      const l4Pattern = [0, 1, 2, 3, 4, 4, 3, 2, 1, 0];
      for (int p = 0; p < l4Pattern.length; p++) {
        final int midi = startMidi + scaleIntervals[l4Pattern[p]];
        final String name = _midiToNoteName(midi);
        // Play note twice: note, gap, note, gap
        for (int rep = 0; rep < 2; rep++) {
          // Quarter note = 2 half-beats
          allNotes.add(name);
          allNotes.add('=');
          // Quarter rest gap = 2 half-beats
          allNotes.addAll(['-', '-']);
        }
      }
    } else {
      for (int p = 0; p < pattern.length; p++) {
        final int midi = startMidi + scaleIntervals[pattern[p]];
        final String name = _midiToNoteName(midi);
        
        if (isPacingUp) {
          // Quarter note = 1 beat = 2 half-beats (1 initial + 1 hold), no rest
          allNotes.add(name);
          allNotes.addAll(List.filled(1, '='));
        } else if (isSwifter) {
          // Half note = 2 beats = 4 half-beats (1 initial + 3 holds), no rest
          allNotes.add(name);
          allNotes.addAll(List.filled(3, '='));
        } else {
          // 3.5 beats note = 7 half-beats (1 initial + 6 holds)
          allNotes.add(name);
          allNotes.addAll(List.filled(6, '='));
          // 0.5 beat rest = 1 half-beat
          allNotes.add('-');
        }
      }
    }

    return allNotes;
  }

  /// Build a map of half-beat-index → chord/guide notes to play.
  Map<int, List<String>> _buildChordMap(double naturalPitchMidi) {
    final int startMidi = naturalPitchMidi.round();
    // Root major chord: 1, 3, 5
    const chordIntervals = [0, 4, 7]; 
    const scaleIntervals = [0, 2, 4, 5, 7, 9, 11, 12];
    final Map<int, List<String>> playMap = {};
    final String lTitle = widget.lessonTitle?.toLowerCase() ?? '';
    final bool isL2L1 = lTitle.contains('wave') || lTitle.contains('12321');
    final bool isL2L2 = lTitle.contains('further') || lTitle.contains('123454321');
    final bool isL2L3 = lTitle.contains('jumps') || lTitle.contains('15151');
    final bool isL2L4 = lTitle.contains('ascent (12345)') || lTitle.contains('(12345)');
    final bool isL2L5 = lTitle.contains('descent (54321)') || lTitle.contains('(54321)');
    final bool isMumLesson = lTitle.contains('mum');

    if (isMumLesson) {
      // Mum lesson: chord intervals [0, 5, 9] (scale degrees 1, 4, 6)
      const mumChordIntervals = [0, 5, 9];
      const lineOffsets = [0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0];

      // Lead-in chord (beat 0)
      playMap[0] = mumChordIntervals.map((i) => _midiToNoteName(startMidi + lineOffsets[0] + i)).toList();

      // Each line = 8 quarter notes (16 half-beats) + 1 half note (4 half-beats) + 2-beat rest (4 half-beats) = 24 half-beats
      for (int line = 0; line < lineOffsets.length; line++) {
        final int lineStart = 4 + line * 24; // 4 half-beat lead-in + line * 24
        final int restStart = lineStart + 20; // 8 quarters (16) + half note (4) = 20 half-beats into the line
        final int nextOffset = line < lineOffsets.length - 1 ? lineOffsets[line + 1] : lineOffsets[line];
        playMap[restStart] = mumChordIntervals.map((i) => _midiToNoteName(startMidi + nextOffset + i)).toList();
      }
    } else {
      // Lead-in rest (beat 0): play full root chord
      playMap[0] = chordIntervals.map((i) => _midiToNoteName(startMidi + i)).toList();

      // On the 3rd beat of the 4-beat lead-in (half-beat index 4)
      // Play the starting root note so the user can hear it before singing
      playMap[4] = [_midiToNoteName(startMidi)];

      if (isL2L1) {
      // For L2L1: each group = 5 quarter notes (10 half-beats) + 3 gaps (6 half-beats) = 16 half-beats
      // Note: we have 8 groups (g=0 to 7).
      // Chord plays on the 2nd gap beat of each group EXCEPT the last.
      // 2nd gap = offset 12 from group start (10 notes + 2 gap half-beats)
      for (int g = 0; g < 7; g++) { 
        final int groupStart = 8 + g * 16; // 8 lead-in + g * 16 per group
        final int chordBeat = groupStart + 12; // 2nd gap beat
        final int nextRoot = startMidi + scaleIntervals[g + 1];
        playMap[chordBeat] = chordIntervals.map((i) => _midiToNoteName(nextRoot + i)).toList();
      }
    } else if (isL2L2) {
      // For L2L2: each group = 9 notes (18 half-beats) + 3 gaps (6 half-beats) = 24 half-beats
      // We have 5 groups (g=0 to 4).
      // Chord plays on the 2nd gap beat of each group EXCEPT the last.
      // 2nd gap = offset 20 from group start (18 notes + 2 gap half-beats)
      for (int g = 0; g < 4; g++) { 
        final int groupStart = 8 + g * 24; // 8 lead-in + g * 24 per group
        final int chordBeat = groupStart + 20; // 2nd gap beat
        final int nextRoot = startMidi + scaleIntervals[g + 1];
        playMap[chordBeat] = chordIntervals.map((i) => _midiToNoteName(nextRoot + i)).toList();
      }
    } else if (isL2L3 || isL2L4 || isL2L5) {
      // For L2L3, L2L4, L2L5: each group = 5 notes (10 half-beats) + 3 gaps (6 half-beats) = 16 half-beats
      // We have 5 groups (g=0 to 4).
      // Chord plays on the 2nd gap beat of each group EXCEPT the last.
      for (int g = 0; g < 4; g++) { 
        final int groupStart = 8 + g * 16; // 8 lead-in + g * 16 per group
        final int chordBeat = groupStart + 12; // 2nd gap beat
        final int nextRoot = startMidi + scaleIntervals[g + 1];
        playMap[chordBeat] = chordIntervals.map((i) => _midiToNoteName(nextRoot + i)).toList();
      }
      }
    }

    return playMap;
  }

  late AnimationController _repaintController;
  
  // Lesson data
  List<PracticeSequence> sequences = [];
  bool isLoading = true;
  String? errorMessage;
  
  // Game state
  double _songTimeMs = 0.0;
  // 145 BPM => ~414ms per quarter beat. Because we use 0.5 beat arrays,
  // each array element represents an eighth note (1/2 beat) = 207ms.
  final double _beatDurationMs = 207.0;
  int _score = 0;
  int _maxPossibleScore = 0;
  bool _isFinished = false;

  // Chord accompaniment: beat index → list of note names to play
  Map<int, List<String>> _chordBeats = {};

  // Audio playback (SoLoud)
  late SoLoud _soloud;
  final Map<String, AudioSource> _noteSources = {};
  bool _audioInitialized = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _repaintController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))..repeat();

    _initAudio();
    _loadLesson();
    _requestMic();
  }

  Future<void> _initAudio() async {
    try {
      _soloud = SoLoud.instance;
      if (!_soloud.isInitialized) {
        await _soloud.init(
          sampleRate: 44100,
          bufferSize: 2048, // Larger buffer = less underruns/glitches on mobile
        );
      }
      _audioInitialized = true;
    } catch (e) {
      debugPrint('SoLoud init error: $e');
    }
  }


  Future<void> _loadLesson() async {
    try {
      final fetchedSequences = await LessonService.fetchLessonSequences(widget.lessonId);
      final profile = await AuthService.fetchProfile();
      
      if (mounted) {
        // Determine natural pitch MIDI from profile (needed both inside and after setState)
        double? naturalMidi;
        if (profile != null && profile['natural_pitch'] != null) {
            double pitchHz = profile['natural_pitch'] is double 
                ? profile['natural_pitch'] 
                : (profile['natural_pitch'] as num).toDouble();
            if (pitchHz > 0) {
               naturalMidi = 69 + 12 * (math.log(pitchHz / 440.0) / math.ln2);
            }
        }

        setState(() {
          if (fetchedSequences.isNotEmpty) {
            // Use backend sequences as-is
            sequences = fetchedSequences;
          } else if (naturalMidi != null) {
            // No backend sequences → generate dynamically from natural pitch
            final generatedNotes = _generateVocalNotes(naturalMidi);
            sequences = [
              PracticeSequence(
                id: 0,
                order: 1,
                type: 'perform',
                notes: generatedNotes,
                timeSignature: '4/4',
              ),
            ];
          }

          isLoading = false;

          // Count max possible score (number of non-rest beats)
          if (sequences.isNotEmpty) {
            _maxPossibleScore = sequences.first.notes.where((n) => n != '-' && n != '=').length;
          }

          // Center the graph on the middle of the generated range
          if (naturalMidi != null) {
            // Range spans from naturalMidi to naturalMidi+8 (9 lines) + up to 7 semitones
            // Center at naturalMidi + 7 (roughly the middle of the full range)
            _currentCenterMidi = naturalMidi + 7;
          }
        });
        
        // Build chord map and load audio for both melody and chords
        if (sequences.isNotEmpty) {
           // Collect all unique notes from melody + chords
           final allAudioNotes = <String>[...sequences.first.notes];
           if (naturalMidi != null) {
              _chordBeats = _buildChordMap(naturalMidi);
              for (var chordNotes in _chordBeats.values) {
                allAudioNotes.addAll(chordNotes);
              }
           }
           await _ensureAudioLoaded(allAudioNotes);
        }
        await _requestMic();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load lesson: $e';
        });
      }
    }
  }

  /// Convert a sharp note name like "C#4" → "Db4" to match the flat-based mp3 assets.
  String _noteToAssetName(String note) {
    // Sharp → flat enharmonic map (applied to just the letter+accidental part)
    const sharpToFlat = {
      'C#': 'Db',
      'D#': 'Eb',
      'F#': 'Gb',
      'G#': 'Ab',
      'A#': 'Bb',
    };
    for (final entry in sharpToFlat.entries) {
      if (note.startsWith(entry.key)) {
        return entry.value + note.substring(entry.key.length);
      }
    }
    return note; // natural note — no change needed
  }

  Future<void> _ensureAudioLoaded(List<String> userNotes) async {
      if (!_audioInitialized) return;
      // Extract unique notes, ignoring rests
      final uniqueNotes = userNotes.where((n) => n != '-' && n != '=').toSet();
      
      for (var note in uniqueNotes) {
         if (!_noteSources.containsKey(note)) {
            try {
              // Convert sharp notation (C#4) to flat asset name (Db4)
              final assetName = _noteToAssetName(note);
              _noteSources[note] = await _soloud.loadAsset(
                'assets/audio/piano_notes/$assetName.mp3',
                mode: LoadMode.memory,
              );
            } catch (e) {
               debugPrint('Failed to load note audio $note: $e');
            }
         }
      }
  }

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for pitch detection')),
        );
      }
      return;
    }
    if (mounted) setState(() => _micGranted = true);
  }

  Future<void> _startListening() async {
    if (!_micGranted) return;
    try {
      final initialized = await _audioCapture.init();
      if (initialized != true) return;

      await _audioCapture.start(
        _processAudio,
        (error) => debugPrint('Audio Capture Error: $error'),
        sampleRate: 44100,
        bufferSize: 4096,
      );
    } catch (e) {
      debugPrint('Error starting audio capture: $e');
    }
  }

  void _processAudio(Float32List data) {
    if (!mounted || !_isPlaying) return;

    _pitchDetector.getPitchFromFloatBuffer(data).then((result) {
      if (!mounted || !_isPlaying) return;

      if (result.pitched && result.probability > 0.45 && result.pitch > 30) {
        final pitch = result.pitch;
        final double midiNote = 69 + 12 * (math.log(pitch / 440.0) / math.log(2));
        _currentMidiVal = midiNote;
      } else {
        _currentMidiVal = null;
      }
    });
  }

  Future<void> _stopListening() async {
    try {
      if (_micGranted) {
        await _audioCapture.stop();
      }
    } catch (_) {}
  }

  void _startPlaying() {
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
      _songTimeMs = 0;
      _score = 0;
      _isFinished = false;
      _pitchHistory.clear();
      _scoredBeats.clear();
    });
    _startTimer();
    _startListening();
  }

  void _stopPlaying() {
    setState(() => _isPlaying = false);
    _stopTimer();
    _stopListening();
    _currentMidiVal = null;
    _smoothedMidiVal = null;
  }

  int _lastPlayedBeat = -1;

  void _startTimer() {
    // Poll pitch at 100fps for low latency (was 22ms)
    const int pollMs = 10;
    _pollingTimer = Timer.periodic(const Duration(milliseconds: pollMs), (timer) {
        if (_currentMidiVal != null) {
          if (_smoothedMidiVal == null) {
             _smoothedMidiVal = _currentMidiVal;
          } else {
             // 0.6 smoothing factor responds much faster than previous 0.15
             _smoothedMidiVal = _smoothedMidiVal! + (_currentMidiVal! - _smoothedMidiVal!) * 0.6;
          }
        } else {
          _smoothedMidiVal = null;
        }

        _pitchHistory.add(PitchFrame(_smoothedMidiVal, _songTimeMs));
        if (_pitchHistory.length > maxPoints) { 
          _pitchHistory.removeAt(0); 
        }
    });
    
    // 120fps physics steps for ultra-smooth scrolling (was 16ms)
    const int songStepMs = 8;
    _lastPlayedBeat = -1; // Reset when starting
    
    // Play the very first beat (index 0) immediately, since the loop starts looking ahead at beat 1
    if (_chordBeats.containsKey(0) && _audioInitialized) {
        Future.microtask(() {
            for (var cn in _chordBeats[0]!) {
               final src = _noteSources[cn];
               if (src != null) _soloud.play(src, volume: 0.45);
            }
        });
    }

    // Optimization: separate logic from UI state
    _songTimer = Timer.periodic(const Duration(milliseconds: songStepMs), (timer) {
       _songTimeMs += songStepMs;
       
       if (sequences.isNotEmpty) {
          final currentBeat = (_songTimeMs / _beatDurationMs).floor();
          final audioTriggerBeat = currentBeat + 2; // Play sound 1 full beat early (2 array indices)
          final notes = sequences.first.notes;
          
          // Play audio when entering a new beat block
          if (audioTriggerBeat > _lastPlayedBeat && audioTriggerBeat >= 0 && audioTriggerBeat < notes.length) {
           _lastPlayedBeat = audioTriggerBeat;
           final noteName = notes[audioTriggerBeat];
           final chordNotes = _chordBeats[audioTriggerBeat];

           // Fire audio on next microtask to avoid blocking the timer callback
           if (_audioInitialized) {
              Future.microtask(() {
                 // Chord notes on rest bars
                 if (chordNotes != null) {
                    for (var cn in chordNotes) {
                       final src = _noteSources[cn];
                       if (src != null) _soloud.play(src, volume: 0.45);
                    }
                 }
                 // Melody note
                 if (noteName != '-' && noteName != '=') {
                    final src = _noteSources[noteName];
                    if (src != null) _soloud.play(src, volume: 0.8);
                 }
              });
           }
        }
     }
       
       _checkScore();
       
       if (sequences.isNotEmpty) {
          final totalBeats = sequences.first.notes.length;
          final totalTimeMs = (totalBeats + 2) * _beatDurationMs;
          if (_songTimeMs >= totalTimeMs && !_isFinished) {
             setState(() {
                _stopPlaying();
                _isFinished = true;
             });
             _onLessonComplete();
          }
       }
       
       // Note: we don't need setState() here because _repaintController 
       // automatically triggers a rebuild for the graph every frame anyway.
    });
  }
  
  // Scoring: +1 for each frame where user pitch is within 1.5 semitones of target
  final Set<int> _scoredBeats = {};
  
  void _checkScore() {
      if (_smoothedMidiVal == null || sequences.isEmpty) return;
      
      final currentBeat = _songTimeMs / _beatDurationMs;
      // Delay score checking until exactly at the playhead 
      final playheadBeat = currentBeat - 1.0; 
      final beatIndex = playheadBeat.floor();
      
      final notes = sequences.first.notes;
      if (beatIndex >= 0 && beatIndex < notes.length) {
          String targetNoteName = notes[beatIndex] as String;
          int noteStartIndex = beatIndex;
          
          // trace back over hold makers
          while (targetNoteName == '=' && noteStartIndex > 0) {
              noteStartIndex--;
              targetNoteName = notes[noteStartIndex] as String;
          }

          if (!_scoredBeats.contains(noteStartIndex) && targetNoteName != '-' && targetNoteName != '=') {
              int targetMidi = _nameToMidi(targetNoteName);
              // Relaxed threshold: user has the entire length of the note to hit the pitch
              // Made very forgiving (2.5 semitones) for Level 1 Lesson 1
              if ((_smoothedMidiVal! - targetMidi).abs() <= 2.5) {
                  _scoredBeats.add(noteStartIndex);
                  _score += 1;
              }
          }
      }
  }
  
  /// Parse a note name (with or without octave) to MIDI number.
  /// e.g. "A2" → 45, "C#3" → 49, "C" → 48 (legacy fallback)
  int _nameToMidi(String noteName) {
      const noteIndex = {
        'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4,
        'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11
      };
      // Check if last char is a digit → octave-qualified name
      if (noteName.length >= 2 && RegExp(r'\d').hasMatch(noteName[noteName.length - 1])) {
        final int octave = int.parse(noteName[noteName.length - 1]);
        final String note = noteName.substring(0, noteName.length - 1);
        return (octave + 1) * 12 + (noteIndex[note] ?? 0);
      }
      // Legacy fallback — bare name mapped to octave 3
      const legacyNotes = {
        'C': 48, 'C#': 49, 'D': 50, 'D#': 51, 'E': 52,
        'F': 53, 'F#': 54, 'G': 55, 'G#': 56, 'A': 57, 'Bb': 58, 'B': 59
      };
      return legacyNotes[noteName] ?? 48;
  }

  void _stopTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _songTimer?.cancel();
    _songTimer = null;
  }
  
  void _onLessonComplete() async {
      await ProgressService.markLessonCompleted(widget.lessonId);
      
      if (!mounted) return;
      
      // Navigate to separate end screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => _VocalLessonEndScreen(
            lessonTitle: widget.lessonTitle ?? 'Vocal Lesson',
            score: _score,
            maxScore: _maxPossibleScore,
          ),
        ),
      );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _repaintController.dispose();
    _stopTimer();
    _stopListening();
    if (_audioInitialized) {
      for (var source in _noteSources.values) {
        _soloud.disposeSource(source);
      }
      _soloud.deinit();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
       return const Scaffold(backgroundColor: Color(0xFF0A1929), body: Center(child: CircularProgressIndicator()));
    }
    if (errorMessage != null) {
       return Scaffold(backgroundColor: const Color(0xFF0A1929), body: Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.white))));
    }

    final List<String> notes = sequences.isNotEmpty ? sequences.first.notes.cast<String>() : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: Stack(
        children: [
          // Graph layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _repaintController,
              builder: (context, child) {
                return CustomPaint(
                  painter: VocalGraphPainter(
                    centerMidi: _currentCenterMidi,
                    pitchHistory: _pitchHistory,
                    isPlaying: _isPlaying,
                    noteNames: _noteNames,
                    songTimeMs: _songTimeMs,
                    beatDurationMs: _beatDurationMs,
                    notes: notes,
                    smoothedMidiVal: _smoothedMidiVal,
                    scoredBeats: _scoredBeats,
                    lessonTitle: widget.lessonTitle,
                    targetLevel: widget.targetLevel,
                  ),
                );
              }
            ),
          ),
          
          // Header Overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    _stopPlaying();
                    Navigator.of(context).pop();
                  },
                ),
                // Live score count removed
              ],
            ),
          ),
          
          // Play button overlay (only when not playing)
          if (!_isPlaying && !_isFinished)
            Center(
              child: GestureDetector(
                onTap: _startPlaying,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE93B81), 
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFE93B81).withOpacity(0.4), blurRadius: 20, spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                ),
              ),
            ),
            
          // Mini map at bottom — mirrors the main graph layout
          Positioned(
            bottom: 10,
            left: 40,
            right: 40,
            child: Container(
               height: 50,
               decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
               ),
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: CustomPaint(
                   painter: _MiniMapPainter(
                     notes: notes,
                     currentBeat: _songTimeMs / _beatDurationMs,
                     centerMidi: _currentCenterMidi,
                     scoredBeats: _scoredBeats,
                   ),
                 ),
               ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// SEPARATE END SCREEN
// =============================================
class _VocalLessonEndScreen extends StatelessWidget {
  final String lessonTitle;
  final int score;
  final int maxScore;

  const _VocalLessonEndScreen({
    required this.lessonTitle,
    required this.score,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    // Restore portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    final double percentage = maxScore > 0 ? (score / maxScore * 100) : 0;
    String rating;
    Color ratingColor;
    IconData ratingIcon;
    
    if (percentage >= 80) {
      rating = 'Excellent!';
      ratingColor = Colors.green;
      ratingIcon = Icons.star;
    } else if (percentage >= 50) {
      rating = 'Good Job!';
      ratingColor = Colors.orange;
      ratingIcon = Icons.thumb_up;
    } else {
      rating = 'Keep Practicing!';
      ratingColor = const Color(0xFFE93B81);
      ratingIcon = Icons.music_note;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy / Badge
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [ratingColor.withOpacity(0.8), ratingColor.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: ratingColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                  ],
                ),
                child: Icon(ratingIcon, color: Colors.white, size: 60),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                rating,
                style: TextStyle(
                  color: ratingColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                lessonTitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Score Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$score / $maxScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notes Hit',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Done button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE93B81),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================
// VOCAL GRAPH PAINTER
// =============================================
class VocalGraphPainter extends CustomPainter {
  final double centerMidi;
  final List<PitchFrame> pitchHistory;
  final bool isPlaying;
  final List<String> noteNames;
  final double songTimeMs;
  final double beatDurationMs;
  final List<String> notes;
  final double? smoothedMidiVal;
  final Set<int> scoredBeats;
  final String? lessonTitle;
  final int? targetLevel;

  VocalGraphPainter({
    required this.centerMidi,
    required this.pitchHistory,
    required this.isPlaying,
    required this.noteNames,
    required this.songTimeMs,
    required this.beatDurationMs,
    required this.notes,
    required this.smoothedMidiVal,
    required this.scoredBeats,
    this.lessonTitle,
    this.targetLevel,
  });

  String _midiToName(int midi) {
    return noteNames[midi % 12];
  }
  
  int _nameToMidi(String noteName) {
      const noteIndex = {
        'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4,
        'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11
      };
      if (noteName.length >= 2 && RegExp(r'\d').hasMatch(noteName[noteName.length - 1])) {
        final int octave = int.parse(noteName[noteName.length - 1]);
        final String note = noteName.substring(0, noteName.length - 1);
        return (octave + 1) * 12 + (noteIndex[note] ?? 0);
      }
      const legacyNotes = {
        'C': 48, 'C#': 49, 'D': 50, 'D#': 51, 'E': 52,
        'F': 53, 'F#': 54, 'G': 55, 'G#': 56, 'A': 57, 'Bb': 58, 'B': 59
      };
      return legacyNotes[noteName] ?? 48;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ---- LAYOUT ----
    // beatWidth now represents 0.5 beats (one array element).
    // Original beatWidth was 120.0 for 1 beat, so we make it 60.0 here
    final double beatWidth = 60.0; 
    final double playheadX = size.width * 0.3;
    final double currentBeat = songTimeMs / beatDurationMs;
    final double scrollOffsetX = playheadX - (currentBeat * beatWidth);
    
    // Semitone span: increased to 24 (2 octaves) so high notes in scale run don't go off screen
    final double semitoneSpan = 24.0;
    
    // Leave 80px at the bottom so the minimap area does not overlap with notes
    final double usableTopHeight = size.height - 80.0;
    final double semitoneHeight = usableTopHeight / semitoneSpan;
    
    // Helper to convert MIDI to Y position (centers the view around the natural pitch)
    double midiToY(double midi) {
      return ((centerMidi + semitoneSpan / 2) - midi) * semitoneHeight;
    }

    // ---- 1. BACKGROUND BARS (dual-tone alternating) ----
    final Paint oddBarPaint = Paint()..color = const Color(0xFF131D33);
    final Paint evenBarPaint = Paint()..color = const Color(0xFF0F172A);
    final Paint linePaint = Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 1.0;
    
    int startBeat = ((-scrollOffsetX) / beatWidth).floor();
    startBeat = math.max(0, startBeat);
    int endBeat = ((size.width - scrollOffsetX) / beatWidth).ceil();
    
    // A full measure is 4 beats = 8 half-beats (array elements)
    int startBar = startBeat ~/ 8;
    int endBar = endBeat ~/ 8;
    for (int bar = startBar; bar <= endBar; bar++) {
        // x position of the start of the bar
        final double x = scrollOffsetX + (bar * 8 * beatWidth);
        final Paint bgPaint = (bar % 2 == 0) ? evenBarPaint : oddBarPaint;
        canvas.drawRect(Rect.fromLTWH(x, 0, beatWidth * 8, size.height), bgPaint);
        
        // Draw 4 beat lines per bar (every 2 half-beats)
        for(int b = 0; b < 4; b++) {
            final double bx = x + b * 2 * beatWidth;
            canvas.drawLine(Offset(bx, 0), Offset(bx, size.height), linePaint);
        }
    }

    // ---- 2. HORIZONTAL NOTE LINES (C3 to B3) ----
    final noteLinePaint = Paint()..color = Colors.white.withOpacity(0.08)..strokeWidth = 1.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.right);
    
    final int topMidi = (centerMidi + semitoneSpan / 2).ceil();
    final int bottomMidi = (centerMidi - semitoneSpan / 2).floor();

    for (int midi = bottomMidi; midi <= topMidi; midi++) {
        final double y = midiToY(midi.toDouble());
        
        // Slightly brighter lines for natural notes
        String name = _midiToName(midi);
        bool isNatural = !name.contains('#') && !name.contains('b');
        
        noteLinePaint.color = isNatural 
            ? Colors.white.withOpacity(0.12) 
            : Colors.white.withOpacity(0.05);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), noteLinePaint);

        if (isNatural) {
            // Show octave number (standard MIDI: C3 = 48, A2 = 45)
            int octave = (midi ~/ 12) - 1;
            textPainter.text = TextSpan(
              text: '$name$octave',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(size.width - textPainter.width - 8, y - textPainter.height / 2));
        }
    }

    // ---- 3. TARGET NOTES ----
    for (int i = 0; i < notes.length; i++) {
        if (notes[i] == '-' || notes[i] == '=') continue;
        
        // Extend across consecutive hold markers '=' (not '-' rests)
        int holdCount = 0;
        while (i + 1 + holdCount < notes.length && notes[i + 1 + holdCount] == '=') {
           holdCount++;
        }
        double noteWidth = beatWidth * (1 + holdCount);
        final double noteX = scrollOffsetX + i * beatWidth;

        // Cull notes that are completely off screen
        if (noteX > size.width + beatWidth || noteX + noteWidth < -beatWidth) continue;
        
        int targetMidi = _nameToMidi(notes[i]);
        final double y = midiToY(targetMidi.toDouble());
        
        // Determine state for visual feedback (scoring kept for future levels)
        bool isActive = currentBeat >= i && currentBeat < i + (noteWidth / beatWidth);
        
        // Always show the pink fill — score only tracked in minimap
        Color fill = isActive
            ? const Color(0xFFE93B81).withOpacity(0.45) // slightly dim glow when being sung
            : const Color(0xFFE93B81).withOpacity(0.18); // always-on light pink fill

        final Paint noteFillPaint = Paint()
          ..color = fill
          ..style = PaintingStyle.fill;
          
        final Paint noteStrokePaint = Paint()
          ..color = isActive
              ? const Color(0xFFE93B81)
              : const Color(0xFFE93B81).withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.5 : 1.5;

        final RRect noteRect = RRect.fromRectAndRadius(
           Rect.fromLTWH(noteX + 4, y - 12, noteWidth - 8, 24),
           const Radius.circular(12),
        );
        
        canvas.drawRRect(noteRect, noteFillPaint);
        canvas.drawRRect(noteRect, noteStrokePaint);
        
        // Note label inside the rect
        textPainter.text = TextSpan(
          text: notes[i],
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7), 
            fontSize: 12, 
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(noteX + 12, y - textPainter.height / 2));

        // Text above the note
        final String lTitle = lessonTitle?.toLowerCase() ?? '';
        final bool isMumLesson = lTitle.contains('mum');
        final bool isL2 = lTitle.contains('wave') || lTitle.contains('12321') || lTitle.contains('further') || lTitle.contains('123454321') || lTitle.contains('jumps') || lTitle.contains('15151') || lTitle.contains('ascent (12345)') || lTitle.contains('(12345)') || lTitle.contains('descent (54321)') || lTitle.contains('(54321)');
        
        String lyricText = 'La...';
        if (isMumLesson) {
            lyricText = 'mum...';
        } else if (isL2) {
            lyricText = targetLevel == 3 ? 'Aa...' : 'Mmm...';
        }

        textPainter.text = TextSpan(
          text: lyricText,
          style: TextStyle(
            color: isActive 
                ? const Color(0xFFFF9ECA) // Bright pastel pink when active
                : const Color(0xFFE93B81).withOpacity(0.6), // Dimmed theme pink when inactive/passed
            fontSize: isActive ? 16 : 14, 
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            shadows: isActive ? [
              Shadow(color: const Color(0xFFE93B81).withOpacity(0.8), blurRadius: 10),
            ] : null,
          ),
        );
        textPainter.layout();
        // Position it just above the note block (note top is y-12)
        textPainter.paint(canvas, Offset(noteX + 4, y - 18 - textPainter.height));
    }

    // ---- 4. PLAYHEAD LINE (Moved to audio trigger 1 full beat ahead) ----
    final double audioTriggerX = playheadX + (beatWidth * 2);
    final Paint playheadPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(audioTriggerX, 0), Offset(audioTriggerX, size.height), playheadPaint);

    // ---- 5. PITCH CURVE (trail behind ball) ----
    final pathPaint = Paint()
      ..color = const Color(0xFFE93B81)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final List<List<Offset>> segments = [];
    List<Offset> currentSegment = [];
    
    final int pointCount = pitchHistory.length;

    for (int i = 0; i < pointCount; i++) {
      final PitchFrame frame = pitchHistory[i];
      if (frame.midi != null) {
        final double y = midiToY(frame.midi!);
        
        // Calculate exact horizontal position based on the time difference
        // offset from the current playback time.
        // 1 beatWidth happens in 1 beatDurationMs.
        double offsetMs = songTimeMs - frame.timeMs;
        double x = playheadX - ((offsetMs / beatDurationMs) * beatWidth);
        
        currentSegment.add(Offset(x, y));
      } else {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment);
          currentSegment = [];
        }
      }
    }
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }
    
    final graphPath = Path();
    for (var segment in segments) {
      if (segment.length == 1) {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
         graphPath.lineTo(segment[0].dx + 1, segment[0].dy); 
      } else if (segment.length == 2) {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
         graphPath.lineTo(segment[1].dx, segment[1].dy);
      } else {
         graphPath.moveTo(segment[0].dx, segment[0].dy);
         for (int i = 0; i < segment.length - 1; i++) {
            final p0 = segment[i];
            final p1 = segment[i + 1];
            final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
            if (i == 0) {
               graphPath.lineTo(midPoint.dx, midPoint.dy);
            } else {
               graphPath.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
            }
         }
         graphPath.lineTo(segment.last.dx, segment.last.dy);
      }
    }
    
    canvas.drawPath(graphPath, pathPaint);

    // ---- 6. PITCH INDICATOR (Only visible when singing) ----
    if (smoothedMidiVal != null) {
      double ballY = midiToY(smoothedMidiVal!);
      
      final ballPaint = Paint()..color = const Color(0xFFE93B81)..style = PaintingStyle.fill;
      final ballOutline = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5;

      canvas.drawCircle(Offset(playheadX, ballY), 6.0, ballPaint);
      canvas.drawCircle(Offset(playheadX, ballY), 6.0, ballOutline);
    }
  }

  @override
  bool shouldRepaint(covariant VocalGraphPainter oldDelegate) => true;
}

// =============================================
// MINIMAP PAINTER — shrunken mirror of the main graph
// =============================================
class _MiniMapPainter extends CustomPainter {
  final List<String> notes;
  final double currentBeat;
  final double centerMidi;
  final Set<int> scoredBeats;

  _MiniMapPainter({
    required this.notes,
    required this.currentBeat,
    required this.centerMidi,
    required this.scoredBeats,
  });

  int _nameToMidi(String noteName) {
    const noteIndex = {
      'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4,
      'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11
    };
    if (noteName.length >= 2 && RegExp(r'\d').hasMatch(noteName[noteName.length - 1])) {
      final int octave = int.parse(noteName[noteName.length - 1]);
      final String note = noteName.substring(0, noteName.length - 1);
      return (octave + 1) * 12 + (noteIndex[note] ?? 0);
    }
    const legacyNotes = {
      'C': 48, 'C#': 49, 'D': 50, 'D#': 51, 'E': 52,
      'F': 53, 'F#': 54, 'G': 55, 'G#': 56, 'A': 57, 'Bb': 58, 'B': 59
    };
    return legacyNotes[noteName] ?? 48;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (notes.isEmpty) return;

    final int totalBeats = notes.length;
    final double padding = 8.0;
    final double usableWidth = size.width - padding * 2;
    final double beatWidth = usableWidth / totalBeats;

    // Vertical mapping: C3(48) to B3(59) = 12 semitones
    final double semitoneSpan = 14.0;
    final double usableHeight = size.height - 8; // 4px top/bottom padding

    double midiToY(int midi) {
      return 4 + ((centerMidi + semitoneSpan / 2) - midi) / semitoneSpan * usableHeight;
    }

    final double noteHeight = 4.0;

    // Draw note bars
    for (int i = 0; i < notes.length; i++) {
      if (notes[i] == '-' || notes[i] == '=') continue;

      int targetMidi = _nameToMidi(notes[i]);
      double y = midiToY(targetMidi);

      // Determine width: extend across hold markers '=' only
      int holdCount = 0;
      while (i + 1 + holdCount < notes.length && notes[i + 1 + holdCount] == '=') {
        holdCount++;
      }
      double noteW = beatWidth * (1 + holdCount);

      double x = padding + i * beatWidth;
      bool isPassed = currentBeat >= i + (noteW / beatWidth);
      bool isActive = currentBeat >= i && currentBeat < i + (noteW / beatWidth);
      bool isHit = scoredBeats.contains(i);

      Color barColor;
      if (isHit && isPassed) {
        barColor = const Color(0xFFE93B81); // Fully colored if properly sung and passed
      } else if (isHit && isActive) {
        barColor = const Color(0xFFE93B81).withOpacity(0.6); // Lightly colored if hit currently
      } else {
        barColor = Colors.white.withOpacity(0.2); // Don't color (dim) if missed or future
      }

      final RRect rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, y - noteHeight / 2, noteW - 2, noteHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rr, Paint()..color = barColor);
    }

    // Draw playhead line
    double playheadX = padding + currentBeat * beatWidth;
    playheadX = playheadX.clamp(padding, size.width - padding);
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) {
    return oldDelegate.currentBeat != currentBeat;
  }
}
