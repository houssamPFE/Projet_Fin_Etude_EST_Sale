import 'dart:ui';
import 'package:flutter/material.dart';

/// A blurred radial glow circle used as ambient background light.
class BlurOrb extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double sigma;

  const BlurOrb({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.sigma = 72,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
