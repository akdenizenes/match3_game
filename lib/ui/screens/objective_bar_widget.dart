import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';
import '../../models/color_tile.dart';
import '../../models/tile_palette.dart'; // ← single color source
import '../widgets/glass_container.dart';

class ObjectiveBarWidget extends StatelessWidget {
  final GameManager gameManager;
  const ObjectiveBarWidget({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    final targets = gameManager.currentLevel.targetColors;
    final scoreTarget = gameManager.currentLevel.targetScore;
    final blockers = gameManager.remainingBlockers;

    if (targets == null && scoreTarget == null && blockers == 0) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. COLOR TARGETS
              if (targets != null)
                Wrap(
                  alignment: WrapAlignment.center,
                  children: targets.entries.map((e) {
                    final collected = gameManager.collectedColors[e.key] ?? 0;
                    final done = collected >= e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: e.key.main, // ← SAME color as the board
                              shape: BoxShape.circle,
                            ),
                            child: done
                                ? const Icon(Icons.check,
                                    size: 16, color: Color(0xFF1C1C28))
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$collected/${e.value}",
                            style: TextStyle(
                              color: done
                                  ? const Color(0xFF81C784)
                                  : Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              // 2. BLOCKER TARGET (clearing boxes / jelly / honey)
              if (blockers > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_view_rounded,
                        size: 18, color: Color(0xFF8D6E4A)),
                    const SizedBox(width: 6),
                    Text(
                      "KALAN ENGEL: $blockers",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              // 3. SCORE TARGET
              if (scoreTarget != null) ...[
                const SizedBox(height: 8),
                Text(
                  "HEDEF SKOR: ${gameManager.score} / $scoreTarget",
                  style: TextStyle(
                    fontSize: 14,
                    color: gameManager.score >= scoreTarget
                        ? const Color(0xFF81C784)
                        : const Color(0xFFFFB74D),
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
}