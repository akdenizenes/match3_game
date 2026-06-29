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

    // Eğer ne taş hedefi ne de skor hedefi varsa barı gizle
    if (targets == null && scoreTarget == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. TAŞ HEDEFLERİ
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
                            decoration: BoxDecoration(color: _getObjectiveColor(e.key), shape: BoxShape.circle),
                            child: done ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                          ),
                          const SizedBox(width: 6),
                          Text("$collected/${e.value}", 
                               style: TextStyle(color: done ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              // 2. SKOR HEDEFİ (Yeni Eklenen)
              if (scoreTarget != null) ...[
                const SizedBox(height: 8),
                Text(
                  "HEDEF SKOR: ${gameManager.score} / $scoreTarget",
                  style: TextStyle(
                    fontSize: 14,
                    color: gameManager.score >= scoreTarget ? Colors.greenAccent : Colors.orangeAccent,
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
      case TileColor.purple: return const Color(0xFFB14DFF);
      case TileColor.orange: return const Color(0xFFFF6B00);
      case TileColor.yellow: return const Color(0xFFFFD700);
      case TileColor.cyan:   return const Color(0xFF00FFFF);
      case TileColor.pink:   return const Color(0xFFFF007F);
      case TileColor.green:  return const Color(0xFF00FF66);
    }
  }
}