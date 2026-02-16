import 'package:flutter/material.dart';

/// Colored notation widget that displays musical notation with color-coded notes
/// matching the piano keyboard. Reuses the same color scheme as ColoredPianoKeyboard.
class ColoredNotationWidget extends StatelessWidget {
  final List<String> notes;
  final int completedIndex; // How many notes have been played correctly
  final double currentProgress; // 0.0 to 1.0 for the active note bar
  final String timeSignature; // e.g., "4/4"

  const ColoredNotationWidget({
    super.key,
    required this.notes,
    required this.completedIndex,
    this.currentProgress = 0.0,
    this.timeSignature = '4/4',
  });

  // Color mapping - MUST match ColoredPianoKeyboard exactly
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Treble Clef
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text(
              '𝄞',
              style: TextStyle(fontSize: 48, color: Colors.black),
            ),
          ),

          // Time Signature
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeSignature.split('/')[0],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 0.9,
                  ),
                ),
                Container(
                  width: 20,
                  height: 1,
                  color: Colors.black26,
                ),
                Text(
                  timeSignature.split('/')[1],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),

          // Staff and Notes
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Staff Lines (5 lines)
                  SizedBox(
                    height: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        5,
                        (index) => Container(
                          height: 1.5,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ),

                  // Notes positioned on the staff
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(notes.length, (index) {
                      final note = notes[index];
                      final isCompleted = index < completedIndex;
                      final isCurrent = index == completedIndex;

                      return _ColoredNoteOnStaff(
                        note: note,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        progress: isCurrent
                            ? currentProgress
                            : (isCompleted ? 1.0 : 0.0),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColoredNoteOnStaff extends StatelessWidget {
  final String note;
  final bool isCompleted;
  final bool isCurrent;
  final double progress;

  const _ColoredNoteOnStaff({
    required this.note,
    required this.isCompleted,
    required this.isCurrent,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Treble Staff positions relative to middle:
    // E4 is on the bottom line (1st line)
    // D4 is just below the bottom line (in the space)
    // C4 is below that, with a ledger line

    double verticalOffset = 0;
    bool needsLedgerLine = false;

    switch (note) {
      case 'C':
        verticalOffset = 60;
        needsLedgerLine = true;
        break;
      case 'D':
        verticalOffset = 45;
        break;
      case 'E':
        verticalOffset = 30;
        break;
      case 'F':
        verticalOffset = 15;
        break;
      case 'G':
        verticalOffset = 0;
        break;
      case 'A':
        verticalOffset = -15;
        break;
      case 'B':
        verticalOffset = -30;
        break;
    }

    final noteColor = ColoredNotationWidget.noteColors[note] ?? Colors.blue;

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Ledger line for C4
              if (needsLedgerLine)
                Container(
                  width: 50,
                  height: 1.5,
                  color: Colors.black45,
                ),

              // Note Rectangle (Horizontal Bar) with color
              Container(
                width: 45,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isCurrent ? noteColor : noteColor.withOpacity(0.4),
                    width: isCurrent ? 2.5 : 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Filling Bar with note color
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: noteColor.withOpacity(isCurrent ? 0.9 : 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Note label
                    Center(
                      child: Text(
                        note,
                        style: TextStyle(
                          color: progress > 0.5
                              ? Colors.white
                              : noteColor.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
