import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'dart:async';
import '../models/lesson_models.dart';
import '../services/lesson_service.dart';
import '../services/progress_service.dart';
import '../widgets/lesson/piano_keyboard.dart';
import '../widgets/lesson/piano_minimap.dart';
import '../widgets/lesson/notation_widget.dart';
import '../widgets/lesson/draggable_note_option.dart';
import '../widgets/lesson/moving_notation_widget.dart';
import '../widgets/lesson/colored_piano_keyboard.dart';
import '../widgets/lesson/colored_notation_widget.dart';
import '../widgets/lesson/note_circles_widget.dart';
import '../widgets/lesson/staff_place_widget.dart';

/// Interactive piano lesson screen that forces landscape mode.
/// Implements a "Simon Says" style play-and-follow game.
class InteractivePianoLessonScreen extends StatefulWidget {
  final int lessonId;
  final String? lessonTitle;
  
  // New fields for mass unlock (jump feature)
  final int? targetLevel;
  final int? targetLessonIndex;
  final List<LessonModule>? allModules;

  const InteractivePianoLessonScreen({
    super.key,
    required this.lessonId,
    this.lessonTitle,
    this.targetLevel,
    this.targetLessonIndex,
    this.allModules,
  });

  @override
  State<InteractivePianoLessonScreen> createState() => _InteractivePianoLessonScreenState();
}

class _InteractivePianoLessonScreenState extends State<InteractivePianoLessonScreen> with SingleTickerProviderStateMixin {
  // Game State
  List<PracticeSequence> sequences = [];
  bool isLoading = true;
  int currentSequenceIndex = 0;
  List<String> currentInput = []; // For playing modes
  Set<String> identifiedNotes = {}; // For Identify mode (which notes are placed correctly)
  double currentReadingProgress = 0.0; // 0.0 to 1.0 for duration bars
  bool isPlayingSequence = false;
  String? highlightedKey;
  bool isLessonComplete = false;
  String? errorMessage;
  
  // Play mode state (Lesson 3)
  int currentNoteIndex = 0; // Current position in the song
  String? wrongNote; // Track wrong note for visual feedback
  Timer? _scrollTimer;
  Set<int> _creditedIndices = {}; // Track correctly played notes to prevent double counting
  int get correctNotesCount => _creditedIndices.length;
  
  // Performance optimization: ValueNotifier for scroll to avoid full rebuilds
  final ValueNotifier<double> _scrollProgressNotifier = ValueNotifier<double>(0.0);
  double get scrollProgress => _scrollProgressNotifier.value;
  set scrollProgress(double v) => _scrollProgressNotifier.value = v;
  
  // Input tolerance: Accept key presses within this window (milliseconds)
  static const int inputToleranceMs = 200;
  DateTime? _noteStartTime; // When current note started scrolling
  String? _earlyInputNote; // Queued early input
  bool _autoAdvancePending = false; // Flag for early input auto-advance
  
  // Track split note progress
  int _splitNoteProgress = 0; // How many parts of the split note have been played
  Map<int, int> _creditedSplitNotes = {}; // Tracks how many parts of a split note were correctly hit

  
  // Audio (SoLoud)
  late SoLoud _soloud;
  AudioSource? _backtrackSource;
  Map<String, AudioSource> _noteSources = {};
  SoundHandle? _backtrackHandle;
  Timer? _durationTimer;
  static const int durationTargetMs = 800; // Easier target (0.8s)
  static const int timerStepMs = 50; // Progress update interval
  
  // Note colors - shared with ColoredPianoKeyboard to ensure consistency
  Map<String, Color> get noteColors => ColoredPianoKeyboard.noteColors;

  // Track which note the user is actively pressing (for minimap + persisting color)
  String? _pressedNote;

  // Tap mode state
  bool _tapCooldown = false; // Blocks input for 2s after correct tap
  int _tapFilledCount = 0;   // How many circles are filled

  // ======== CENTRALIZED LESSON CONFIG ========
  // Add new lessons here — everything else resolves automatically.
  static const List<_LessonConfig> _lessonConfigs = [
    _LessonConfig(
      id: 'hot_cross_buns',
      matchTitle: null,
      matchFirstNote: 'E',
      displayName: 'HOT CROSS BUNS',
      headerColor: 'green',
      backtrackAsset: 'assets/audio/piano_level1/hot_cross_buns.mp3',
      scrollDurationMs: 1189,
      performInstruction: 'Keep up with the music!',
    ),
    _LessonConfig(
      id: 'work_song',
      matchTitle: null,
      matchFirstNote: 'D',
      displayName: 'WORK SONG',
      headerColor: 'amber',
      backtrackAsset: 'assets/audio/piano_level2/work_song.mp3',
      scrollDurationMs: 480,
      performInstruction: 'Play the Work Song!',
    ),
    _LessonConfig(
      id: 'three_blind_mice',
      matchTitle: 'Three Blind Mice',
      matchFirstNote: null,
      displayName: 'THREE BLIND MICE',
      headerColor: 'red',
      backtrackAsset: 'assets/audio/piano_level3/three_blind_mice.mp3',
      scrollDurationMs: 529,
      performInstruction: 'Keep up with the music!',
    ),
    _LessonConfig(
      id: 'cyanide',
      matchTitle: 'Play at your own pace',
      matchFirstNote: 'C',
      displayName: 'CYANIDE',
      headerColor: 'cyan',
      backtrackAsset: 'assets/audio/piano_level4/cyanide.mp3',
      scrollDurationMs: 562,
      performInstruction: 'Keep up with the music!',
    ),
    _LessonConfig(
      id: 'old_macdonald',
      matchTitle: 'Old MacDonald',
      matchFirstNote: 'F',
      displayName: 'OLD MACDONALD',
      headerColor: 'purple',
      backtrackAsset: 'assets/audio/piano_level5/old_macdonald.mp3', // Note: assuming this file exists.
      scrollDurationMs: 600, // Roughly a normal speed
      performInstruction: 'Keep up with the music!',
    ),
  ];

