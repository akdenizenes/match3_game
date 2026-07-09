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
        // Blur seviyesini bir tık artırarak arkadaki objelerin daha yumuşak dağılmasını sağladık
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
        child: Container(
        decoration: BoxDecoration(
            // Opaklığı 0.5'ten 0.8'e çıkardık, rengi tam antrasite (neredeyse siyah) çektik
            color: const Color(0xFF12121A).withOpacity(0.8), 
            borderRadius: BorderRadius.circular(24),
            // Çerçeve opaklığını %5'ten %2'ye düşürdük, zar zor belli olacak
            border: Border.all(color: Colors.white.withOpacity(0.02), width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}