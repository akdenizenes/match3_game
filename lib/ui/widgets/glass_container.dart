import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        // Slightly stronger blur so objects behind dissolve more softly.
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            // Near-black anthracite fill at 0.8 opacity.
            color: const Color(0xFF12121A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            // Barely-visible border at 2% opacity.
            border: Border.all(color: Colors.white.withOpacity(0.02), width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}