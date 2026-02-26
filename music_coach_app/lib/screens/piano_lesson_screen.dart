import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'interactive_piano_lesson.dart';
import '../services/lesson_service.dart';
import '../models/lesson_models.dart';
import '../services/progress_service.dart';

class PianoLessonScreen extends StatefulWidget {
  const PianoLessonScreen({super.key});

  @override
  State<PianoLessonScreen> createState() => _PianoLessonScreenState();
}

class _PianoLessonScreenState extends State<PianoLessonScreen>
    with TickerProviderStateMixin {
  int? selectedLessonIndex;
  // Initialize with a very large offset to start at the bottom (Level 1 & 2)
  // The actual maxScrollExtent will clamp this value automatically
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 100000);

  // Piano color
  final Color _pianoColor = const Color(0xFF00B4D8);

  List<LessonModule> _backendModules = [];
  bool _isLoading = true;
  Set<int> _completedLessons = {};

  // Generate all lessons placeholders (Level 1 first, going up to Level 5)
  List<LessonPlaceholder> get _lessonPlaceholders {
    final placeholders = <LessonPlaceholder>[];
    for (int level = 1; level <= 5; level++) {
      for (int lessonIndex = 0; lessonIndex < 5; lessonIndex++) {
        placeholders.add(LessonPlaceholder(
          level: level,
          index: lessonIndex,
        ));
      }
    }
    return placeholders;
  }

  @override
  void initState() {
    super.initState();
    // Enforce portrait mode when entering this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final modules = await LessonService.fetchModules();
      final completed = await ProgressService.getCompletedLessons();
      
      if (mounted) {
        setState(() {
          _backendModules = modules;
          _completedLessons = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('DEBUG: Error loading lessons: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final completed = await ProgressService.getCompletedLessons();
    if (mounted) {
      setState(() {
         _completedLessons = completed;
      });
    }
  }

  void _onLessonTap(int placeholderIndex, LessonItem? backendLesson, bool isLocked, {bool isJump = false, int? targetLevel, int? targetLessonIndex, List<LessonModule>? allModules}) {
    setState(() {
      if (selectedLessonIndex == placeholderIndex) {
        if (backendLesson != null && (!isLocked || isJump)) { 
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InteractivePianoLessonScreen(
                lessonId: backendLesson!.id,
                lessonTitle: backendLesson.title,
                targetLevel: targetLevel,
                targetLessonIndex: targetLessonIndex,
                allModules: allModules,
              ),
            ),
          ).then((_) {
             _loadProgress();
          });
        } else if (isLocked && backendLesson != null && !isJump) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete the previous level to unlock this lesson!'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          // Placeholder for future lessons
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This lesson is coming soon!'),
              backgroundColor: Color(0xFF00B4D8),
            ),
          );
        }
      } else {
        // Select new
        selectedLessonIndex = placeholderIndex;
      }
    });
  }

  // Vertical spacing constants
  static const double _verticalSpacing = 160.0; // Spacing between lessons
  static const double _levelGap = 100.0;       // Extra gap for level headers
  static const double _bottomPadding = 220.0;  // Reverted closer to original

  double _getLessonY(int index, double contentHeight) {
    final level = (index / 5).floor();
    return contentHeight - _bottomPadding - (index * _verticalSpacing) - (level * _levelGap);
  }

  Offset _getLessonPosition(int placeholderIndex, double screenWidth, double contentHeight) {
    final placeholder = _lessonPlaceholders[placeholderIndex];
    final level = placeholder.level;
    final lessonInLevel = placeholder.index; // 0-4 within the level
    
    final y = _getLessonY(placeholderIndex, contentHeight);
    
    // Horizontal center
    final centerX = screenWidth / 2;
    final maxOffset = screenWidth * 0.25; // Maximum horizontal offset
    
    // Progress within the level (0 to 1 for 5 lessons)
    final progressInLevel = lessonInLevel / 4.0;
    
    // Alternate direction per level: Level 1 goes right, Level 2 goes left, etc.
    final isRightDirection = (level % 2 == 1); // Odd levels go right, even go left
    final direction = isRightDirection ? 1.0 : -1.0;
    
    // Create a curve within the level (sine wave for smooth curve)
    final curve = math.sin(progressInLevel * math.pi) * maxOffset * direction;
    final x = centerX + curve;
    
    return Offset(x, y);
  }

  // Get level label position (placed in the gap between levels)
  double _getLevelLabelY(int level, double contentHeight) {
    // Position it centered in the gap for Level 1, and balanced for others
    final firstLessonIndex = (level - 1) * 5;
    // Increased offset to move it DOWN towards the bottom of the screen/nav
    return _getLessonY(firstLessonIndex, contentHeight) + 130;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final placeholders = _lessonPlaceholders;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1929),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _pianoColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.piano,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Piano',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFF0A1929),
      body: Builder(
        builder: (context) {
          final contentHeight = placeholders.length * 160.0 + (5 * 100.0) + 200;
          return SingleChildScrollView(
            controller: _scrollController,
            reverse: false,
            child: SizedBox(
              height: contentHeight,
              child: Stack(
                children: [
                  // Visual Path (Journey Line)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _JourneyPathPainter(
                        placeholders: placeholders,
                        contentHeight: contentHeight,
                        screenWidth: screenWidth,
                        getLessonPosition: _getLessonPosition,
                      ),
                    ),
                  ),
                  // Level headers
                  ...List.generate(6, (levelIndex) {
                    final level = levelIndex + 1;
                    final labelY = _getLevelLabelY(level, contentHeight);
                    
                    final String headerText = level == 6 ? 'COMING SOON' : 'LEVEL $level';
                    
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: labelY - 20, // Adjusted to center capsule on the line
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1.5)),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                                child: Text(
                                  headerText,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1.5)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  // Lesson buttons
                  ...placeholders.asMap().entries.map((entry) {
                    final index = entry.key;
                    final placeholder = entry.value;
                    
                    // Match placeholder to backend lesson
                    LessonItem? backendLesson;
                    final module = _backendModules.firstWhere(
                      (m) => m.order == placeholder.level,
                      orElse: () => LessonModule(id: -1, title: '', description: '', order: -1, lessons: []),
                    );
                    
                    if (module.id != -1) {
                      final lessonsInModule = module.lessons;
                      if (placeholder.index < lessonsInModule.length) {
                        backendLesson = lessonsInModule[placeholder.index];
                      }
                    }

                    bool isLevelUnlocked = placeholder.level == 1;
                    if (placeholder.level > 1) {
                      final prevModule = _backendModules.firstWhere(
                        (m) => m.order == placeholder.level - 1,
                        orElse: () => LessonModule(id: -1, title: '', description: '', order: -1, lessons: []),
                      );
                      if (prevModule.id != -1 && prevModule.lessons.isNotEmpty) {
                         // Unlock if the last lesson of the previous level is completed
                         isLevelUnlocked = _completedLessons.contains(prevModule.lessons.last.id);
                      }
                    }

                    // Jump logic: Lesson 1 of any level is always "playable" for jumping
                    final bool isJumpable = !isLevelUnlocked && placeholder.index == 0;
                    final bool isEffectivelyPlayable = backendLesson != null && (isLevelUnlocked || isJumpable);

                    final position = _getLessonPosition(index, screenWidth, contentHeight);
                    
                    return Positioned(
                      left: position.dx - 60, // Wider for text
                      top: position.dy - 60, // Moved up to accommodate jump text
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          _AnimatedLessonButton(
                            lessonTitle: backendLesson?.title ?? '?',
                            pianoColor: _pianoColor,
                            isAvailable: isEffectivelyPlayable,
                            isSelected: selectedLessonIndex == index,
                            onTap: () => _onLessonTap(
                              index, 
                              backendLesson, 
                              !isLevelUnlocked, 
                              isJump: isJumpable,
                              targetLevel: placeholder.level,
                              targetLessonIndex: placeholder.index,
                              allModules: _backendModules,
                            ),
                          ),
                          if (isJumpable)
                            Positioned(
                              top: -24,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: selectedLessonIndex == index ? 0.0 : 1.0, 
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Jump here',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LessonPlaceholder {
  final int level;
  final int index;

  LessonPlaceholder({required this.level, required this.index});
}

class _AnimatedLessonButton extends StatefulWidget {
  final String lessonTitle;
  final Color pianoColor;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedLessonButton({
    required this.lessonTitle,
    required this.pianoColor,
    required this.isAvailable,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedLessonButton> createState() => _AnimatedLessonButtonState();
}

class _AnimatedLessonButtonState extends State<_AnimatedLessonButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Slower for smooth rotation
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedLessonButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 120, // Container for button + text
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: widget.isAvailable 
                      ? (widget.isSelected ? Colors.white : widget.pianoColor)
                      : const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected ? widget.pianoColor : Colors.white24,
                    width: 3,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: widget.pianoColor.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  widget.isAvailable ? Icons.music_note : Icons.lock_outline,
                  color: widget.isSelected && widget.isAvailable ? widget.pianoColor : Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.lessonTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                shadows: widget.isSelected ? [
                  const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
                ] : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyPathPainter extends CustomPainter {
  final List<LessonPlaceholder> placeholders;
  final double contentHeight;
  final double screenWidth;
  final Offset Function(int, double, double) getLessonPosition;

  _JourneyPathPainter({
    required this.placeholders,
    required this.contentHeight,
    required this.screenWidth,
    required this.getLessonPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (placeholders.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final path = Path();
    final startPos = getLessonPosition(0, screenWidth, contentHeight);
    path.moveTo(startPos.dx, startPos.dy);

    for (int i = 1; i < placeholders.length; i++) {
      final p1 = getLessonPosition(i - 1, screenWidth, contentHeight);
      final p2 = getLessonPosition(i, screenWidth, contentHeight);
      
      // Control point for smooth sine-like curve between steps
      final midY = (p1.dy + p2.dy) / 2;
      path.quadraticBezierTo(p1.dx, midY, p2.dx, p2.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
