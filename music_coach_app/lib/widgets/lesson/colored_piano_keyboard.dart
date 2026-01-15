import 'package:flutter/material.dart';

/// Colored piano keyboard that scales to any set of contiguous white keys.
/// Automatically places black keys based on standard piano layout.
class ColoredPianoKeyboard extends StatelessWidget {
  final String? highlightedKey;
  final Function(String) onNoteDown;
  final Function(String) onNoteUp;
  final String? currentNote; // The note that should be played
  final String? wrongNote; // If user played wrong note
  
  // The range of notes to display. Defaults to C, D, E for backward compatibility/current lesson.
  // In future, pass ['C', 'D', 'E', 'F', 'G', 'A', 'B'] etc.
  final List<String> visibleNotes;

  const ColoredPianoKeyboard({
    super.key,
    this.highlightedKey,
    required this.onNoteDown,
    required this.onNoteUp,
    this.currentNote,
    this.wrongNote,
    this.visibleNotes = const ['C', 'D', 'E'],
  });

  // Extended color mapping for full octave
  static const Map<String, Color> noteColors = {
    'C': Color(0xFF9333EA), // Purple
    'D': Color(0xFFF97316), // Orange
    'E': Color(0xFF10B981), // Green
    'F': Color(0xFFEF4444), // Red
    'G': Color(0xFF3B82F6), // Blue
    'A': Color(0xFFEAB308), // Yellow
    'B': Color(0xFFEC4899), // Pink
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Calculate key width based on number of visible keys
        // Subtract standard margin (2px per side per key roughly, or just fit to width)
        // Here we fit exactly to width with small internal margins
        final whiteKeyCount = visibleNotes.length;
        if (whiteKeyCount == 0) return const SizedBox();

        final whiteKeyWidth = (totalWidth / whiteKeyCount) - 4; // -4 for margins
        final blackKeyWidth = whiteKeyWidth * 0.6;
        final blackKeyHeight = constraints.maxHeight * 0.55;

        return Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: [
            // --- White Keys ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: visibleNotes.map((note) {
                 return _buildWhiteKey(note, whiteKeyWidth);
              }).toList(),
            ),

            // --- Black Keys ---
            // Dynamically place black keys based on piano rules
            // Rules: Black key follows C, D, F, G, A. No black key after E, B.
            ...visibleNotes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              
              // Don't draw black key if it's the last key (nothing to its right)
              if (index >= visibleNotes.length - 1) return const SizedBox.shrink();

              // Check if this note should have a black key to its right
              if (_shouldHaveBlackKeyAfter(note)) {
                // Calculate position: 
                // Right edge of this white key is: (index + 1) * (whiteKeyWidth + 4)
                // Center the black key on the boundary
                final leftPos = ((index + 1) * (whiteKeyWidth + 4)) - (blackKeyWidth / 2);
                
                return Positioned(
                  left: leftPos,
                  top: 0,
                  child: _BlackKey(width: blackKeyWidth, height: blackKeyHeight),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }

  bool _shouldHaveBlackKeyAfter(String note) {
    // Standard piano layout: C#, D#, F#, G#, A#
    // Notes that HAVE a black key after them: C, D, F, G, A
    // Notes that DO NOT: E, B
    return ['C', 'D', 'F', 'G', 'A'].contains(note);
  }

  Widget _buildWhiteKey(String note, double width) {
    final isPressed = highlightedKey == note;
    final keyColor = noteColors[note] ?? Colors.blue;

    return _ColoredWhiteKey(
      note: note,
      width: width,
      isPressed: isPressed,
      color: keyColor,
      onTapDown: () => onNoteDown(note),
      onTapUp: () => onNoteUp(note),
    );
  }
}

class _ColoredWhiteKey extends StatelessWidget {
  final String note;
  final double width;
  final bool isPressed;
  final Color color;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _ColoredWhiteKey({
    required this.note,
    required this.width,
    required this.isPressed,
    required this.color,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: width,
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2), // 2px margin each side = 4px total gap per key
        decoration: BoxDecoration(
          color: isPressed ? const Color(0xFFF1F5F9) : Colors.white,
          border: Border.all(
            color: Colors.black.withOpacity(0.1),
            width: 1,
          ),
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
            // Colored label at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                note,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Colored shadow highlight at bottom
            Container(
              width: width * 0.7,
              height: 8,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            // Pressed indicator (brighter when pressed)
            if (isPressed)
              Container(
                width: width * 0.7,
                height: 8,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
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
