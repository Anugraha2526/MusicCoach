import 'package:flutter/material.dart';
import 'colored_piano_keyboard.dart';

/// A full-screen staff where the user drags a circle vertically to find
/// the correct note position. The target line/space is highlighted.
class StaffPlaceWidget extends StatefulWidget {
  final String targetNote;
  final Color targetColor;
  final ValueChanged<String> onNoteChanged; // Called when circle snaps to a new note
  final VoidCallback onCorrectPlacement;    // Called when circle placed on correct note

  const StaffPlaceWidget({
    super.key,
    required this.targetNote,
    required this.targetColor,
    required this.onNoteChanged,
    required this.onCorrectPlacement,
  });

  @override
  State<StaffPlaceWidget> createState() => _StaffPlaceWidgetState();
}

class _StaffPlaceWidgetState extends State<StaffPlaceWidget> {
  // Notes from bottom to top on the staff
  static const List<String> staffNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  
  // Current snapped note index
  late int _currentNoteIndex;
  double _dragOffset = 0;
  bool _isPlaced = false;

  @override
  void initState() {
    super.initState();
    // Start the circle 2-3 steps away from the target so it's not obvious
    final targetIdx = staffNotes.indexOf(widget.targetNote);
    if (targetIdx >= 4) {
      _currentNoteIndex = targetIdx - 3; // Start below target
    } else {
      _currentNoteIndex = targetIdx + 3; // Start above target
    }
    _currentNoteIndex = _currentNoteIndex.clamp(0, staffNotes.length - 1);
  }

