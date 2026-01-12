import 'package:flutter/material.dart';

class NotationView extends StatelessWidget {
  final List<String> notes;
  final int completedIndex; // How many notes have been played correctly
  final double currentProgress; // 0.0 to 1.0 for the active note bar

  const NotationView({
    super.key,
    required this.notes,
    required this.completedIndex,
    this.currentProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Further reduced height
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Clef
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text('𝄞', style: TextStyle(fontSize: 40, color: Colors.black)),
          ),
          
          Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Staff Lines (5 lines)
                      SizedBox(
                        height: 50, // Total height of the 5-line staff
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (index) => Container(height: 1.5, color: Colors.black26)),
                        ),
                      ),
                      
                      // Notes positioned vertically on the staff
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(notes.length, (index) {
                          final note = notes[index];
                          final isCompleted = index < completedIndex;
                          final isCurrent = index == completedIndex;
                          
                          return _NoteOnStaff(
                            note: note,
                            isCompleted: isCompleted,
                            isCurrent: isCurrent,
                            progress: isCurrent ? currentProgress : (isCompleted ? 1.0 : 0.0),
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

class _NoteOnStaff extends StatelessWidget {
  final String note;
  final bool isCompleted;
  final bool isCurrent;
  final double progress;

  const _NoteOnStaff({
    required this.note,
    required this.isCompleted,
    required this.isCurrent,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Treble Staff positions relative to middle:
    // E4 is on the bottom line.
    // D4 is just below the bottom line.
    // C4 is below that, with a ledger line.
    
    double verticalOffset = 0;
    bool needsLedgerLine = false;

    switch (note) {
      case 'C': verticalOffset = 50; needsLedgerLine = true; break; 
      case 'D': verticalOffset = 37.5; break;
      case 'E': verticalOffset = 25; break;
      case 'F': verticalOffset = 12.5; break;
      case 'G': verticalOffset = 0; break;
    }

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
              
              // Note Block (Horizontal Bar)
              Container(
                width: 40,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isCurrent ? const Color(0xFF4FA2FF) : Colors.black26, 
                    width: isCurrent ? 2 : 1
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Filling Bar
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4FA2FF).withOpacity(isCurrent ? 1.0 : 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        note,
                        style: TextStyle(
                          color: progress > 0.5 ? Colors.white : Colors.black87,
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
