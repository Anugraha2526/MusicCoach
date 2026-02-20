import 'package:flutter/material.dart';
import 'dart:math' as math;

const List<String> _noteNames = ['E', 'A', 'D', 'G', 'B', 'E'];

class GuitarHeadstock extends StatelessWidget {
  final int? activeStringIndex;   // currently selected / highlighted
  final int? tunedStringIndex;
  final Function(int) onStringSelected;

  const GuitarHeadstock({
    super.key,
    this.activeStringIndex,
    this.tunedStringIndex,
    required this.onStringSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Original sizing
        final imgWidth = math.min(width, height * 0.5);
        final imgHeight = imgWidth * 2.0;
        final btnSize = imgWidth * 0.20;

        // Widen container so buttons at x=-0.25 and x=1.05 are inside hit-test bounds
        final totalWidth = imgWidth + btnSize * 2;
        final imgLeft = btnSize;
        final topOffset = math.max(0.0, (height - imgHeight) / 2);

        return SizedBox(
          width: totalWidth,
          height: height,
          child: Stack(
            children: [
              // Headstock image – non-interactive
              Positioned(
                left: imgLeft,
                top: topOffset,
                width: imgWidth,
                height: imgHeight,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/icons/guitar_tuner.png',
                    width: imgWidth,
                    height: imgHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Six string buttons
              ...List.generate(6, (index) {
                final isLeft = index < 3;

                double yFrac;
                if (index == 0 || index == 5) {
                  yFrac = 0.44;
                } else if (index == 1 || index == 4) {
                  yFrac = 0.285;
                } else {
                  yFrac = 0.13;
                }

                final double btnLeft = isLeft ? 0 : imgLeft + imgWidth - btnSize * 0.05;
                final double btnTop = topOffset + imgHeight * yFrac;

                final bool isSelected = activeStringIndex == index;
                final bool isTuned = tunedStringIndex == index;

                // Colors: inverted when selected, green when tuned, dark otherwise
                final Color bgColor = isTuned
                    ? Colors.green
                    : isSelected
                        ? Colors.white
                        : const Color(0xFF1A2B3C);
                final Color textColor = (isSelected && !isTuned)
                    ? Colors.black
                    : Colors.white;
                final Color borderColor = isTuned
                    ? Colors.green.shade300
                    : isSelected
                        ? Colors.white
                        : Colors.white30;

                return Positioned(
                  left: btnLeft,
                  top: btnTop,
                  width: btnSize,
                  height: btnSize,
                  child: GestureDetector(
                    onTap: () => onStringSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: btnSize,
                      height: btnSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _noteNames[index],
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 18 * (imgWidth / 300),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
