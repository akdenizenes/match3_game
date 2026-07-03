import 'package:flutter/material.dart';
import 'dart:math';

class Particle {
  double x, y, dx, dy, opacity;
  Color color;
  Particle(this.x, this.y, this.dx, this.dy, this.color, this.opacity);
}

class ParticleSystem extends StatefulWidget {
  final List<Offset> explosionPositions;
  final List<Color> colors;
  final VoidCallback onFinished;

  const ParticleSystem({super.key, required this.explosionPositions, required this.colors, required this.onFinished});

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    final random = Random();
    // Create 5-8 particles per explosion point
    for (var pos in widget.explosionPositions) {
      for (int i = 0; i < 6; i++) {
        particles.add(Particle(
          pos.dx, pos.dy,
          (random.nextDouble() - 0.5) * 8, // Random velocity X
          (random.nextDouble() - 0.5) * 8, // Random velocity Y
          widget.colors[random.nextInt(widget.colors.length)],
          1.0
        ));
      }
    }

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..addListener(() {
        setState(() {
          for (var p in particles) {
            p.x += p.dx;
            p.y += p.dy;
            p.opacity -= 0.02; // Fade out
          }
        });
      })
      ..addStatusListener((status) { if (status == AnimationStatus.completed) widget.onFinished(); })
      ..forward();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: ParticlePainter(particles));
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter(this.particles);
  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), 4.0, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}