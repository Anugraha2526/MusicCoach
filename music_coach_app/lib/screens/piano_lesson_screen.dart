import 'package:flutter/material.dart';
import 'dart:math' as math;

class PianoLessonScreen extends StatefulWidget {
  const PianoLessonScreen({super.key});

  @override
  State<PianoLessonScreen> createState() => _PianoLessonScreenState();
}

class _PianoLessonScreenState extends State<PianoLessonScreen>
    with TickerProviderStateMixin {
  int? selectedLessonIndex;
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, AnimationController> _pulseControllers = {};
  // Initialize with a very large offset to start at the bottom (Level 1 & 2)
  // The actual maxScrollExtent will clamp this value automatically
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 100000);

  // Piano color
  final Color _pianoColor = const Color(0xFF00B4D8);

  // Generate all lessons in order (Level 1 first, going up to Level 10)
  List<Lesson> get _allLessons {
    final lessons = <Lesson>[];
    for (int level = 1; level <= 10; level++) {
      for (int lessonIndex = 0; lessonIndex < 5; lessonIndex++) {
        lessons.add(Lesson(
          id: (level - 1) * 5 + lessonIndex + 1,
          level: level,
          index: lessonIndex,
        ));
      }
    }
    return lessons; // Level 1 is first in list, will be positioned at bottom
  }

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers for all lessons
    for (var lesson in _allLessons) {
      _animationControllers[lesson.id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _pulseControllers[lesson.id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    for (var controller in _pulseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onLessonTap(int lessonId) {
    setState(() {
      if (selectedLessonIndex == lessonId) {
        // If clicked again, navigate to lesson detail (leave for now)
        // Navigator.pushNamed(context, '/lesson-detail', arguments: lessonId);
      } else {
        // Deselect previous lesson
        if (selectedLessonIndex != null) {
          _animationControllers[selectedLessonIndex]?.reverse();
          _pulseControllers[selectedLessonIndex]?.stop();
          _pulseControllers[selectedLessonIndex]?.reset();
        }
        // Select new lesson
        selectedLessonIndex = lessonId;
        _animationControllers[lessonId]?.forward();
        _pulseControllers[lessonId]?.repeat();
      }
    });
  }

  // Calculate position for a lesson along the curved path
  // Each level curves independently, alternating left/right
  Offset _getLessonPosition(int lessonIndex, double screenWidth, double contentHeight) {
    final lesson = _allLessons[lessonIndex];
    final level = lesson.level;
    final lessonInLevel = lesson.index; // 0-4 within the level
    
    // Vertical position (Level 1 at bottom, goes up)
    final verticalSpacing = 120.0;
    final bottomPadding = 50.0;
    final levelSpacing = 5 * verticalSpacing; // Space for 5 lessons per level
    final levelStartY = contentHeight - bottomPadding - ((level - 1) * levelSpacing);
    final y = levelStartY - (lessonInLevel * verticalSpacing);
    
    // Horizontal position - curve within each level
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

  // Get level label position (separate line above the level's first lesson)
  double _getLevelLabelY(int level, double contentHeight) {
    final verticalSpacing = 120.0;
    final bottomPadding = 50.0;
    final levelSpacing = 5 * verticalSpacing;
    final levelStartY = contentHeight - bottomPadding - ((level - 1) * levelSpacing);
    // Position label above the first lesson in the level
    return levelStartY + 40; // Above the first lesson
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final lessons = _allLessons;

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
          final contentHeight = lessons.length * 120.0 + 200; // Extra space for level labels
          return SingleChildScrollView(
            controller: _scrollController,
            reverse: false,
            child: SizedBox(
              height: contentHeight,
              child: Stack(
                children: [
                  // Level labels (on separate lines with borders)
                  ...List.generate(10, (levelIndex) {
                    final level = levelIndex + 1;
                    final labelY = _getLevelLabelY(level, contentHeight);
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: labelY,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Level $level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Lesson buttons
                  ...lessons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final lesson = entry.value;
                    final position = _getLessonPosition(index, screenWidth, contentHeight);
                    
                    return Positioned(
                      left: position.dx - 40,
                      top: position.dy - 40,
                      child: _AnimatedLessonButton(
                        lesson: lesson,
                        pianoColor: _pianoColor,
                        isSelected: selectedLessonIndex == lesson.id,
                        liftController: _animationControllers[lesson.id],
                        pulseController: _pulseControllers[lesson.id],
                        onTap: () => _onLessonTap(lesson.id),
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

class Lesson {
  final int id;
  final int level;
  final int index;

  Lesson({required this.id, required this.level, required this.index});
}

class _AnimatedLessonButton extends StatelessWidget {
  final Lesson lesson;
  final Color pianoColor;
  final bool isSelected;
  final AnimationController? liftController;
  final AnimationController? pulseController;
  final VoidCallback onTap;

  const _AnimatedLessonButton({
    required this.lesson,
    required this.pianoColor,
    required this.isSelected,
    required this.liftController,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final liftAnimation = liftController != null
        ? Tween<double>(begin: 0.0, end: -15.0).animate(
            CurvedAnimation(
              parent: liftController!,
              curve: Curves.easeOut,
            ),
          )
        : AlwaysStoppedAnimation<double>(0.0);

    return AnimatedBuilder(
      animation: liftAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, liftAnimation.value),
          child: pulseController != null && isSelected
              ? AnimatedBuilder(
                  animation: pulseController!,
                  builder: (context, child) {
                    final pulseValue = pulseController!.value * 2 * math.pi;
                    final pulseRadius = 30.0 + (math.sin(pulseValue) * 10.0);

                    return _buildLessonButton(pulseRadius);
                  },
                )
              : _buildLessonButton(0.0),
        );
      },
    );
  }

  Widget _buildLessonButton(double pulseRadius) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing circle animation
          if (isSelected && pulseRadius > 0)
            Container(
              width: 80 + pulseRadius,
              height: 80 + pulseRadius,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: pianoColor.withOpacity(0.6 - (pulseRadius / 50) * 0.3),
                  width: 3,
                ),
              ),
            ),
          // Main lesson button
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected ? pianoColor.withOpacity(0.9) : pianoColor,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: pianoColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
