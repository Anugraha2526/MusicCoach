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
  double scrollProgress = 0.0; // Smooth scrolling progress 0.0 to 1.0
  Timer? _scrollTimer;
  int correctNotesCount = 0; // For Lesson 5 accuracy

  
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
      // Initialize SoLoud engine with low buffer for latency < 10ms
      _soloud = SoLoud.instance;
      // Default is 2048 (~46ms). 512 is ~11ms which is imperceptible.
      await _soloud.init(bufferSize: 512);
      print('DEBUG: SoLoud engine initialized (Low Latency Mode)');
      
      // Pre-load backtrack audio source
      _backtrackSource = await _soloud.loadAsset(
        'assets/audio/hot_cross_buns.mp3',
        mode: LoadMode.memory, // Pre-load into memory for instant playback
      );
      print('DEBUG: Backtrack source loaded');
      
      // Pre-load all note sounds
      final notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
      for (var note in notes) {
        _noteSources[note] = await _soloud.loadAsset(
          'assets/audio/${note}4.mp3',
          mode: LoadMode.memory,
        );
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
      if (mounted) {
        setState(() {
          sequences = fetchedSequences;
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
         correctNotesCount = 0;
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
    super.dispose();
  }

  Future<void> _startNote(String note) async {
    // Instant playback with SoLoud (< 10ms latency)
    if (_noteSources.containsKey(note)) {
      // Fire-and-forget: Don't await the result to keep UI thread unblocked
      _soloud.play(_noteSources[note]!);
    }
    
    // Only for Read modes
    _startDurationTimer(note);
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
        looping: true,
        volume: 1.0,
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
    if (scrollProgress > 0 && sequences[currentSequenceIndex].type == 'play') return; // Prevent input while animating in standard Play mode
    
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
        if (note == expectedNote) {
           // Visual feedback only
           setState(() {
             wrongNote = null;
             // highlightedKey = null; // Optional: clear hint if they got it
             correctNotesCount++;
           });
           // Play user note logic is handled in _onKeyTapDown -> _startNote calling
        } else {
           setState(() {
             wrongNote = note;
           });
           Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => wrongNote = null);
           });
        }
        return;
    }

    // STANDARD PLAY MODE LOGIC (Lesson 3):
    // If current note is a rest (shouldn't happen if logic works, but safety check)
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

      // Start or Resume Backtrack (instant with lowLatency mode)
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
    
    final currentSeq = sequences[currentSequenceIndex];
    // Tuned to 1125ms to correct for "half beat late" drift at the end
    final int scrollDurationMs = 1185;
    
    // Use normal speed for backtrack as requested
    // Use normal speed for backtrack as requested
    // (SoLoud handles this via the play method parameters, default is 1.0)
    
    final startTime = DateTime.now();
    const stepMs = 20; // 50fps for better balance of smoothness and performance

    _scrollTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final int elapsed = DateTime.now().difference(startTime).inMilliseconds;

      setState(() {
        // Calculate progress based on real elapsed time to avoid drift
        scrollProgress = (elapsed / scrollDurationMs).clamp(0.0, 1.0);
        
        if (scrollProgress >= 1.0) {
          // MOVE TO NEXT NOTE
          scrollProgress = 0.0;
          currentNoteIndex++;
          timer.cancel();
          _scrollTimer = null;

          // Check if song is complete
          if (currentNoteIndex >= currentSeq.notes.length) {
            highlightedKey = null;
            _stopBacktrackAudio();
            _handleSequenceSuccess();
            return;
          }

          if (currentSeq.type == 'perform') {
             // PERFORM MODE: CONTINUOUS PLAY
             // Do NOT stop audio.
             // Update visual hint for next note
             highlightedKey = currentSeq.notes[currentNoteIndex];
             // Automatically start scrolling for the next note immediately
             _startSmoothScroll();
          } else {
              // PLAY MODE: PAUSE AND WAIT
              // Automatic Progression for Rests
              if (currentSeq.notes[currentNoteIndex] == '-') {
                 // Recursively start scrolling for the rest
                 highlightedKey = null;
                 _startSmoothScroll();
              } else {
                 // Reached a new note, pause and wait for user
                 _stopBacktrackAudio();
                 highlightedKey = currentSeq.notes[currentNoteIndex];
              }
          }
        }
      });
    });
  }

  // --- Interaction Logic ---
  void _onKeyTapDown(String note) {
    if (isPlayingSequence) return;
    
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

    if (currentSequenceIndex < sequences.length - 1) {
      if (mounted) {
        setState(() {
          currentSequenceIndex++;
        });
        _startCurrentSequence();
      }
    } else {
      _showCompletionScreen();
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

    final currentSeq = sequences[currentSequenceIndex];
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
                          child: MovingNotationWidget(
                            notes: currentSeq.notes,
                            currentNoteIndex: currentNoteIndex,
                            wrongNote: wrongNote,
                            scrollProgress: scrollProgress,
                            timeSignature: currentSeq.timeSignature,
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
                   // Notation Layout (Treble staff)
                   if (currentSeq.type == 'read') 
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: NotationView(
                             notes: currentSeq.notes,
                             completedIndex: currentInput.length,
                             currentProgress: currentReadingProgress,
                           ),
                        ),
                      )
                   else
                      const Spacer(flex: 1), // Placeholder when no notation
                   
                   // Main Piano Area
                   Expanded(
                     flex: 4,
                     child: Center(
                       child: SizedBox(
                         width: screenWidth * pianoWidthMultiplier,
                         height: 110,
                         child: PianoKeyboard(
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

                   // Mode-specific supplementary UI (Bottom) - Minimap etc
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
      case 'perform': instruction = "Keep up with the music!"; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double progress;
                        if (seq.type == 'play' || seq.type == 'perform') {
                          // Play Mode: Continuous Smooth Flow
                          // (Index + Fraction of current note) / Total
                          final totalNotes = seq.notes.isNotEmpty ? seq.notes.length : 1;
                          progress = (currentNoteIndex + scrollProgress) / totalNotes;
                        } else {
                          // Other Modes: Step-based
                          progress = (currentSequenceIndex + 1) / sequences.length;
                        }
                        
                        // Clamp and ensure valid
                        progress = progress.clamp(0.0, 1.0);

                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color: const Color(0xFF58CC02), // Duolingo Green
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }
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
    if (sequences.isNotEmpty && sequences[currentSequenceIndex].type == 'perform') {
       final totalNotes = sequences[currentSequenceIndex].notes.where((n) => n != '-').length;
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
             if (sequences.isNotEmpty && sequences[currentSequenceIndex].type == 'perform')
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

