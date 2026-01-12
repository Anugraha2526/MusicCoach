import 'package:flutter/material.dart';

class DraggableNoteOption extends StatelessWidget {
  final String note;
  final bool isMatched; // If true, hide or show dimmed

  const DraggableNoteOption({
    super.key,
    required this.note,
    this.isMatched = false,
  });

    @override
  Widget build(BuildContext context) {
    // Standard size to match keyboard circle: 48.0
    final size = 48.0;

    if (isMatched) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
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
            color: const Color(0xFF4FA2FF),
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
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
