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
    // Staff height and line spacing
    const double staffHeight = 48.0; // 4 gaps between 5 lines
    const double lineSpacing = staffHeight / 4; // 12px per gap
    // Half of lineSpacing for note steps (each note step = half a line gap)
    const double noteStep = lineSpacing / 2; // 6px per note step

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: SizedBox(
        // height: staffHeight + 3 lines of space below + top padding
        height: staffHeight + (3 * lineSpacing) + 30, // 3 gaps = 3 * lineSpacing. 30 for padding/notes.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Staff Lines (5 horizontal lines spanning full width)
            ...List.generate(5, (i) {
              final y = 10.0 + i * lineSpacing; // 10px top padding (reduced from 20)
              return Positioned(
                left: 0,
                right: 0,
                top: y,
                child: Container(height: 1.5, color: Colors.black26),
              );
            }),

            // Treble Clef (left side)
            Positioned(
              left: 0,
              top: 16,
              child: Text(
                '𝄞',
                style: TextStyle(
                  fontSize: 36,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),

            // Time Signature
            Positioned(
              left: 32,
              top: 20,
              child: SizedBox(
                height: staffHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeSignature.split('/')[0],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      timeSignature.split('/')[1],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Notes area
            Positioned(
              left: 60,
              right: 8,
              top: 0,
              bottom: 0,
              child: Row(
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
                    staffTopPadding: 10.0,
                    lineSpacing: lineSpacing,
                    noteStep: noteStep,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColoredNoteOnStaff extends StatelessWidget {
  final String note;
  final bool isCompleted;
  final bool isCurrent;
  final double progress;
  final double staffTopPadding;
  final double lineSpacing;
  final double noteStep;

  const _ColoredNoteOnStaff({
    required this.note,
    required this.isCompleted,
    required this.isCurrent,
    required this.progress,
    required this.staffTopPadding,
    required this.lineSpacing,
    required this.noteStep,
  });

  @override
  Widget build(BuildContext context) {
    // Treble clef staff positions (bottom line = E4, line 1):
    // Line 5 (top):    F5   → staffTop + 0 * lineSpacing
    // Space 4:         E5   → staffTop + 0.5 * lineSpacing
    // Line 4:          D5   → staffTop + 1 * lineSpacing
    // Space 3:         C5   → staffTop + 1.5 * lineSpacing
    // Line 3:          B4   → staffTop + 2 * lineSpacing
    // Space 2:         A4   → staffTop + 2.5 * lineSpacing
    // Line 2:          G4   → staffTop + 3 * lineSpacing
    // Space 1:         F4   → staffTop + 3.5 * lineSpacing
    // Line 1 (bottom): E4   → staffTop + 4 * lineSpacing
    // Below line 1:    D4   → staffTop + 4.5 * lineSpacing
    // Ledger line:     C4   → staffTop + 5 * lineSpacing

    double noteY; // Center of the note
    bool needsLedgerLine = false;

    switch (note) {
      case 'C':
        noteY = staffTopPadding + 5 * lineSpacing; // Below staff, on ledger line
        needsLedgerLine = true;
        break;
      case 'D':
        noteY = staffTopPadding + 4.5 * lineSpacing; // Below bottom line
        break;
      case 'E':
        noteY = staffTopPadding + 4 * lineSpacing; // On bottom line (line 1)
        break;
      case 'F':
        noteY = staffTopPadding + 3.5 * lineSpacing; // First space
        break;
      case 'G':
        noteY = staffTopPadding + 3 * lineSpacing; // Line 2
        break;
      case 'A':
        noteY = staffTopPadding + 2.5 * lineSpacing; // Second space
        break;
      case 'B':
        noteY = staffTopPadding + 2 * lineSpacing; // Line 3
        break;
      default:
        noteY = staffTopPadding + 4 * lineSpacing;
    }

    final noteColor = ColoredNotationWidget.noteColors[note] ?? Colors.blue;
    const noteHeight = 18.0;
    const noteWidth = 42.0;

    return SizedBox(
      width: noteWidth + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ledger line for C4
          if (needsLedgerLine)
            Positioned(
              left: -4,
              right: -4,
              top: noteY - 0.75,
              child: Container(
                height: 1.5,
                color: Colors.black45,
              ),
            ),

          // Note Rectangle (colored bar)
          Positioned(
            left: 0,
            top: noteY - noteHeight / 2,
            child: Container(
              width: noteWidth,
              height: noteHeight,
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
                  // Filling bar
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
                        fontSize: 12,
                      ),
                    ),
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
