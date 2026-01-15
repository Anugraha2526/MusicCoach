import 'package:flutter/material.dart';

/// Moving notation widget for self-paced piano lessons
/// Features:
/// - "Sliding Paper" model: Clef, Time Signature, and Notes all move together
/// - Zero-gap continuous notation look
/// - Accurate Staff Lines & Bar Lines
class MovingNotationWidget extends StatelessWidget {
  final List<String> notes;
  final int currentNoteIndex;
  final String? wrongNote;
  final double scrollProgress;
  final String timeSignature; // New field

  const MovingNotationWidget({
    super.key,
    required this.notes,
    required this.currentNoteIndex,
    this.wrongNote,
    this.scrollProgress = 0.0,
    this.timeSignature = '4/4',
  });

  // Colors
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
      height: 200, 
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 0. Static Background Lines (Fills all gaps)
            Positioned.fill(
              child: CustomPaint(
                painter: ContinuousStaffPainter(),
              ),
            ),

            // 1. Moving Content (The "Paper")
            _buildMovingContent(),

            // 2. Static Overlay (Only the Target Line)
            _buildTargetLine(),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetLine() {
    return Stack(
      children: [
        // FIXED CLEF + TIME SIG (Static on the left)
        Positioned(
           left: 0,
           top: 0, 
           bottom: 0,
           width: 120, // Increased width for Clef + 4/4
           child: Container(
             color: Colors.white, 
             child: Stack(
               children: [
                 CustomPaint(size: Size.infinite, painter: ContinuousStaffPainter()),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Text('𝄞', style: TextStyle(fontSize: 64, color: Colors.black, height: 1)),
                     const SizedBox(width: 8),
                     _buildTimeSig(), // 4/4 now static
                   ],
                 ),
               ],
             ),
           ),
        ),

        // FIXED TARGET LINE
        Positioned(
          left: 220, // Moved right for better visibility winodw
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 4,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 4, spreadRadius: 2)
                ]
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovingContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dimensions
        const double noteWidth = 100.0;
        const double headerWidth = 60.0;
        const double targetX = 220.0; // Must match TargetLine position
        
        // Calculate Scroll Offset
        // Header is now 0 width in moving part since 4/4 is static
        final double baseOffset = targetX; 
        final double startScrollX = -1 * (currentNoteIndex + scrollProgress) * noteWidth;
        final double finalX = baseOffset + startScrollX;

        // Add huge padding to ensure lines never run out
        final double totalWidth = (notes.length * noteWidth) + 1200;

        // Use a Stack to contain the huge moving strip, but clip it to constraints
        return Stack(
          clipBehavior: Clip.hardEdge, 
          children: [
             Positioned(
               left: finalX,
               top: 0,
               bottom: 0,
               width: totalWidth,
               child: Stack(
                 children: [
                    // Continuous Staff Lines
                    Positioned.fill(
                       child: CustomPaint(
                         painter: ContinuousStaffPainter(),
                       ),
                    ),
                    
                    // Header + Notes Row
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           // Moving Header Removed (Made Static)
                           // Notes
                           
                           // Notes
                           ...List.generate(notes.length, (index) {
                             return SizedBox(
                               width: noteWidth,
                               height: constraints.maxHeight,
                               child: _buildMeasureItem(
                                 index: index, 
                                 note: notes[index], 
                                 isFirstInMeasure: index % 4 == 0
                               ),
                             );
                           }),
                           
                           // Ending Bar (Double Line)
                           _buildEndingBar(constraints.maxHeight),
                         ],
                      ),
                    ),
                 ],
               ),
             ),
          ],
        );
      },
    );
  }
  
  Widget _buildTimeSig() {
    // Parse "4/4", "3/4", etc.
    final parts = timeSignature.split('/');
    final top = parts.isNotEmpty ? parts[0] : '4';
    final bottom = parts.length > 1 ? parts[1] : '4';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
         Text(top, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1)),
         Text(bottom, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1)),
      ],
    );
  }

  Widget _buildEndingBar(double height) {
    return Container(
      width: 40,
      height: height,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 64, // Matches staff height
        child: Row(
          children: [
            Container(width: 2, color: Colors.black), // Thin line
            const SizedBox(width: 4),
            Container(width: 6, color: Colors.black), // Thick line
          ],
        ),
      ),
    );
  }

  Widget _buildMeasureItem({
     required int index, 
     required String note, 
     required bool isFirstInMeasure
  }) {
    // Note Positioning Logic
    final bool isCurrent = index == currentNoteIndex;
    final bool isPast = index < currentNoteIndex;
    final bool isWrong = isCurrent && wrongNote != null;
    
    // Vertical Offsets
    double yOffset = 0;
    
    switch (note) {
      case 'C': yOffset = 48; break; // Ledger removed
      case 'D': yOffset = 40; break;
      case 'E': yOffset = 32; break;
      case 'F': yOffset = 24; break;
      case 'G': yOffset = 16; break;
      case 'A': yOffset = 8; break;
      case 'B': yOffset = 0; break;
    }

    final color = isWrong 
        ? Colors.grey 
        : (noteColors[note] ?? Colors.black);
    
    return Stack(
      fit: StackFit.expand, // Force execution of children constraints
      children: [
        // Debug Container to ensure stack takes space
        Container(color: Colors.transparent),

        // Note Block
        if (note != '-')
          Center(
            child: Transform.translate(
               offset: Offset(0, yOffset),
               child: Container(
                 width: 100, // Reduced length as requested
                 height: 16, // Height matches staff spacing (16.0)
                 margin: EdgeInsets.zero,
                 decoration: BoxDecoration(
                   color: isPast ? color.withOpacity(0.5) : color, 
                   borderRadius: BorderRadius.circular(4),
                   border: isCurrent && !isWrong 
                      ? Border.all(color: Colors.white, width: 2) 
                      : null,
                 ),
                 child: Center(
                   child: Text(
                     note,
                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                   ),
                 ),
               ),
            ),
          ),

        // Bar Line (Align is safer than Positioned sometimes)
        if (isFirstInMeasure)
          Align(
             alignment: Alignment.centerLeft,
             child: Container(
               width: 4, 
               height: 64, // Matches exact staff height (4 spaces * 16px)
               color: Colors.black,
             ),
          ),
      ],
    );
  }
}

class ContinuousStaffPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 2.0;

    final center = size.height / 2; // 100
    const spacing = 16.0;
    
    // 5 Lines centered
    for (int i = -2; i <= 2; i++) {
        final y = center + (i * spacing);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
