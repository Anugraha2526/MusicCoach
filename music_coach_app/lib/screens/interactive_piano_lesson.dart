import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/lesson_models.dart';
import '../services/lesson_service.dart';

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
  List<String> currentInput = [];
  bool isPlayingSequence = false;
  String? highlightedKey;
  bool isLessonComplete = false;
  String? errorMessage;
  
  // Audio
  final Map<String, AudioPlayer> _audioPlayers = {};

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initAudio();
    _loadSequences();
  }

  Future<void> _initAudio() async {
    // Preload sounds
    final notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    print('DEBUG: Initializing Audio...');
    
    for (var note in notes) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        // Force volume to max
        await player.setVolume(1.0); 
        
        // Debug path
        final path = 'audio/${note}4.mp3';
        print('DEBUG: Loading asset: $path');
        
        await player.setSource(AssetSource(path));
        _audioPlayers[note] = player;
      } catch (e) {
        print('DEBUG: Error initializing audio for $note: $e');
      }
    }
  }

  Future<void> _loadSequences() async {
    try {
      final fetchedSequences = await LessonService.fetchLessonSequences(widget.lessonId);
      setState(() {
        sequences = fetchedSequences;
        isLoading = false;
        errorMessage = null; 
      });
      // Start slightly delayed to let UI settle
      Future.delayed(const Duration(milliseconds: 1000), _playCurrentSequence);
    } catch (e) {
      print('Error loading sequences: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load lesson data.\n\n$e';
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  // --- Audio Logic ---

  // Track active "sessions" for each note to handle rapid re-triggering
  final Map<String, int> _noteActiveTokens = {};

  Future<void> _startNote(String note) async {
    try {
      // 1. Invalidate any previous fade/stop loops for this note
      final newToken = (_noteActiveTokens[note] ?? 0) + 1;
      _noteActiveTokens[note] = newToken;

      setState(() => highlightedKey = note);
      
      final player = _audioPlayers[note];
      if (player != null) {
        print('DEBUG: Playing note $note (Token: $newToken)');
        // 2. Stop immediately and reset volume
        await player.stop(); 
        await player.setVolume(1.0); 
        await player.resume();
      } else {
        print('DEBUG: Player for $note is null!');
      }
    } catch (e) {
      print('DEBUG: Error playing note $note: $e');
    }
  }

  Future<void> _stopNote(String note) async {
    try {
      if (!isPlayingSequence) { 
          final player = _audioPlayers[note];
          final currentToken = _noteActiveTokens[note];

          if (player != null) {
            // Fade out loop
            for (var i = 10; i >= 0; i--) {
               if (_noteActiveTokens[note] != currentToken) return;
               
               await player.setVolume(i / 10.0);
               await Future.delayed(const Duration(milliseconds: 15)); 
            }
            
            if (_noteActiveTokens[note] == currentToken) {
               await player.stop();
               if (mounted && highlightedKey == note) {
                 setState(() => highlightedKey = null);
               }
            }
          } else {
             if (mounted) setState(() => highlightedKey = null);
          }
      }
    } catch (e) {
      print('Error stopping note: $e');
    }
  }

  // For the DEMO sequence, we play full duration (or fixed duration)
  Future<void> _playDemoNote(String note) async {
     try {
      setState(() => highlightedKey = note);
      
      final player = _audioPlayers[note];
      if (player != null) {
        // Must reset volume in case it was faded out previously
        await player.setVolume(1.0); 
        await player.stop();
        await player.resume();
      }

      // Hold visual highlight and let sound play for a bit
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) setState(() => highlightedKey = null);
    } catch (e) {
      print('Error playing demo note: $e');
    }
  }

  Future<void> _playCurrentSequence() async {
    if (sequences.isEmpty || currentSequenceIndex >= sequences.length) return;
    
    setState(() {
      isPlayingSequence = true;
      currentInput = []; 
    });

    final targetNotes = sequences[currentSequenceIndex].notes;
    
    await Future.delayed(const Duration(milliseconds: 1000));

    for (var note in targetNotes) {
      if (!mounted) return;
      await _playDemoNote(note);
      await Future.delayed(const Duration(milliseconds: 100)); // gap
    }

    if (mounted) {
      setState(() {
        isPlayingSequence = false;
      });
    }
  }

  // --- User Input Logic ---

  void _onKeyTapDown(String note) {
    if (isPlayingSequence) return; 

    _startNote(note);
    
    setState(() {
      currentInput.add(note);
    });

    _checkInput();
  }

  void _onKeyTapUp(String note) {
    if (isPlayingSequence) return;
    _stopNote(note);
  }

  void _checkInput() {
    if (sequences.isEmpty) return;
    
    final targetNotes = sequences[currentSequenceIndex].notes;
    
    // Check match
    for (int i = 0; i < currentInput.length; i++) {
        if (currentInput[i] != targetNotes[i]) {
            _handleError();
            return;
        }
    }

    // Check complete
    if (currentInput.length == targetNotes.length) {
      _handleSequenceSuccess();
    }
  }

  void _handleError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oops! Listen carefully and try again.'),
        duration: Duration(milliseconds: 1000),
        backgroundColor: Colors.redAccent,
      ),
    );
    // Reset after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
        if(mounted) {
            setState(() => currentInput = []);
            _playCurrentSequence(); 
        }
    });
  }

  void _handleSequenceSuccess() async {
    // Keep the "success" feel for a moment before moving on
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (currentSequenceIndex < sequences.length - 1) {
      setState(() {
        currentSequenceIndex++;
        currentInput = [];
      });
      _playCurrentSequence();
    } else {
      _showCompletionScreen();
    }
  }

  void _showCompletionScreen() {
    setState(() {
      isLessonComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E293B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8))),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              const Text(
                'Oops! Connection Failed.',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  _loadSequences();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (!isLoading && sequences.isEmpty && errorMessage == null) {
       return const Scaffold(
        backgroundColor: Color(0xFF1E293B),
        body: Center(child: Text('No sequences found.', style: TextStyle(color: Colors.white))),
      );
    }

    if (isLessonComplete) {
      return Scaffold(
        backgroundColor: const Color(0xFF00D26A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'LESSON COMPLETE!',
                style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200, height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00D26A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('CONTINUE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main Game UI
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: SafeArea(
        child: Column(
          children: [
            // --- Top Bar ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: isPlayingSequence ? null : _playCurrentSequence,
                    icon: const Icon(Icons.replay_circle_filled_rounded),
                    color: const Color(0xFF00B4D8),
                    iconSize: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: sequences.isEmpty ? 0.0 : (currentSequenceIndex / sequences.length),
                        minHeight: 16,
                        backgroundColor: const Color(0xFF334155),
                        color: const Color(0xFF00D26A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // --- Status Text ---
            Expanded(
              child: Center(
                child: Text(
                  isPlayingSequence ? "Listen..." : "Repeat the steps!",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            
            // --- Piano Keys ---
            // Center the piano and restrict width to ~45% of screen (Duolingo style)
            Expanded(
              child: Center(
                child: SizedBox(
                   // In landscape, width is the "longer" dimension. 
                   // We want 45% of that width.
                  width: MediaQuery.of(context).size.width * 0.45,
                  height: 240, 
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      // Account for margins: 3 keys * 4px margin (2-left, 2-right) = 12px total margin
                      // Actually let's just make the calculation safer
                      final whiteKeyWidth = (totalWidth - 12) / 3; 
                      final blackKeyWidth = whiteKeyWidth * 0.55; 
                      final blackKeyHeight = 240 * 0.45; // 45% height

                      return Stack(
                        alignment: Alignment.topLeft,
                        clipBehavior: Clip.none,
                        children: [
                          // White Keys Layer
                          Row(
                            children: [
                              _WhiteKey(
                                label: 'C',
                                width: whiteKeyWidth,
                                isPressed: highlightedKey == 'C',
                                onTapDown: () => _onKeyTapDown('C'),
                                onTapUp: () => _onKeyTapUp('C'),
                              ),
                              _WhiteKey(
                                label: 'D',
                                width: whiteKeyWidth,
                                isPressed: highlightedKey == 'D',
                                isMiddle: true,
                                onTapDown: () => _onKeyTapDown('D'),
                                onTapUp: () => _onKeyTapUp('D'),
                              ),
                              _WhiteKey(
                                label: 'E',
                                width: whiteKeyWidth,
                                isPressed: highlightedKey == 'E',
                                onTapDown: () => _onKeyTapDown('E'),
                                onTapUp: () => _onKeyTapUp('E'),
                              ),
                            ],
                          ),

                          // Black Keys Layer
                          // Position logic needs to account for the margins too.
                          // Key 1 center: margin(2) + w/2
                          // Key 2 center: margin(2) + w + margin(4) + w/2 ... complicated
                          // Let's approximate positions visually since they are decorative.
                          // C# is between C and D.
                          // C ends at: 2 + width + 2. D starts at: 3*margin + width.
                          // Gap center is at: 2 + width + 2 (edge of C) ... roughly (width + 4)
                          Positioned(
                            left: (whiteKeyWidth + 4) - (blackKeyWidth / 2),
                            top: 0,
                            child: _BlackKey(
                              label: '', 
                              width: blackKeyWidth,
                              height: blackKeyHeight,
                            ),
                          ),
                          // D# is between D and E
                          Positioned(
                            left: ((whiteKeyWidth + 4) * 2) - (blackKeyWidth / 2),
                            top: 0,
                            child: _BlackKey(
                              label: '',
                              width: blackKeyWidth,
                              height: blackKeyHeight,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteKey extends StatelessWidget {
  final String label;
  final double width;
  final bool isPressed;
  final bool isMiddle;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _WhiteKey({
    required this.label,
    required this.width,
    required this.isPressed,
    this.isMiddle = false,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp, // Handle drag off
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: width,
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2), // Small gap for rounded look
        decoration: BoxDecoration(
          color: isPressed ? const Color(0xFFE2E8F0) : Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          // All corners rounded
          borderRadius: BorderRadius.circular(12),
          gradient: isPressed 
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                )
              : null,
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 2,
              ),
          ],
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _BlackKey extends StatelessWidget {
  final String label;
  final double width;
  final double height;

  const _BlackKey({
    required this.label,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        // All corners rounded
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF333333), Colors.black],
        ),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
