import 'package:flutter/material.dart';

/// Displays a row of circles representing notes to be tapped.
/// Each filled circle shows the note's color.
class NoteCirclesWidget extends StatelessWidget {
  final String note;
  final Color color;
  final int totalCount;
  final int filledCount;

  const NoteCirclesWidget({
    super.key,
    required this.note,
    required this.color,
    this.totalCount = 4,
    required this.filledCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalCount, (index) {
          final isFilled = index < filledCount;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? color : Colors.transparent,
              border: Border.all(
                color: isFilled ? color : color.withOpacity(0.4),
                width: isFilled ? 0 : 2.5,
              ),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                note,
                style: TextStyle(
                  color: isFilled ? Colors.white : color.withOpacity(0.7),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