  // Get the Y position for a note index within the staff area
  double _noteY(int index, double staffTop, double noteStep) {
    // Index 0 = C (bottom, below staff), Index 6 = B (line 3)
    // Staff lines from bottom: E(2), G(4), B(6) — on lines
    // Staff spaces: F(3), A(5) — in spaces
    // Below staff: C(0) ledger, D(1) below line 1
    // noteStep = half the gap between lines
    // Bottom line (E) is at staffTop + 4*lineSpacing
    // Each note step goes up by noteStep
    
    // C = 10 steps down from top line (F5), at bottom + below
    // We measure from top: higher index = higher on the staff = lower Y
    final stepsFromBottom = index; // C=0, D=1, E=2, F=3, G=4, A=5, B=6
    // E is on line 1 (bottom): staffTop + 4*lineSpacing
    // Each step up = -noteStep
    // E is index 2, so index 0 (C) is 2 steps below E
    final ePos = staffTop + 4 * (noteStep * 2); // E position (line 1)
    return ePos - (stepsFromBottom - 2) * noteStep;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        
        // Adjust proportions based on the image
        // 1. Line spacing is smaller height wise
        const double lineSpacing = 30.0; 
        const double noteStep = lineSpacing / 2; // 15px per note step
        final staffHeight = 4 * lineSpacing; // 120px for 5 lines
        final staffTop = (totalHeight - staffHeight) / 2 - 20; // Moved slightly upside
        
        // Horizontal centering
        // To place the entire section in the exact middle, we center the content width
        final contentWidth = totalWidth > 450 ? 450.0 : totalWidth * 0.8;
        final sidePadding = (totalWidth - contentWidth) / 2;
        
        // Dashed circle area bounds
        const double circleAreaWidth = 90;
        // Shift dashed box to the right by about a treble clef width (approx 60-80px)
        final circleAreaLeft = (totalWidth / 2) - (circleAreaWidth / 2) + 70;
        
        // Calculate note positions
        final currentY = _noteY(_currentNoteIndex, staffTop, noteStep) + _dragOffset;
        final targetIndex = staffNotes.indexOf(widget.targetNote);

        return GestureDetector(
          onVerticalDragUpdate: _isPlaced ? null : (details) {
            setState(() {
              _dragOffset += details.delta.dy;
              
              // Snap to nearest note
              final rawY = _noteY(_currentNoteIndex, staffTop, noteStep) + _dragOffset;
              
              // Find closest note
              double minDist = double.infinity;
              int closestIndex = _currentNoteIndex;
              for (int i = 0; i < staffNotes.length; i++) {
                final noteYPos = _noteY(i, staffTop, noteStep);
                final dist = (rawY - noteYPos).abs();
                if (dist < minDist) {
                  minDist = dist;
                  closestIndex = i;
                }
              }
              
              if (closestIndex != _currentNoteIndex) {
                _currentNoteIndex = closestIndex;
                _dragOffset = 0;
                // No sound during drag — sound plays on finger lift
              }
              
              // Clamp drag offset
              _dragOffset = _dragOffset.clamp(-noteStep * 0.8, noteStep * 0.8);
            });
          },
          onVerticalDragEnd: _isPlaced ? null : (details) {
            setState(() {
              _dragOffset = 0;
            });
            // Play the note sound on finger lift
            widget.onNoteChanged(staffNotes[_currentNoteIndex]);
            // Check if correct
            if (_currentNoteIndex == targetIndex) {
              setState(() => _isPlaced = true);
              widget.onCorrectPlacement();
            }
          },
          child: Container(
            color: Colors.transparent, // Make entire area tappable
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // === Staff Lines (5 lines, full width) ===
                ...List.generate(5, (i) {
                  final y = staffTop + i * lineSpacing;
                  // Ensure staff lines end just right of the dashed box
                  final lineRight = totalWidth - (circleAreaLeft + circleAreaWidth + 20);
                  
                  return Positioned(
                    left: sidePadding,
                    right: lineRight,
                    top: y - 0.75,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                }),
                
                // === Highlight target (solid translucent box) ===
                if (targetIndex >= 0)
                  Positioned(
                    left: circleAreaLeft - 5,
                    width: circleAreaWidth + 10,
                    top: _noteY(targetIndex, staffTop, noteStep) - noteStep,
                    child: Container(
                      height: lineSpacing,
                      decoration: BoxDecoration(
                        color: widget.targetColor.withOpacity(0.2),
                      ),
                    ),
                  ),

                // === Target Line Marker inside dashed box ===
                if (targetIndex % 2 == 0) // It's on a line (E=2, G=4, B=6)
                  Positioned(
                    left: circleAreaLeft,
                    width: circleAreaWidth,
                    top: _noteY(targetIndex, staffTop, noteStep) - 1.0,
                    child: Container(
                      height: 2.0,
                      color: widget.targetColor,
                    ),
                  ),



                // === Ledger line for C ===
                Positioned(
                  left: circleAreaLeft - 10,
                  top: _noteY(0, staffTop, noteStep) - 0.75,
                  child: Container(
                    width: circleAreaWidth + 20,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),

                // === Treble Clef ===
                Positioned(
                  left: sidePadding + 20,
                  top: staffTop - 42 + lineSpacing, // Move down by one lineSpacing
                  child: const Text(
                    '𝄞',
                    style: TextStyle(
                      fontSize: 130, // Much larger to fill the staff height
                      color: Colors.white38,
                      height: 1.1,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),

                // === Note labels on right side ===
                ...staffNotes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final note = entry.value;
                  final y = _noteY(i, staffTop, noteStep);
                  final isTarget = i == targetIndex;
                  final noteColor = ColoredPianoKeyboard.noteColors[note] ?? Colors.white;
                  final labelsRightPadding = totalWidth - (circleAreaLeft + circleAreaWidth + 60);
                  
                  return Positioned(
                    right: labelsRightPadding > 0 ? labelsRightPadding : 10,
                    top: y - 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 1.5,
                          color: isTarget
                              ? widget.targetColor
                              : Colors.white.withOpacity(0.15),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note,
                          style: TextStyle(
                            color: isTarget
                                ? widget.targetColor
                                : Colors.white38,
                            fontSize: isTarget ? 14 : 11,
                            fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // === Dashed drop area ===
                Positioned(
                  left: circleAreaLeft,
                  top: staffTop - lineSpacing,
                  child: Container(
                    width: circleAreaWidth,
                    height: staffHeight + 2 * lineSpacing,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),

                // === Draggable Circle ===
                Positioned(
                  left: circleAreaLeft + (circleAreaWidth - 56) / 2,
                  top: currentY - 28,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPlaced
                          ? widget.targetColor
                          : const Color(0xFF383A4A),
                      border: Border.all(
                        color: _isPlaced
                            ? widget.targetColor
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isPlaced
                              ? widget.targetColor.withOpacity(0.4)
                              : Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: _isPlaced ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isPlaced
                          ? Text(
                              widget.targetNote,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Icon(
                              Icons.unfold_more,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
