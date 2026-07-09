import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';
import '../../models/tile.dart';
import '../widgets/glass_container.dart';

class ObjectiveBarWidget extends StatelessWidget {
  final GameManager gameManager;
  const ObjectiveBarWidget({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    final targets = gameManager.currentLevel.targetColors;
    final scoreTarget = gameManager.currentLevel.targetScore;

    if (targets == null && scoreTarget == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. TILE OBJECTIVES
              if (targets != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: targets.entries.map((e) {
                    int collected = gameManager.collectedColors[e.key] ?? 0;
                    bool done = collected >= e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: _getObjectiveColor(e.key), 
                              shape: BoxShape.circle
                            ),
                            // Saf siyah yerine koyu lacivert/antrasit tik işareti
                            child: done ? const Icon(Icons.check, size: 16, color: Color(0xFF1C1C28)) : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$collected/${e.value}", 
                            style: TextStyle(
                              // Tamamlandığında patlayan yeşil yerine mat/pastel bir yeşil, tamamlanmadığında soft beyaz
                              color: done ? const Color(0xFF81C784) : Colors.white.withOpacity(0.85), 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              // 2. SCORE OBJECTIVE
              if (scoreTarget != null) ...[
                const SizedBox(height: 8),
                Text(
                  "HEDEF SKOR: ${gameManager.score} / $scoreTarget",
                  style: TextStyle(
                    fontSize: 14,
                    // Neon yeşil ve turuncu yerine mat pastel yeşil ve soft turuncu
                    color: gameManager.score >= scoreTarget ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

Color _getObjectiveColor(TileColor color) {
    switch (color) {
      case TileColor.purple: return const Color(0xFF674EA7); 
      case TileColor.orange: return const Color(0xFFB4654A); 
      case TileColor.yellow: return const Color(0xFFA68A38); 
      case TileColor.cyan:   return const Color(0xFF337A75); 
      case TileColor.pink:   return const Color(0xFFA64D6E); 
      case TileColor.green:  return const Color(0xFF4C8053); 
    }
  }
}