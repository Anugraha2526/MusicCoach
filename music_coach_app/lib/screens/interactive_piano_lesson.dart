import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../models/lesson_models.dart';
import '../services/lesson_service.dart';
import '../widgets/lesson/piano_keyboard.dart';
import '../widgets/lesson/piano_minimap.dart';
import '../widgets/lesson/notation_widget.dart';
import '../widgets/lesson/draggable_note_option.dart';

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

class _InteractivePianoLessonScreenState extends State<InteractivePianoLessonScreen> {
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
  
  // Audio
  final Map<String, AudioPlayer> _audioPlayers = {};
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

    _initAudio();
    _loadSequences();
  }
  
  // ... (Keep existing _initAudio, _loadSequences, dispose, _startNote, _stopNote implementations) ...
  // Re-implementing them here for clarity in the replacement if needed, 
  // but simpler to keep structure.
  // Since I am replacing the CLASS CONTENT, I must provide full methods.

  // Shuffled options for Identify mode
  List<String> shuffledOptions = [];

  Future<void> _initAudio() async {
    final notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    for (var note in notes) {
      try {
        final player = AudioPlayer();
        // Set to low latency for better game response
        await player.setPlayerMode(PlayerMode.lowLatency); 
        await player.setReleaseMode(ReleaseMode.stop);
        // Pre-set the source to avoid load lag during play
        await player.setSource(AssetSource('audio/${note}4.mp3'));
        _audioPlayers[note] = player;
      } catch (e) {
        print('DEBUG: Error initializing audio for $note: $e');
      }
    }
  }

  Future<void> _loadSequences() async {
    try {
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
    });

    // Auto-play only for 'listen' mode
    if (currentSeq.type == 'listen') {
       Future.delayed(const Duration(milliseconds: 1000), _playCurrentSequenceAudio);
    } else if (currentSeq.type == 'learn') {
       // Highlight the note to learn immediately
       if (currentSeq.notes.isNotEmpty) {
          setState(() => highlightedKey = currentSeq.notes.first);
       }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _startNote(String note) async {
    final player = _audioPlayers[note];
    if (player != null) {
      try {
        await player.stop(); 
        await player.resume();
      } catch (e) {
        print('DEBUG: Playback error for $note: $e');
      }
    }
  }

  Future<void> _stopNote(String note) async {
    final player = _audioPlayers[note];
    if (player != null) {
       await player.stop();
    }
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
      
      _startNote(note);
      await Future.delayed(const Duration(milliseconds: 700));
      
      if (!mounted) return;
      setState(() => highlightedKey = null);
      await Future.delayed(const Duration(milliseconds: 150)); 
    }

    if (mounted) setState(() => isPlayingSequence = false);
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
    
    // User requested: Even smaller piano
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
                   child: FractionallySizedBox(
                     alignment: Alignment.centerLeft,
                     widthFactor: (currentSequenceIndex + 1) / sequences.length,
                     child: Container(
                       decoration: BoxDecoration(
                         color: const Color(0xFF00D26A),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00D26A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars, size: 80, color: Color(0xFF00D26A)),
            ),
            const SizedBox(height: 32),
            const Text(
              'LESSON COMPLETE!', 
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'ve mastered notes C, D, and E!', 
              style: TextStyle(color: Colors.white70, fontSize: 18)
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

