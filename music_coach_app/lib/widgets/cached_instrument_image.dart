import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/instrument_item.dart';

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
        errorWidget: (context, url, error) => _buildSvgFallback(),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 200,
        maxHeightDiskCache: 200,
      );
    } else {
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

