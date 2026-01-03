import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/instrument_item.dart';

/// A reusable widget for displaying instrument images with automatic fallback.
/// 
/// This widget follows Flutter best practices for dynamic images:
/// - Uses cached_network_image for performance and offline support
/// - Falls back to local SVG assets if network image fails or is unavailable
/// - Shows loading placeholder while image loads
/// - Handles errors gracefully
class CachedInstrumentImage extends StatelessWidget {
  final InstrumentItem instrument;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? svgColor;

  const CachedInstrumentImage({
    super.key,
    required this.instrument,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.contain,
    this.svgColor,
  });

  @override
  Widget build(BuildContext context) {
    // If imageUrl from database exists and is not empty, use cached network image
    if (instrument.imageUrl != null && instrument.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: instrument.imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => SizedBox(
          width: width,
          height: height,
          child: Center(
            child: CircularProgressIndicator(
              color: svgColor ?? Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          // Fallback to local SVG if network image fails
          return _buildSvgFallback();
        },
        // Cache configuration
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 200,
        maxHeightDiskCache: 200,
      );
    } else {
      // Use local SVG asset as fallback
      return _buildSvgFallback();
    }
  }

  Widget _buildSvgFallback() {
    return SvgPicture.asset(
      instrument.svgIcon,
      width: width,
      height: height,
      fit: fit,
      colorFilter: svgColor != null
          ? ColorFilter.mode(
              svgColor!,
              BlendMode.srcIn,
            )
          : const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
    );
  }
}