  /// Resolves the config for the current lesson. Title-based matches take priority
  /// over first-note-only matches to avoid ambiguity (e.g. two songs starting with C).
  _LessonConfig? _resolveLessonConfig() {
    if (sequences.isEmpty) return null;
    final firstNote = sequences.first.notes.isNotEmpty ? sequences.first.notes.first : '';
    final title = widget.lessonTitle ?? '';

    // Advanced signature match for ambiguous "Rehearsal" or "Perform" lessons
    if (title.contains('Rehearsal') || title.contains('Perform')) {
      final seqString = sequences.first.notes.take(5).join(',');
      if (seqString == 'C,-,-,-,-') {
        return _lessonConfigs.firstWhere((c) => c.id == 'three_blind_mice');
      }
      if (seqString == 'C,-,-,-,E') {
        return _lessonConfigs.firstWhere((c) => c.id == 'cyanide');
      }
      if (seqString == 'F,-,-,-,-') {
        return _lessonConfigs.firstWhere((c) => c.id == 'old_macdonald');
      }
      if (seqString == 'D,-,-,-,-') {
        return _lessonConfigs.firstWhere((c) => c.id == 'work_song');
      }
      if (seqString == 'E,-,-,-,E') {
        // Hot Cross Buns - fallback if we had a config for it, but currently not in the list.
        // Assuming no strict config is needed or it's implicitly handled.
      }
    }

    // Priority 1: Match by title + first note (most specific)
    for (final cfg in _lessonConfigs) {
      if (cfg.matchTitle != null && cfg.matchFirstNote != null &&
          title.contains(cfg.matchTitle!) && firstNote == cfg.matchFirstNote) {
        return cfg;
      }
    }
    // Priority 2: Match by title only
    for (final cfg in _lessonConfigs) {
      if (cfg.matchTitle != null && cfg.matchFirstNote == null && title.contains(cfg.matchTitle!)) {
        return cfg;
      }
    }
    // Priority 3: Match by first note only (fallback)
    for (final cfg in _lessonConfigs) {
      if (cfg.matchTitle == null && cfg.matchFirstNote != null && firstNote == cfg.matchFirstNote) {
        return cfg;
      }
    }
    return null;
  }

