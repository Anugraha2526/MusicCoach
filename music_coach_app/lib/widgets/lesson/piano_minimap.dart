import 'package:flutter/material.dart';

class PianoRangeMinimap extends StatelessWidget {
  final bool highlightMiddle;
  final String? pressedNote;
  final Color? pressedNoteColor;

  const PianoRangeMinimap({
    super.key, 
    this.highlightMiddle = true,
    this.pressedNote,
    this.pressedNoteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: SizedBox(
          width: 300, 
          child: Row(
            children: [
              _buildOctave(context, isHighlighted: false),
              const SizedBox(width: 4),
              _buildOctave(context, isHighlighted: highlightMiddle),
              const SizedBox(width: 4),
              _buildOctave(context, isHighlighted: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOctave(BuildContext context, {bool isHighlighted = false}) {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFF334155) : const Color(0xFF1E293B),
          border: isHighlighted 
              ? Border.all(color: const Color(0xFF4FA2FF), width: 1.5)
              : Border.all(color: Colors.white10, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // White keys dividers
            Row(
              children: List.generate(7, (index) {
                final noteNames = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
                final isThisNotePressed = isHighlighted && pressedNote == noteNames[index];

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      color: isThisNotePressed && pressedNoteColor != null 
                          ? pressedNoteColor!
                          : isHighlighted ? Colors.white.withOpacity(0.9) : Colors.white10,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(1)),
                    ),
                  ),
                );
              }),
            ),
            // Black keys bars
            Row(
              children: [
                // Gap, C#, D#, Gap, F#, G#, A#, Gap
                _buildBlackKeyPlaceholder(flex: 1), // C
                _buildBlackKeyBar(isHighlighted),  // C#
                _buildBlackKeyBar(isHighlighted),  // D#
                _buildBlackKeyPlaceholder(flex: 1), // E
                _buildBlackKeyPlaceholder(flex: 1), // F
                _buildBlackKeyBar(isHighlighted),  // F#
                _buildBlackKeyBar(isHighlighted),  // G#
                _buildBlackKeyBar(isHighlighted),  // A#
                _buildBlackKeyPlaceholder(flex: 1), // B
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlackKeyBar(bool isHighlighted) {
    return Expanded(
      flex: 1,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.black : Colors.white12,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(1)),
          ),
        ),
      ),
    );
  }

  Widget _buildBlackKeyPlaceholder({required int flex}) {
    return Expanded(flex: flex, child: const SizedBox());
  }
}
