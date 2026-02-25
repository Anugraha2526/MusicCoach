import 'package:flutter/material.dart';
import 'colored_piano_keyboard.dart';

class DraggableNoteOption extends StatelessWidget {
  final String note;
  final bool isMatched; // If true, show colored fill

  const DraggableNoteOption({
    super.key,
    required this.note,
    this.isMatched = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = 48.0;
    final noteColor = ColoredPianoKeyboard.noteColors[note] ?? const Color(0xFF4FA2FF);

    if (isMatched) {
      // Filled with the note's color when correctly placed
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: noteColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: noteColor.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          note,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Draggable<String>(
      data: note,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: size + 4,
          height: size + 4,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: noteColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: Text(
            note,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
      ),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
          ],
        ),
        child: Text(
          note,
          style: TextStyle(
            color: noteColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
