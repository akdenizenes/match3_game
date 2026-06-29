import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';
import '../widgets/glass_container.dart'; // Kendi klasör yoluna göre ayarla

class TopBarWidget extends StatelessWidget {
  final GameManager gameManager;
  const TopBarWidget({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SKOR\n${gameManager.score}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("BÖLÜM ${gameManager.currentLevel.levelNumber}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF00FFFF))),
              Text("HAMLE\n${gameManager.moves}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}