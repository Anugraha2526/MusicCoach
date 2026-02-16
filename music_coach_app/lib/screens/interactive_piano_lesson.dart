import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'dart:async';
import '../models/lesson_models.dart';
import '../services/lesson_service.dart';
import '../widgets/lesson/piano_keyboard.dart';
import '../widgets/lesson/piano_minimap.dart';
import '../widgets/lesson/notation_widget.dart';
import '../widgets/lesson/draggable_note_option.dart';
import '../widgets/lesson/moving_notation_widget.dart';
import '../widgets/lesson/colored_piano_keyboard.dart';
import '../widgets/lesson/colored_notation_widget.dart';

/// Interactive piano lesson screen that forces landscape mode.
/// Implements a "Simon Says" style play-and-follow game.
class InteractivePianoLessonScreen extends StatefulWidget {
  final int lessonId;

  const InteractivePianoLessonScreen({
    super.key,
    required this.lessonId,
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

  
  // Audio (SoLoud)
  late SoLoud _soloud;
  AudioSource? _backtrackSource;
  Map<String, AudioSource> _noteSources = {};
  SoundHandle? _backtrackHandle;
  Timer? _durationTimer;
  static const int durationTargetMs = 800; // Easier target (0.8s)
  static const int timerStepMs = 50; // Progress update interval
  
  // Note colors mapping
  final Map<String, Color> noteColors = {
    'C': const Color(0xFF00B4D8),
    'D': const Color(0xFF6C5CE7),
    'E': const Color(0xFF00D9A5),
  };

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
    
    // Simple heuristic: 
    // If first note is 'E' (Lesson 3/5 Hot Cross Buns), use hot_cross_buns.mp3
    // If first note is 'D' (Lesson L2-2 Work Song), use work_song_hozier.mp3 (if available) or silence.
    
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
      final firstNote = sequences.first.notes.isNotEmpty ? sequences.first.notes.first : '';
      
      String? assetPath;
      if (firstNote == 'E') {
         assetPath = 'assets/audio/piano_level1/hot_cross_buns.mp3';
      } else if (firstNote == 'D') {
         // Try Work Song
         assetPath = 'assets/audio/piano_level2/work_song.mp3';
      }

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
       shuffledOptions = options;
       
       // Reset play mode state
       if (currentSeq.type == 'play' || currentSeq.type == 'perform') {
         currentNoteIndex = 0;
         wrongNote = null;
         scrollProgress = 0.0;
         _creditedIndices.clear();
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
    if (sequences.isEmpty) return 1189;
    
    final firstNote = sequences.first.notes.isNotEmpty ? sequences.first.notes.first : '';
    
    // Work Song starts with D major/minor pattern usually, but let's check notes
    if (firstNote == 'D') {
       return 480; // Placeholder for Work Song
    }
    
    return 1189; // Default for Hot Cross Buns etc
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

        final expectedNote = currentSeq.notes[currentNoteIndex];
        
        // 1. Check if input matches CURRENT note
        if (note == expectedNote) {
           setState(() {
             wrongNote = null;
             _creditedIndices.add(currentNoteIndex);
           });
           return;
        } 
        
        // 2. Check if input matches NEXT note (Early Press Tolerance)
        if (currentNoteIndex + 1 < currentSeq.notes.length) {
            final nextNote = currentSeq.notes[currentNoteIndex + 1];
            if (note == nextNote && _noteStartTime != null) {
                 // Calculate if we are close enough to the end of current note
                 final elapsed = DateTime.now().difference(_noteStartTime!).inMilliseconds;
                 final scrollDurationMs = _lessonScrollDuration;
                 final remainingMs = scrollDurationMs - elapsed;
                 
                 // If within tolerance window of next note appearing
                 if (remainingMs > 0 && remainingMs <= inputToleranceMs) {
                      setState(() {
                        wrongNote = null;
                        _creditedIndices.add(currentNoteIndex + 1); // Pre-credit the next note
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


    // STANDARD PLAY MODE LOGIC (Lesson 3):
    // Allow input while animating if within tolerance window
    if (scrollProgress > 0) {
      // Check if we're near the end of current note and pressing the NEXT note
      if (_noteStartTime != null && currentNoteIndex + 1 < currentSeq.notes.length) {
        final elapsed = DateTime.now().difference(_noteStartTime!).inMilliseconds;
        final scrollDurationMs = _lessonScrollDuration;
        final remainingMs = scrollDurationMs - elapsed;
        final nextExpectedNote = currentSeq.notes[currentNoteIndex + 1];
        
        // If pressing next note early (within tolerance), queue it
        if (remainingMs > 0 && remainingMs <= inputToleranceMs && note == nextExpectedNote) {
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
    if (currentSeq.notes[currentNoteIndex] == '-') {
       _startSmoothScroll();
       return;
    }

    final expectedNote = currentSeq.notes[currentNoteIndex];

    if (note == expectedNote) {
      // Correct note!
      setState(() {
        wrongNote = null;
        highlightedKey = null;
      });

      // Start or Resume Backtrack
      if (currentNoteIndex == 0) {
        _startBacktrackAudio();
      } else {
        _resumeBacktrackAudio();
      }

      // Start smooth scroll animation
      _startSmoothScroll();
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

  void _startSmoothScroll() {
    _scrollTimer?.cancel();
    _earlyInputNote = null;
    _autoAdvancePending = false;
    
    final currentSeq = sequences[currentSequenceIndex];
    final int scrollDurationMs = _lessonScrollDuration;
    
    final startTime = DateTime.now();
    _noteStartTime = startTime; // Track for tolerance window
    const stepMs = 33; // ~30fps - reduced from 50fps for better performance
    
    // Use Stopwatch for more accurate timing
    final stopwatch = Stopwatch()..start();

    _scrollTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        stopwatch.stop();
        return;
      }

      final int elapsed = stopwatch.elapsedMilliseconds;
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
        
      if (newProgress >= 1.0) {
        // MOVE TO NEXT NOTE - only setState here for actual state changes
        timer.cancel();
        stopwatch.stop();
        _scrollTimer = null;
        _noteStartTime = null;
        
        setState(() {
          scrollProgress = 0.0;
          currentNoteIndex++;
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
           setState(() => highlightedKey = currentSeq.notes[currentNoteIndex]);
           // Immediately start next note
           _startSmoothScroll();
        } else {
            // PLAY MODE: PAUSE AND WAIT
            if (currentSeq.notes[currentNoteIndex] == '-') {
               // Rest - auto-continue
               setState(() => highlightedKey = null);
               _startSmoothScroll();
            } else if (_autoAdvancePending && _earlyInputNote == currentSeq.notes[currentNoteIndex]) {
               // Early input was queued for this note - auto-advance!
               _autoAdvancePending = false;
               _earlyInputNote = null;
               setState(() {
                 highlightedKey = null;
                 wrongNote = null;
               });
               _resumeBacktrackAudio();
               _startSmoothScroll();
            } else {
               // Wait for user input
               _stopBacktrackAudio();
               setState(() => highlightedKey = currentSeq.notes[currentNoteIndex]);
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
    
    if (currentSeq.type == 'identify') return; 

    if (currentSeq.type == 'read') {
      _startDurationTimer(note);
      return;
    }

    if (currentSeq.type == 'play' || currentSeq.type == 'perform') {
      _handlePlayModeInput(note);
      return;
    }

    setState(() {
      currentInput.add(note);
    });
    _checkInput();
  }

  void _onKeyTapUp(String note) {
    final currentSeq = sequences[currentSequenceIndex];
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

  void _showCompletionScreen() {
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
                          width: screenWidth * 0.45, // Bigger piano for play mode
                          height: 140, // Taller keys too
                          child: ColoredPianoKeyboard(
                            highlightedKey: highlightedKey,
                            onNoteDown: _onKeyTapDown,
                            onNoteUp: _onKeyTapUp,
                            currentNote: currentNoteIndex < currentSeq.notes.length 
                                ? currentSeq.notes[currentNoteIndex] 
                                : null,
                            wrongNote: wrongNote,
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
    final pianoWidthMultiplier = (currentSeq.type == 'learn' || currentSeq.type == 'identify') ? 0.22 : 0.32;
    
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
                   else
                      const Spacer(flex: 1), // Placeholder when no notation
                   
                   // Main Piano Area
                   Expanded(
                     flex: 3,
                     child: Center(
                       child: SizedBox(
                         width: currentSeq.type == 'read' ? screenWidth * 0.45 : screenWidth * pianoWidthMultiplier,
                         height: currentSeq.type == 'read' ? 140 : 110,
                         child: currentSeq.type == 'read'
                             ? ColoredPianoKeyboard(
                                 highlightedKey: highlightedKey,
                                 onNoteDown: _onKeyTapDown,
                                 onNoteUp: _onKeyTapUp,
                                 currentNote: currentInput.length < currentSeq.notes.length 
                                     ? currentSeq.notes[currentInput.length] 
                                     : null,
                                 wrongNote: null,
                               )
                             : PianoKeyboard(
                                 highlightedKey: currentSeq.type == 'learn' || isPlayingSequence ? highlightedKey : null,
                                 onNoteDown: _onKeyTapDown,
                                 onNoteUp: _onKeyTapUp,
                                 onNoteDrop: currentSeq.type == 'identify' ? _onNoteDrop : null,
                                 showQuestionMarks: currentSeq.type == 'identify',
                                 showLabels: true,
                                 identifiedNotes: identifiedNotes,
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
    if (seq.type == 'learn') {
      return PianoRangeMinimap(highlightMiddle: true);
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
      case 'identify': instruction = "Identify the keys"; break;
      case 'read': instruction = "Play the written notes"; break;
      case 'play': instruction = "Play at your own pace"; break;
      case 'perform': 
         instruction = (sequences.isNotEmpty && sequences.first.notes.isNotEmpty && sequences.first.notes.first == 'D')
             ? "Play the Work Song!"
             : "Keep up with the music!"; 
         break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          // Dynamic Header Title (e.g. Song Name)
          if (sequences.isNotEmpty && sequences.first.notes.isNotEmpty && sequences.first.notes.first == 'D')
             const Padding(
               padding: EdgeInsets.only(bottom: 8),
               child: Text(
                 "WORK SONG",
                 style: TextStyle(
                   color: Colors.amber,
                   fontWeight: FontWeight.w900,
                   fontSize: 16,
                   letterSpacing: 1.5,
                 ),
               ),
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
          Text(
            instruction,
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: titleColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    // defaults
    int stars = 3;
    String title = 'LESSON COMPLETE!';
    String subtitle = 'You\'ve mastered notes C, D, and E!';
    double accuracy = 1.0;
    
    // Calculate accuracy for Perform mode
    // (Exclude Rehearsal Lesson 4 which uses 'perform' mode for continuous play but shouldn't be scored)
    // Use safe index since currentSequenceIndex is now at sequences.length (100% progress)
    final safeIndex = (currentSequenceIndex >= sequences.length) ? sequences.length - 1 : currentSequenceIndex;
    final lastSeq = sequences[safeIndex];
    
    if (sequences.isNotEmpty && lastSeq.type == 'perform' && widget.lessonId != 4) {
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
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // STARS
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
            ),
            const SizedBox(height: 32),
            Text(
              title, 
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)
            ),
            const SizedBox(height: 8),
             if (sequences.isNotEmpty && lastSeq.type == 'perform' && widget.lessonId != 4)
              Text(
                'Accuracy: ${(accuracy * 100).toInt()}%',
                style: const TextStyle(color: Color(0xFF58CC02), fontSize: 24, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            Text(
              subtitle, 
              style: const TextStyle(color: Colors.white70, fontSize: 18)
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

  // End of file class