  // Helper to determine which keys to show based on the sequences
  List<String> get _requiredKeys {
    if (sequences.isEmpty) return ['C', 'D', 'E']; // Default
    
    // Check if any note goes beyond C, D, E
    bool needsFullOctave = false;
    for (var seq in sequences) {
      for (var note in seq.notes) {
        if (note != '-' && !['C', 'D', 'E'].contains(note)) {
          needsFullOctave = true;
          break;
        }
      }
      if (needsFullOctave) break;
    }

    if (needsFullOctave) {
      return ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    } else {
      return ['C', 'D', 'E'];
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _loadSequences();
  }
  
  // ... (Keep existing _initAudio, _loadSequences, dispose, _startNote, _stopNote implementations) ...
  // Re-implementing them here for clarity in the replacement if needed, 
  // but simpler to keep structure.
  // Since I am replacing the CLASS CONTENT, I must provide full methods.

  // Shuffled options for Identify mode
  List<String> shuffledOptions = [];

  Future<void> _initAudio() async {
    print('DEBUG: Starting SoLoud audio initialization');
    
    try {
      _soloud = SoLoud.instance;
      
      // Check if already initialized to prevent errors/race conditions during navigation
      if (!_soloud.isInitialized) {
        await _soloud.init(bufferSize: 512);
        print('DEBUG: SoLoud engine initialized (Low Latency Mode)');
      } else {
         print('DEBUG: SoLoud engine already initialized, reusing instance');
      }
      
      // Pre-load all note sounds
      // Reset map to ensure we have fresh handles if needed, though they might be valid.
      // Better to clear and reload to be safe if context changed, or check validity.
      // For simplicity/safety in this small app: reload.
      _noteSources.clear();
      
      final notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
      for (var note in notes) {
        try {
          _noteSources[note] = await _soloud.loadAsset(
            'assets/audio/piano_notes/${note}4.mp3',
            mode: LoadMode.memory,
          );
        } catch (e) {
           print('DEBUG: Failed to load note $note: $e');
        }
      }
      print('DEBUG: All note sources loaded (${_noteSources.length} notes)');
      
      print('DEBUG: SoLoud audio initialization COMPLETED');
    } catch (e) {
      print('DEBUG: SoLoud init error: $e');
    }
  }

  Future<void> _loadSequences() async {
    try {
      // Ensure audio is ready BEFORE showing the lesson
      await _initAudio(); 
      
      final fetchedSequences = await LessonService.fetchLessonSequences(widget.lessonId);
      
      // Pre-load audio BEFORE showing UI
      sequences = fetchedSequences; // Update local state for the helper to usage
      await _loadBacktrackForLesson();

      if (mounted) {
        setState(() {
          // sequences already set above, but setState needed to trigger build
          isLoading = false;
          errorMessage = null; 
        });
        _startCurrentSequence();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load lesson data.\n\n$e';
        });
      }
    }
  }

  Future<void> _loadBacktrackForLesson() async {
    if (sequences.isEmpty) return;
    
    // Clear existing
    if (_backtrackSource != null && _soloud.isInitialized) {
      try {
        await _soloud.disposeSource(_backtrackSource!);
      } catch (e) {
        print('DEBUG: Error disposing backtrack: $e');
      }
      _backtrackSource = null;
    }

    try {
      final config = _resolveLessonConfig();
      final assetPath = config?.backtrackAsset;

      if (assetPath != null && _soloud.isInitialized) {
          try {
            _backtrackSource = await _soloud.loadAsset(
              assetPath,
              mode: LoadMode.memory,
            );
            print('DEBUG: Backtrack loaded: $assetPath');
          } catch (e) {
            print('DEBUG: Info - Backtrack asset not found ($assetPath), silent mode. ($e)');
          }
      }
    } catch (e) {
      print('DEBUG: Error deciding backtrack: $e');
    }
  }

  void _startCurrentSequence() {
    if (sequences.isEmpty || currentSequenceIndex >= sequences.length) return;
    
    final currentSeq = sequences[currentSequenceIndex];
    
    // Shuffle options for Identify mode to ensure they aren't right below target
    List<String> options = [];
    if (currentSeq.type == 'identify') {
      options = List.from(currentSeq.notes);
      options.shuffle();
    }

    setState(() {
       currentInput = [];
       identifiedNotes = {};
       highlightedKey = null;
       _pressedNote = null; // Clear persisted key color for next unit
       shuffledOptions = options;
       
       // Reset tap mode state
       _tapFilledCount = 0;
       _tapCooldown = false;
       
       // Reset play mode state
       if (currentSeq.type == 'play' || currentSeq.type == 'perform') {
         currentNoteIndex = 0;
         wrongNote = null;
         scrollProgress = 0.0;
         _creditedIndices.clear();
         _splitNoteProgress = 0;
         _creditedSplitNotes.clear();
       }
    });

    // Auto-play only for 'listen' mode
    if (currentSeq.type == 'listen') {
       Future.delayed(const Duration(milliseconds: 1000), _playCurrentSequenceAudio);
    } else if (currentSeq.type == 'learn') {
       // Highlight the note to learn immediately
       if (currentSeq.notes.isNotEmpty) {
          setState(() => highlightedKey = currentSeq.notes.first);
       }
    } else if (currentSeq.type == 'play' || currentSeq.type == 'perform') {
       // Backtrack audio starts on first note input now (in _handlePlayModeInput)
       
       // Highlight the first note immediately if it's not a rest
       if (currentSeq.notes.isNotEmpty) {
          // In perform mode, we might want to start automatically? 
          // For now, let's keep it consistent: start on first tap.
          if (currentSeq.notes.first == '-') {
             _startSmoothScroll();
          } else {
             setState(() => highlightedKey = currentSeq.notes.first);
          }
       }
    }
  }

  // Dynamic Scroll Duration
  // Default: 1189ms (Hot Cross Buns)
  // Work Song (Level 2 Lesson 2): 1400ms (Slower for learning)
  int get _lessonScrollDuration {
    final config = _resolveLessonConfig();
    return config?.scrollDurationMs ?? 1189; // Default for unknown lessons
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Dispose SoLoud resources
    if (_backtrackSource != null) {
      _soloud.disposeSource(_backtrackSource!);
    }
    for (var source in _noteSources.values) {
      _soloud.disposeSource(source);
    }
    _soloud.deinit();
    
    _scrollTimer?.cancel();
    _durationTimer?.cancel();
    _scrollProgressNotifier.dispose();
    super.dispose();
  }

  Future<void> _startNote(String note) async {
    // Instant playback with SoLoud (< 10ms latency)
    if (_noteSources.containsKey(note)) {
      // Fire-and-forget: Don't await the result to keep UI thread unblocked
      // print('DEBUG: Playing note $note'); // Optional: Uncomment if needed
      _soloud.play(_noteSources[note]!, volume: 1.0);
    } else {
      print('DEBUG: Note source not found for $note');
    }
    
    // Only for Read modes
    // _startDurationTimer(note); // REMOVED: Managed explicitly in onKeyTapDown to avoid auto-play triggering input
  }

  void _stopNote(String note) {
    // Notes auto-stop, no action needed
    _stopDurationTimer();
  }

  void _startDurationTimer(String note) {
    if (_durationTimer != null) return;

    final currentSeq = sequences[currentSequenceIndex];
    if (currentInput.length >= currentSeq.notes.length) return;
    
    final targetNote = currentSeq.notes[currentInput.length];
    if (note != targetNote) return;

    _durationTimer = Timer.periodic(const Duration(milliseconds: timerStepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        currentReadingProgress += (timerStepMs / durationTargetMs);
        if (currentReadingProgress >= 1.0) {
          currentReadingProgress = 1.0;
          timer.cancel();
          _durationTimer = null;
          _handleDurationComplete();
        }
      });
    });
  }

  void _stopDurationTimer() {
    if (_durationTimer != null) {
      _durationTimer!.cancel();
      _durationTimer = null;
    }
    if (currentReadingProgress < 0.9) { // Only reset if not basically finished
      setState(() {
        currentReadingProgress = 0.0;
      });
    }
  }

  void _handleDurationComplete() {
    // Current note completed
    setState(() {
       final currentSeq = sequences[currentSequenceIndex];
       currentInput.add(currentSeq.notes[currentInput.length]);
       currentReadingProgress = 0.0;
    });
    
    // Check if whole sequence complete
    final currentSeq = sequences[currentSequenceIndex];
    if (currentInput.length == currentSeq.notes.length) {
       _handleSequenceSuccess();
    }
  }

  Future<void> _playCurrentSequenceAudio() async {
    if (sequences.isEmpty) return;
    setState(() => isPlayingSequence = true);
    
    final targetNotes = sequences[currentSequenceIndex].notes;
    await Future.delayed(const Duration(milliseconds: 500));

    for (var note in targetNotes) {
      if (!mounted) return;
      setState(() => highlightedKey = note);
      
      if (note != '-') {
        await _startNote(note);
      }
      await Future.delayed(const Duration(milliseconds: 700));
      
      if (!mounted) return;
      setState(() => highlightedKey = null);
      await Future.delayed(const Duration(milliseconds: 150)); 
    }

    if (mounted) setState(() => isPlayingSequence = false);
  }



  // --- Play Mode Methods (Lesson 3) ---
  Future<void> _startBacktrackAudio() async {
    // Instant playback with SoLoud
    if (_backtrackSource != null) {
      _backtrackHandle = await _soloud.play(
        _backtrackSource!,
        looping: false,
        volume: 0.3,
      );
    }
  }

  void _stopBacktrackAudio() {
    // Instant pause
    if (_backtrackHandle != null) {
      _soloud.setPause(_backtrackHandle!, true);
    }
  }

  void _resumeBacktrackAudio() {
    // Instant resume
    if (_backtrackHandle != null) {
      _soloud.setPause(_backtrackHandle!, false);
    }
  }

  void _handlePlayModeInput(String note) {
    if (currentSequenceIndex >= sequences.length) return; // Safety guard
    
    final currentSeq = sequences[currentSequenceIndex];
    if (currentNoteIndex >= currentSeq.notes.length) return;

    // PERFORM MODE LOGIC:
    if (currentSeq.type == 'perform') {
        // Start on first note if not started
        if (currentNoteIndex == 0 && scrollProgress == 0.0 && _scrollTimer == null) {
             _startBacktrackAudio();
             _startSmoothScroll();
        }

        final expectedNoteBlock = currentSeq.notes[currentNoteIndex];
        final bool isSplitNote = expectedNoteBlock.contains(';');
        final List<String> subNotes = isSplitNote ? expectedNoteBlock.split(';') : [expectedNoteBlock];
        
        // Target is the NEXT unplayed part of this split block
        if (_splitNoteProgress < subNotes.length) {
            final targetSubNote = subNotes[_splitNoteProgress];
            
            // 1. Check if input matches CURRENT target sub-note
            if (note == targetSubNote) {
               setState(() {
                 wrongNote = null;
                 _splitNoteProgress++;
                 _creditedSplitNotes[currentNoteIndex] = _splitNoteProgress;
                 
                 if (!isSplitNote || _splitNoteProgress >= subNotes.length) {
                    _creditedIndices.add(currentNoteIndex); // Full credit
                 }
                 highlightedKey = null; // Clear highlight to show hit
               });
               return;
            } 
        }
        
        // 2. Check if input matches NEXT note (Early Press Tolerance)
        if (currentNoteIndex + 1 < currentSeq.notes.length) {
            final nextBlock = currentSeq.notes[currentNoteIndex + 1];
            final nextTargetNote = nextBlock.contains(';') ? nextBlock.split(';').first : nextBlock;
            if (note == nextTargetNote && _noteStartTime != null) {
                 // Calculate if we are close enough to the end of current note
                 final elapsed = DateTime.now().difference(_noteStartTime!).inMilliseconds;
                 final scrollDurationMs = _lessonScrollDuration;
                 final remainingMs = scrollDurationMs - elapsed;
                 
                 // If within tolerance window of next note appearing
                 if (remainingMs > 0 && remainingMs <= inputToleranceMs) {
                      setState(() {
                        wrongNote = null;
                        if (!nextBlock.contains(';')) {
                           _creditedIndices.add(currentNoteIndex + 1); // Pre-credit the whole next block
                        }
                        _creditedSplitNotes[currentNoteIndex + 1] = 1; // Credit the first sub-note
                      });
                      return;
                 }
            }
        }

        // 3. Wrong Note
        setState(() {
           wrongNote = note;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => wrongNote = null);
        });
        return;
    }


    // STANDARD PLAY MODE LOGIC (Lesson 3 / Custom Split):
    final expectedNoteBlock = currentSeq.notes[currentNoteIndex];
    final bool isSplitNote = expectedNoteBlock.contains(';');
    final List<String> subNotes = isSplitNote ? expectedNoteBlock.split(';') : [expectedNoteBlock];

    // Allow input while animating if within tolerance window
    if (scrollProgress > 0) {
      if (isSplitNote) {
         // Handle second part of split note WHILE it's scrolling
         if (_splitNoteProgress < subNotes.length) {
            final targetSubNote = subNotes[_splitNoteProgress];
            if (note == targetSubNote) {
                setState(() {
                  _splitNoteProgress++;
                  _creditedSplitNotes[currentNoteIndex] = _splitNoteProgress;
                  wrongNote = null;
                  highlightedKey = null;
                });
                // Check if split note is fully played (e.g. both halves of D;D done)
                if (_splitNoteProgress >= subNotes.length) {
                  _resumeBacktrackAudio();
                  // Resume scroll from 50% to animate the second half smoothly
                  _startSmoothScroll(startProgress: 0.5);
                }
                return;
            } else {
                setState(() { wrongNote = note; });
                _stopBacktrackAudio();
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => wrongNote = null);
                });
                return;
            }
         }
      }

      // Check if we're near the end of current note and pressing the NEXT note
      if (_noteStartTime != null && currentNoteIndex + 1 < currentSeq.notes.length) {
        final elapsed = DateTime.now().difference(_noteStartTime!).inMilliseconds;
        final scrollDurationMs = _lessonScrollDuration;
        final remainingMs = scrollDurationMs - elapsed;
        final nextExpectedBlock = currentSeq.notes[currentNoteIndex + 1];
        
        final nextTargetNote = nextExpectedBlock.contains(';') ? nextExpectedBlock.split(';').first : nextExpectedBlock;

        // If pressing next note early (within tolerance), queue it
        if (remainingMs > 0 && remainingMs <= inputToleranceMs && note == nextTargetNote) {
          _earlyInputNote = note;
          _autoAdvancePending = true;
          // VISUAL FEEDBACK: Clear prompt immediately so user knows they hit it
          setState(() {
            highlightedKey = null;
            wrongNote = null;
          });
          return;
        }
      }
      return; // Block other input while animating
    }
    
    // If current note is a rest
    if (expectedNoteBlock == '-') {
       _startSmoothScroll();
       return;
    }

    final targetSubNote = subNotes[_splitNoteProgress];

    if (note == targetSubNote) {
      // Correct note!
      setState(() {
        _splitNoteProgress++;
        _creditedSplitNotes[currentNoteIndex] = _splitNoteProgress;
        wrongNote = null;
        highlightedKey = null;
      });

      // Start or Resume Backtrack
      if (currentNoteIndex == 0 && _splitNoteProgress == 1) {
        _startBacktrackAudio();
      } else {
        _resumeBacktrackAudio();
      }

      // Only start smooth scroll if this is the FIRST note of the split block being hit,
      // because we want the block to scroll as a single unit while allowing the second tap.
      if (!isSplitNote) {
          _startSmoothScroll();
      } else if (_splitNoteProgress == 1) {
          // First tap - trigger scroll of block
          _startSmoothScroll();
      } else if (_splitNoteProgress >= subNotes.length) {
          // Last tap of split note - block is finished. 
          // Check if it was paused at the end of the block or halfway.
          if (scrollProgress >= 0.5 || _scrollTimer == null) {
             _handleSequenceSuccessFromSplit(); // Custom helper
          }
      }
    } else {
      // Wrong note
      setState(() {
        wrongNote = note;
      });

      // Music pauses if wrong note is pressed
      _stopBacktrackAudio();

      // Clear wrong note after a brief moment
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            wrongNote = null;
          });
        }
      });
    }
  }

  void _startSmoothScroll({double startProgress = 0.0}) {
    _scrollTimer?.cancel();
    _earlyInputNote = null;
    _autoAdvancePending = false;
    
    final currentSeq = sequences[currentSequenceIndex];
    final int scrollDurationMs = _lessonScrollDuration;
    
    final startTime = DateTime.now();
    _noteStartTime = startTime; // Track for tolerance window
    const stepMs = 33; // ~30fps - reduced from 50fps for better performance
    
    // Offset for resuming mid-scroll (e.g. after split note second half)
    final int progressOffsetMs = (startProgress * scrollDurationMs).round();
    
    // Use Stopwatch for more accurate timing
    final stopwatch = Stopwatch()..start();

    _scrollTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        stopwatch.stop();
        return;
      }

      final int elapsed = stopwatch.elapsedMilliseconds + progressOffsetMs;
      final newProgress = (elapsed / scrollDurationMs).clamp(0.0, 1.0);
      
      // Update ValueNotifier directly instead of setState for scroll-only updates
      _scrollProgressNotifier.value = newProgress;
      
      // Check for early input auto-advance (within tolerance window)
      if (_autoAdvancePending && _earlyInputNote != null) {
        final remainingMs = scrollDurationMs - elapsed;
        if (remainingMs <= 0) {
          // Time to advance - the early input is now "on time"
          _autoAdvancePending = false;
          _earlyInputNote = null;
        }
      }
        
      // Splitting Note Stop Logic: WAIT in the middle if we haven't pressed the second note
      final bool isSplitNote = currentSeq.notes[currentNoteIndex].contains(';');
      if (isSplitNote && newProgress >= 0.5) {
          // Update visual highlight halfway for all modes
          final nextSubNote = currentSeq.notes[currentNoteIndex].split(';')[1];
          if (highlightedKey != nextSubNote && _splitNoteProgress < 2) {
              setState(() {
                highlightedKey = nextSubNote;
              });
          }

          // ONLY stop and wait if we are in 'play' mode and waiting for second tap
          if (currentSeq.type == 'play' && _splitNoteProgress == 1) {
              timer.cancel();
              stopwatch.stop();
              _scrollTimer = null;
              _noteStartTime = null;

              _stopBacktrackAudio();
              
              // Use ValueNotifier so the drawing halts exactly halfway (gap between the split notes)
              _scrollProgressNotifier.value = 0.5;
              
              setState(() {
                scrollProgress = 0.5; // Update state representation too
              });
              return;
          }
      }
        
      if (newProgress >= 1.0) {

        // MOVE TO NEXT NOTE - only setState here for actual state changes
        timer.cancel();
        stopwatch.stop();
        _scrollTimer = null;
        _noteStartTime = null;
        
        setState(() {
          scrollProgress = 0.0;
          currentNoteIndex++;
          _splitNoteProgress = 0; // Reset for next block
        });

        // Check if song is complete
        if (currentNoteIndex >= currentSeq.notes.length) {
          setState(() => highlightedKey = null);
          _stopBacktrackAudio();
          _handleSequenceSuccess();
          return;
        }

        if (currentSeq.type == 'perform') {
           // PERFORM MODE: CONTINUOUS PLAY
           final nextBlock = currentSeq.notes[currentNoteIndex];
           setState(() => highlightedKey = nextBlock.contains(';') ? nextBlock.split(';').first : nextBlock);
           // Immediately start next note
           _startSmoothScroll();
        } else {
            // PLAY MODE: PAUSE AND WAIT
            final nextBlock = currentSeq.notes[currentNoteIndex];
            final nextTargetNote = nextBlock.contains(';') ? nextBlock.split(';').first : nextBlock;

            if (nextBlock == '-' || nextBlock == '_') {
               // Rest or Continuous Hold - auto-continue
               setState(() => highlightedKey = null);
               _startSmoothScroll();
            } else if (_autoAdvancePending && _earlyInputNote == nextTargetNote) {
               // Early input was queued for this note - auto-advance!
               _autoAdvancePending = false;
               _earlyInputNote = null;
               setState(() {
                 _splitNoteProgress = 1; // Count first part as hit
                 highlightedKey = null;
                 wrongNote = null;
               });
               _resumeBacktrackAudio();
               _startSmoothScroll();
            } else {
               // Wait for user input
               _stopBacktrackAudio();
               setState(() => highlightedKey = nextTargetNote);
            }
        }
      }
    });
  }


  // --- Interaction Logic ---
  void _onKeyTapDown(String note) {
    if (isPlayingSequence) return;
    if (currentSequenceIndex >= sequences.length) return; // Safety guard
    
    final currentSeq = sequences[currentSequenceIndex];
    _startNote(note);
    
    // Track pressed note for minimap highlighting
    setState(() => _pressedNote = note);
    
    if (currentSeq.type == 'identify') return; 

    if (currentSeq.type == 'read') {
      _startDurationTimer(note);
      return;
    }

    if (currentSeq.type == 'play' || currentSeq.type == 'perform') {
      _handlePlayModeInput(note);
      return;
    }

    if (currentSeq.type == 'tap') {
      _handleTapModeInput(note);
      return;
    }

    setState(() {
      currentInput.add(note);
    });
    _checkInput();
  }

  void _handleTapModeInput(String note) {
    if (_tapCooldown) return; // Block input during cooldown
    if (currentSequenceIndex >= sequences.length) return;
    
    final currentSeq = sequences[currentSequenceIndex];
    final expectedNote = currentSeq.notes.first; // All notes in tap are the same
    
    if (note == expectedNote) {
      // Correct!
      setState(() {
        _tapFilledCount++;
        _tapCooldown = true;
      });
      
      // Check if all circles are filled
      if (_tapFilledCount >= currentSeq.notes.length) {
        // All done - delay briefly then advance
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _tapCooldown = false;
              _pressedNote = null;
            });
            _handleSequenceSuccess();
          }
        });
      } else {
        // More circles to fill - hold key color for 2s then reset for next press
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _tapCooldown = false;
              _pressedNote = null;
            });
          }
        });
      }
    }
  }

  void _onKeyTapUp(String note) {
    final currentSeq = sequences[currentSequenceIndex];
    
    // In learn/tap mode, keep _pressedNote set so the key stays colored after correct press
    // It will be cleared when _startCurrentSequence resets for the next unit
    if (currentSeq.type != 'learn' && currentSeq.type != 'tap') {
      setState(() => _pressedNote = null);
    }
    
    if (currentSeq.type == 'read') {
      _stopDurationTimer();
    }
  }

  void _onNoteDrop(String key, String droppedNote) {
    if (currentSequenceIndex >= sequences.length) return; // Safety guard
    
    final currentSeq = sequences[currentSequenceIndex];
    if (currentSeq.type != 'identify') return;

    if (key == droppedNote) {
      _startNote(key); 
      setState(() {
        identifiedNotes.add(key);
      });
      _checkIdentifyProgress();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Try again!'), 
          duration: Duration(milliseconds: 500), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _checkInput() {
    final currentSeq = sequences[currentSequenceIndex];
    final targetNotes = currentSeq.notes;

    if (currentSeq.type == 'learn') {
       if (currentInput.isNotEmpty) {
          if (currentInput.last == targetNotes.first) {
             _handleSequenceSuccess();
          } else {
             setState(() => currentInput = []); 
          }
       }
       return;
    }

    for (int i = 0; i < currentInput.length; i++) {
        if (currentInput[i] != targetNotes[i]) {
            _handleError();
            return;
        }
    }
    if (currentInput.length == targetNotes.length) {
      _handleSequenceSuccess();
    }
  }

  void _checkIdentifyProgress() {
    final currentSeq = sequences[currentSequenceIndex];
    final targets = currentSeq.notes.toSet();
    if (identifiedNotes.containsAll(targets)) {
       _handleSequenceSuccess();
    }
  }

  void _handleError() {
    currentInput = [];
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oops! Try again.'), 
        duration: Duration(milliseconds: 1000), 
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (sequences[currentSequenceIndex].type == 'listen') {
       // Block input immediately to prevent multiple replays from rapid key presses
       setState(() => isPlayingSequence = true);
       Future.delayed(const Duration(milliseconds: 1000), _playCurrentSequenceAudio);
    }
  }

  void _handleSequenceSuccess() async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
         // Always increment to update progress bar
         currentSequenceIndex++;
      });
      
      if (currentSequenceIndex < sequences.length) {
         _startCurrentSequence();
      } else {
         // Lesson Complete! Bar is now 100% (index == length)
         // Wait for bar animation
         await Future.delayed(const Duration(milliseconds: 500));
         if (mounted) _showCompletionScreen();
      }
    }
  }

  void _handleSequenceSuccessFromSplit() {
    setState(() {
      scrollProgress = 0.0;
      currentNoteIndex++;
      _splitNoteProgress = 0; // Reset for next block
    });

    final currentSeq = sequences[currentSequenceIndex];
    // Check if song is complete
    if (currentNoteIndex >= currentSeq.notes.length) {
      setState(() => highlightedKey = null);
      _stopBacktrackAudio();
      _handleSequenceSuccess();
      return;
    }

    // Move to next waiting note
    final nextBlock = currentSeq.notes[currentNoteIndex];
    final nextTargetNote = nextBlock.contains(';') ? nextBlock.split(';').first : nextBlock;

    if (nextBlock == '-') {
       // Rest - auto-continue
       setState(() => highlightedKey = null);
       _startSmoothScroll();
    } else {
       // Wait for user input
       _stopBacktrackAudio();
       setState(() => highlightedKey = nextTargetNote);
    }
  }

  void _showCompletionScreen() {
    ProgressService.markLessonCompleted(
      widget.lessonId,
      allModules: widget.allModules,
      targetLevel: widget.targetLevel,
      targetLessonIndex: widget.targetLessonIndex,
    );
    
    // If we have level info, it means we can potentially unlock previous levels
    // Since targetLevel is now always passed, we need a separate way to check if it's a jump.
    // However, unlockLessonsUpTo is safe to call even for non-jumps because it only unlocks
    // levels strictly *below* targetLevel. But just to be cleanly intentional:
    if (widget.targetLevel != null && widget.targetLessonIndex != null && widget.allModules != null) {
      ProgressService.unlockLessonsUpTo(widget.targetLevel!, widget.targetLessonIndex!, widget.allModules);
    }
    
    setState(() => isLessonComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: Color(0xFF1E293B), body: Center(child: CircularProgressIndicator(color: Color(0xFF4FA2FF))));
    if (errorMessage != null) return Scaffold(backgroundColor: Color(0xFF1E293B), body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)))));
    if (isLessonComplete) return _buildCompletionScreen();
    if (sequences.isEmpty) return const Scaffold(backgroundColor: Color(0xFF1E293B), body: Center(child: Text("No data")));
    
    // Safety check for completion state (when animating 100% bar)
    final safeIndex = currentSequenceIndex >= sequences.length ? sequences.length - 1 : currentSequenceIndex;
    final currentSeq = sequences[safeIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Special layout for 'place' mode (staff drag interaction)
    if (currentSeq.type == 'place') {
      final targetNote = currentSeq.notes.first;
      final targetColor = noteColors[targetNote] ?? Colors.blue;
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(currentSeq),
              Expanded(
                child: StaffPlaceWidget(
                  key: ValueKey('place_$currentSequenceIndex'),
                  targetNote: targetNote,
                  targetColor: targetColor,
                  onNoteChanged: (note) {
                    _startNote(note);
                  },
                  onCorrectPlacement: () {
                    _startNote(targetNote);
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) _handleSequenceSuccess();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Special layout for 'play' and 'perform' mode (Lesson 3 & 4)
    if (currentSeq.type == 'play' || currentSeq.type == 'perform') {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(currentSeq),
              
              // 50/50 split: Notation at top, Piano at bottom
              Expanded(
                child: Column(
                  children: [
                    // Notation Area (50% height)
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: RepaintBoundary(
                            child: ValueListenableBuilder<double>(
                              valueListenable: _scrollProgressNotifier,
                              builder: (context, progress, _) {
                                return MovingNotationWidget(
                                  notes: currentSeq.notes,
                                  currentNoteIndex: currentNoteIndex,
                                  wrongNote: wrongNote,
                                  scrollProgress: progress,
                                  timeSignature: currentSeq.timeSignature,
                                  creditedSplitNotes: _creditedSplitNotes,
                                  currentSplitProgress: _splitNoteProgress,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    
                    // Piano Area (50% height)
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: SizedBox(
                          width: screenWidth * (_requiredKeys.length > 3 ? 0.65 : 0.45), // Bigger piano for play mode
                          height: 140, // Taller keys too
                          child: ColoredPianoKeyboard(
                            highlightedKey: highlightedKey,
                            onNoteDown: _onKeyTapDown,
                            onNoteUp: _onKeyTapUp,
                            currentNote: currentNoteIndex < currentSeq.notes.length 
                                ? currentSeq.notes[currentNoteIndex] 
                                : null,
                            wrongNote: wrongNote,
                            visibleNotes: _requiredKeys,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Original layout for other lesson types
    // Dynamic width based on the number of keys to display
    final int keyCount = _requiredKeys.length;
    double pianoWidthMultiplier = (currentSeq.type == 'learn' || currentSeq.type == 'tap' || currentSeq.type == 'identify') ? 0.22 : 0.32;
    // Scale up for full octave
    if (keyCount > 3) {
      pianoWidthMultiplier = (currentSeq.type == 'learn' || currentSeq.type == 'tap' || currentSeq.type == 'identify') ? 0.45 : 0.65;
    }
    
    // Scale height slightly for bigger keyboards to maintain aspect ratio
    final double basePianoHeight = currentSeq.type == 'read' ? 140 : 120;
    final double finalPianoHeight = keyCount > 3 ? basePianoHeight + 20 : basePianoHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), 
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(currentSeq),
            
            Expanded(
               child: Column(
                children: [
                   // Notation Layout (Treble staff with colored notes for 'read' mode)
                   if (currentSeq.type == 'read') 
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: ColoredNotationWidget(
                              notes: currentSeq.notes,
                              completedIndex: currentInput.length,
                              currentProgress: currentReadingProgress,
                              timeSignature: currentSeq.timeSignature,
                            ),
                          ),
                        ),
                      )
                   else if (currentSeq.type == 'tap')
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: NoteCirclesWidget(
                            note: currentSeq.notes.first,
                            color: noteColors[currentSeq.notes.first] ?? Colors.blue,
                            totalCount: currentSeq.notes.length,
                            filledCount: _tapFilledCount,
                          ),
                        ),
                      )
                   else
                      const Spacer(flex: 1), // Placeholder when no notation
                   
                   // Main Piano Area
                   Expanded(
                     flex: 3,
                     child: Center(
                       child: SizedBox(
                         width: screenWidth * pianoWidthMultiplier,
                         height: finalPianoHeight,
                         child: (currentSeq.type == 'read' || currentSeq.type == 'learn' || currentSeq.type == 'tap')
                             ? ColoredPianoKeyboard(
                                 highlightedKey: highlightedKey,
                                 onNoteDown: _onKeyTapDown,
                                 onNoteUp: _onKeyTapUp,
                                 currentNote: currentInput.length < currentSeq.notes.length 
                                     ? currentSeq.notes[currentInput.length] 
                                     : null,
                                 wrongNote: null,
                                 persistedNote: _pressedNote,
                                 visibleNotes: _requiredKeys,
                               )
                             : PianoKeyboard(
                                 highlightedKey: currentSeq.type == 'learn' || isPlayingSequence ? highlightedKey : null,
                                 onNoteDown: _onKeyTapDown,
                                 onNoteUp: _onKeyTapUp,
                                 onNoteDrop: currentSeq.type == 'identify' ? _onNoteDrop : null,
                                 showQuestionMarks: currentSeq.type == 'identify',
                                 showLabels: true,
                                 identifiedNotes: identifiedNotes,
                                 targetNotes: currentSeq.type == 'identify' ? Set.from(currentSeq.notes) : const {},
                                 visibleNotes: _requiredKeys,
                               ),
                       ),
                     ),
                   ),

                   // Mode-specific supplementary UI (Bottom) - Minimap etc (skip for 'read' mode)
                   if (currentSeq.type != 'read')
                     Padding(
                       padding: const EdgeInsets.only(bottom: 12),
                       child: _buildSupplementaryUI(currentSeq),
                     ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementaryUI(PracticeSequence seq) {
    if (seq.type == 'learn' || seq.type == 'tap') {
      return PianoRangeMinimap(
        highlightMiddle: true,
        pressedNote: _pressedNote,
        pressedNoteColor: _pressedNote != null ? noteColors[_pressedNote] : null,
      );
    }
    
    if (seq.type == 'identify') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: shuffledOptions.map((note) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DraggableNoteOption(
              note: note,
              isMatched: identifiedNotes.contains(note),
            ),
          );
        }).toList(),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildHeader(PracticeSequence seq) {
    String instruction = "";
    Color titleColor = Colors.white;

    switch(seq.type) {
      case 'listen': instruction = isPlayingSequence ? "Listen..." : "Repeat the sequence"; break;
      case 'learn': 
         final note = seq.notes.first;
         instruction = "Play the note $note";
         titleColor = noteColors[note] ?? Colors.white;
         break;
      case 'tap':
         final tapNote = seq.notes.first;
         instruction = "Play the note $tapNote";
         titleColor = noteColors[tapNote] ?? Colors.white;
         break;
      case 'place':
         final placeNote = seq.notes.first;
         instruction = "Drag to the note $placeNote";
         titleColor = noteColors[placeNote] ?? Colors.white;
         break;
      case 'identify': instruction = "Identify the keys"; break;
      case 'read': instruction = "Play the written notes"; break;
      case 'play': instruction = "Play at your own pace"; break;
      case 'perform': 
         final perfConfig = _resolveLessonConfig();
         instruction = perfConfig?.performInstruction ?? 'Keep up with the music!';
         break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          // Dynamic Header Title (e.g. Song Name) — driven by _LessonConfig
          Builder(
            builder: (context) {
              final headerConfig = _resolveLessonConfig();
              if (headerConfig == null) return const SizedBox.shrink();

              // User requested: "dont show song titles for these lessons, only show for play at your own pace, rehearsal and perform."
              // Play at your own pace = 'play' type. Rehearsal/Perform = 'perform' type.
              if (seq.type != 'play' && seq.type != 'perform') {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  headerConfig.displayName,
                  style: TextStyle(
                    color: headerConfig.headerColorValue,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              );
            },
          ),

          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context), 
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white70)
              ),
              const SizedBox(width: 12),
               Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: (seq.type == 'play' || seq.type == 'perform')
                      // Use ValueListenableBuilder for smooth progress in play modes
                      ? ValueListenableBuilder<double>(
                          valueListenable: _scrollProgressNotifier,
                          builder: (context, scrollProg, _) {
                            final totalNotes = seq.notes.isNotEmpty ? seq.notes.length : 1;
                            final progress = ((currentNoteIndex + scrollProg) / totalNotes).clamp(0.0, 1.0);
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF58CC02),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          },
                        )
                      // Other modes: Step-based (no animation needed)
                      : FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (currentSequenceIndex / sequences.length).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF58CC02),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                ),

              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              instruction,
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: titleColor,
                letterSpacing: 0.5,
              ),
            ),
            // Replay button: only visible for 'listen' mode after sequence finishes
            if (seq.type == 'listen' && !isPlayingSequence)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  onPressed: _playCurrentSequenceAudio,
                  icon: const Icon(Icons.replay, color: Colors.white70, size: 24),
                  tooltip: 'Replay sequence',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    // defaults
    int stars = 3;
    String fallbackTitle = widget.lessonTitle?.toUpperCase() ?? 'LESSON COMPLETE!';
    String title = fallbackTitle;
    String subtitle = 'You\'ve mastered notes C, D, and E!';
    double accuracy = 1.0;

    // Calculate accuracy for Perform mode
    // (Exclude Rehearsal Lesson 4 which uses 'perform' mode for continuous play but shouldn't be scored)
    // Use safe index since currentSequenceIndex is now at sequences.length (100% progress)
    final safeIndex = (currentSequenceIndex >= sequences.length) ? sequences.length - 1 : currentSequenceIndex;
    final lastSeq = sequences[safeIndex];

    // Check if it's a "Rehearsal" lesson either by title or legacy ID check
    final bool isRehearsal = (widget.lessonTitle?.contains('Rehearsal') ?? false) || widget.lessonId == 4 || (widget.lessonTitle == 'Rehearsal');
    final bool isPerformScoreable = sequences.isNotEmpty && lastSeq.type == 'perform' && !isRehearsal;

    if (isPerformScoreable) {
       final totalNotes = lastSeq.notes.where((n) => n != '-').length;
       if (totalNotes > 0) {
          accuracy = correctNotesCount / totalNotes;
          if (accuracy >= 0.9) {
             stars = 3;
             title = 'PERFECT!';
             subtitle = 'Amazing performance!';
          } else if (accuracy >= 0.7) {
             stars = 2;
             title = 'GREAT JOB!';
             subtitle = 'Keep practicing to get 3 stars!';
          } else {
             stars = 1;
             title = 'COMPLETED';
             subtitle = 'Try again for better accuracy!';
          }
       }
    } else {
       // For non-perform lessons, show a generic congratulatory subtitle
       subtitle = 'Great job completing this lesson!';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // STARS only for scoreable perform mode
            if (isPerformScoreable)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                   // index 0, 1, 2
                   // if stars = 1, only index 0 is full
                   // if stars = 2, 0 and 1 are full
                   bool isFull = index < stars;
                   return Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 8),
                     child: AnimatedScale(
                       scale: 1.0,
                       duration: Duration(milliseconds: 300 + (index * 200)),
                       child: Icon(
                         isFull ? Icons.star_rounded : Icons.star_outline_rounded,
                         size: index == 1 ? 90 : 70, // Middle star bigger
                         color: isFull ? const Color(0xFFFFC800) : Colors.white24,
                       ),
                     ),
                   );
                }),
              )
            else
              // BADGE for non-perform modes
              AnimatedScale(
                 scale: 1.0,
                 duration: const Duration(milliseconds: 500),
                 child: Container(
                   padding: const EdgeInsets.all(24),
                   decoration: BoxDecoration(
                     color: const Color(0xFF58CC02).withOpacity(0.2),
                     shape: BoxShape.circle,
                   ),
                   child: const Icon(
                     Icons.emoji_events_rounded,
                     size: 100,
                     color: Color(0xFF58CC02),
                   ),
                 ),
              ),

            const SizedBox(height: 32),

            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

             if (isPerformScoreable)
              Text(
                'Accuracy: ${(accuracy * 100).toInt()}%',
                style: const TextStyle(color: Color(0xFF58CC02), fontSize: 24, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 16),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FA2FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('CONTINUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}



/// Centralized config for each song/lesson in play/perform modes.
/// Add a new entry to [_InteractivePianoLessonScreenState._lessonConfigs] to
/// register a new lesson — the header title, backtrack audio, scroll speed,
/// and perform instruction are all derived from this single source of truth.
class _LessonConfig {
  final String id;
  final String? matchTitle;      // Substring to match against lesson title (null = don't match by title)
  final String? matchFirstNote;  // First note to match (null = don't match by note)
  final String displayName;      // Shown in the header banner
  final String headerColor;      // Color name for the header text
  final String backtrackAsset;   // Path to the backtrack audio file
  final int scrollDurationMs;    // How long each note scrolls (ms)
  final String performInstruction; // Instruction text for perform mode

  const _LessonConfig({
    required this.id,
    required this.matchTitle,
    required this.matchFirstNote,
    required this.displayName,
    required this.headerColor,
    required this.backtrackAsset,
    required this.scrollDurationMs,
    required this.performInstruction,
  });

  Color get headerColorValue {
    switch (headerColor) {
      case 'red':    return Colors.redAccent;
      case 'amber':  return Colors.amber;
      case 'green':  return Colors.greenAccent;
      case 'cyan':   return Colors.cyanAccent;
      case 'blue':   return Colors.blueAccent;
      case 'purple': return Colors.purpleAccent;
      default:       return Colors.white70;
    }
  }
}
