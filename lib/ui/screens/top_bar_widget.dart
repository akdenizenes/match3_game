import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';
import '../widgets/glass_container.dart';

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
          // spaceBetween REMOVED → each item takes an equal 1/3 → the middle block is perfectly centered
          child: Row(
            children: [
              // LEFT: SCORE — left-aligned
              Expanded(
                child: Text(
                  "SKOR\n${gameManager.score}",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),

              // CENTER: LEVEL — always perfectly centered
              Expanded(
                child: Text(
                  "BÖLÜM ${gameManager.currentLevel.levelNumber}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4DB6AC),
                  ),
                ),
              ),

              // RIGHT: MOVES — right-aligned
              Expanded(
                child: Text(
                  "HAMLE\n${gameManager.moves}",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}