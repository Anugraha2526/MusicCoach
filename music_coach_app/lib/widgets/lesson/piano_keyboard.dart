import 'package:flutter/material.dart';

class PianoKeyboard extends StatelessWidget {
  final String? highlightedKey; // Key that should light up (e.g., 'C')
  final Function(String) onNoteDown; // Callback when key pressed
  final Function(String) onNoteUp;   // Callback when key released
  final Function(String, String)? onNoteDrop; // Callback when note dropped (targetKey, droppedNote)
  final bool showLabels;
  final bool showQuestionMarks; // If true, labels are '?' (for Identify mode)
  final Set<String> visibleKeys; // Which keys to show (default all ['C', 'D', 'E'])
  final Set<String> identifiedNotes; // Notes correctly dropped in Identify mode

  const PianoKeyboard({
    super.key,
    this.highlightedKey,
    required this.onNoteDown,
    required this.onNoteUp,
    this.onNoteDrop,
    this.showLabels = true,
    this.showQuestionMarks = false,
    this.visibleKeys = const {'C', 'D', 'E'},
    this.identifiedNotes = const {},
  });

  @override
  Widget build(BuildContext context) {
    // 3 keys side-by-side
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Account for margins: 3 keys * 4px margin (2-left, 2-right) = 12px
        final whiteKeyWidth = (totalWidth - 12) / 3; 
        final blackKeyWidth = whiteKeyWidth * 0.55; 
        final blackKeyHeight = constraints.maxHeight * 0.45;

        return Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: [
            // --- White Keys ---
            Row(
              children: [
                _buildWhiteKey('C', whiteKeyWidth),
                _buildWhiteKey('D', whiteKeyWidth, isMiddle: true),
                _buildWhiteKey('E', whiteKeyWidth),
              ],
            ),

            // --- Black Keys (Decorative) ---
            // C# between C and D
            Positioned(
              left: (whiteKeyWidth + 4) - (blackKeyWidth / 2),
              top: 0,
              child: _BlackKey(width: blackKeyWidth, height: blackKeyHeight),
            ),
            // D# between D and E
            Positioned(
              left: ((whiteKeyWidth + 4) * 2) - (blackKeyWidth / 2),
              top: 0,
              child: _BlackKey(width: blackKeyWidth, height: blackKeyHeight),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWhiteKey(String note, double width, {bool isMiddle = false}) {
    // If showQuestionMarks is true (Identify mode), only show '?' if NOT identified yet
    final isIdentified = identifiedNotes.contains(note);
    final label = showQuestionMarks 
        ? (isIdentified ? note : '?') 
        : (showLabels ? note : '');
    final isPressed = highlightedKey == note;
    
    return _WhiteKey(
      label: label,
      width: width,
      isPressed: isPressed,
      isIdentified: isIdentified,
      onTapDown: () => onNoteDown(note),
      onTapUp: () => onNoteUp(note),
      showQuestionMarkCircle: showQuestionMarks,
      onAcceptDrop: onNoteDrop != null ? (dropped) => onNoteDrop!(note, dropped) : null,
    );
  }
}

class _WhiteKey extends StatelessWidget {
  final String label;
  final double width;
  final bool isPressed;
  final bool isIdentified;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final bool showQuestionMarkCircle;
  final Function(String)? onAcceptDrop;

  const _WhiteKey({
    required this.label,
    required this.width,
    required this.isPressed,
    this.isIdentified = false,
    required this.onTapDown,
    required this.onTapUp,
    this.showQuestionMarkCircle = false,
    this.onAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    // Puzzle piece size for Identify mode: 48x48 circle 
    final circleSize = 48.0;

    Widget keyContent = showQuestionMarkCircle 
          ? Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isIdentified ? const Color(0xFF4FA2FF) : Colors.black12, 
                  width: 2, 
                  style: BorderStyle.solid
                ),
                color: isIdentified ? const Color(0xFFE0F2FE) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 1)
                ]
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isIdentified ? const Color(0xFF4FA2FF) : Colors.black45,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Text(
              label,
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            );

    Widget container = AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: width,
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isPressed ? const Color(0xFFF1F5F9) : Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(isPressed ? 0.05 : 0.1),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Content (Label or Circle)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: keyContent,
            ),
            
            // Bottom Highlight Indicator (User request)
            if (isPressed)
              Container(
                width: width * 0.6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FA2FF),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4FA2FF).withOpacity(0.5), blurRadius: 8, spreadRadius: 2)
                  ]
                ),
              ),
          ],
        ),
    );

    if (onAcceptDrop != null) {
      return DragTarget<String>(
        onWillAccept: (data) => true,
        onAccept: (data) => onAcceptDrop!(data),
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTapDown: (_) => onTapDown(),
            onTapUp: (_) => onTapUp(),
            onTapCancel: onTapUp,
            child: container,
          );
        },
      );
    }

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: container,
    );
  }
}

class _BlackKey extends StatelessWidget {
  final double width;
  final double height;

  const _BlackKey({
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
    );
  }
}
