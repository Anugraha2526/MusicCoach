import 'package:flutter/material.dart';
import 'colored_piano_keyboard.dart';

class PianoKeyboard extends StatelessWidget {
  final String? highlightedKey; // Key that should light up (e.g., 'C')
  final Function(String) onNoteDown; // Callback when key pressed
  final Function(String) onNoteUp;   // Callback when key released
  final Function(String, String)? onNoteDrop; // Callback when note dropped (targetKey, droppedNote)
  final bool showLabels;
  final bool showQuestionMarks; // If true, labels are '?' (for Identify mode)
  final List<String> visibleNotes; // Which keys to show
  final Set<String> identifiedNotes; // Notes correctly dropped in Identify mode
  final Set<String> targetNotes; // Only these keys show the '?' circle in identify mode

  const PianoKeyboard({
    super.key,
    this.highlightedKey,
    required this.onNoteDown,
    required this.onNoteUp,
    this.onNoteDrop,
    this.showLabels = true,
    this.showQuestionMarks = false,
    this.visibleNotes = const ['C', 'D', 'E'],
    this.identifiedNotes = const {},
    this.targetNotes = const {},
  });

  @override
  Widget build(BuildContext context) {
    // 3 keys side-by-side
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final whiteKeyCount = visibleNotes.length;
        if (whiteKeyCount == 0) return const SizedBox();

        final whiteKeyWidth = (totalWidth / whiteKeyCount) - 4; // -4 for margins
        final blackKeyWidth = whiteKeyWidth * 0.55; 
        final blackKeyHeight = constraints.maxHeight * 0.45;

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
            ...visibleNotes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              
              if (index >= visibleNotes.length - 1) return const SizedBox.shrink();

              if (_shouldHaveBlackKeyAfter(note)) {
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
    return ['C', 'D', 'F', 'G', 'A'].contains(note);
  }

  Widget _buildWhiteKey(String note, double width) {
    final isIdentified = identifiedNotes.contains(note);
    final isTarget = targetNotes.isEmpty || targetNotes.contains(note);
    final showCircle = showQuestionMarks && isTarget;
    
    // In Identify mode (showQuestionMarks), only show labels for identified target notes,
    // show '?' for unidentified targets, and show nothing for non-targets.
    String label;
    if (showQuestionMarks) {
      if (isTarget) {
        label = isIdentified ? note : '?';
      } else {
        label = ''; // Hide labels for non-target keys
      }
    } else {
      label = showLabels ? note : '';
    }
    
    final isPressed = highlightedKey == note;
    final noteColor = ColoredPianoKeyboard.noteColors[note];
    
    return _WhiteKey(
      label: label,
      width: width,
      isPressed: isPressed,
      isIdentified: isIdentified,
      identifiedColor: isIdentified ? noteColor : null,
      onTapDown: () => onNoteDown(note),
      onTapUp: () => onNoteUp(note),
      showQuestionMarkCircle: showCircle,
      onAcceptDrop: onNoteDrop != null ? (dropped) => onNoteDrop!(note, dropped) : null,
    );
  }
}

class _WhiteKey extends StatefulWidget {
  final String label;
  final double width;
  final bool isPressed;
  final bool isIdentified;
  final Color? identifiedColor; // Key fill color after correct identification
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final bool showQuestionMarkCircle;
  final Function(String)? onAcceptDrop;

  const _WhiteKey({
    required this.label,
    required this.width,
    required this.isPressed,
    this.isIdentified = false,
    this.identifiedColor,
    required this.onTapDown,
    required this.onTapUp,
    this.showQuestionMarkCircle = false,
    this.onAcceptDrop,
  });

  @override
  State<_WhiteKey> createState() => _WhiteKeyState();
}

class _WhiteKeyState extends State<_WhiteKey> {
  bool _isTouchPressed = false;

  void _handleTapDown() {
    setState(() => _isTouchPressed = true);
    widget.onTapDown();
  }

  void _handleTapUp() {
    setState(() => _isTouchPressed = false);
    widget.onTapUp();
  }

  @override
  Widget build(BuildContext context) {
    // Puzzle piece size for Identify mode: 48x48 circle 
    final circleSize = 48.0;
    final bool effectiveIsPressed = widget.isPressed || _isTouchPressed;

    Widget keyContent = widget.showQuestionMarkCircle 
          ? Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isIdentified 
                      ? (widget.identifiedColor ?? const Color(0xFF4FA2FF))
                      : Colors.black12, 
                  width: 2, 
                  style: BorderStyle.solid
                ),
                color: widget.isIdentified 
                    ? (widget.identifiedColor ?? const Color(0xFF4FA2FF))
                    : Colors.white,
                boxShadow: widget.isIdentified ? [
                  BoxShadow(
                    color: (widget.identifiedColor ?? const Color(0xFF4FA2FF)).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 1)
                ]
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isIdentified ? Colors.white : Colors.black45,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Text(
              widget.label,
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            );

    Widget container = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: double.infinity,
        margin: EdgeInsets.only(
          left: 2, 
          right: 2, 
          top: effectiveIsPressed ? 4 : 0, 
        ),
        decoration: BoxDecoration(
          color: widget.isIdentified && widget.identifiedColor != null
              ? widget.identifiedColor!
              : Colors.white,
          border: Border.all(
            color: widget.isIdentified && widget.identifiedColor != null
                ? widget.identifiedColor!.withOpacity(0.7)
                : Colors.black.withOpacity(0.08),
            width: 1
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          gradient: widget.isIdentified && widget.identifiedColor != null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [widget.identifiedColor!.withOpacity(0.7), widget.identifiedColor!],
              )
            : effectiveIsPressed 
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                ),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(effectiveIsPressed ? 0.02 : 0.12),
                offset: Offset(0, effectiveIsPressed ? 2 : 8),
                blurRadius: effectiveIsPressed ? 2 : 10,
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
            
            // Bottom Highlight Indicator (Blue line)
            if (widget.isPressed)
              Container(
                width: widget.width * 0.75,
                height: 8,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FA2FF),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FA2FF).withOpacity(0.6), 
                      blurRadius: 12, 
                      spreadRadius: 2
                    )
                  ]
                ),
              ),
          ],
        ),
    );

    if (widget.onAcceptDrop != null) {
      return DragTarget<String>(
        onWillAccept: (data) => true,
        onAccept: (data) => widget.onAcceptDrop!(data),
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(),
            onTapCancel: _handleTapUp,
            child: container,
          );
        },
      );
    }

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapUp,
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            offset: const Offset(0, 6),
            blurRadius: 8,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF444444), Color(0xFF0A0A0A)],
        ),
      ),
    );
  }
}
