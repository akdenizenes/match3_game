import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';
import '../widgets/animated_board.dart';
import '../widgets/glass_container.dart';
import '../widgets/particle_system.dart'; 

import 'top_bar_widget.dart';
import 'objective_bar_widget.dart';
import 'powerup_bar_widget.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameScreenContent();
  }
}

class GameScreenContent extends StatefulWidget {
  const GameScreenContent({super.key});

  @override
  State<GameScreenContent> createState() => _GameScreenContentState();
}

class _GameScreenContentState extends State<GameScreenContent> {
  final GameManager gameManager = GameManager();
  bool isDialogShowing = false; 

  bool showParticles = false;
  List<Offset> explosionPositions = [];

  @override
  void initState() {
    super.initState();
    gameManager.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted) return;

    _checkForExplosions();

    setState(() {});

    if (gameManager.gameState == GameState.playing) {
      isDialogShowing = false;
    }

    if (!isDialogShowing) {
      if (gameManager.gameState == GameState.won) {
        isDialogShowing = true;
        _showEndDialog(true);
      } else if (gameManager.gameState == GameState.lost) {
        isDialogShowing = true;
        _showEndDialog(false);
      }
    }
  }

  void _checkForExplosions() {
    if (gameManager.cells.isEmpty) return;
    List<Offset> newPositions = [];
    final double tileSize = MediaQuery.of(context).size.width * 0.8 / 8;

    for (int r = 0; r < gameManager.rows; r++) {
      for (int c = 0; c < gameManager.cols; c++) {
        final tile = gameManager.cells[r][c].tile;   // ← changed line
        if (tile != null && tile.isExploding) {
          newPositions.add(
            Offset(c * tileSize + tileSize / 2, r * tileSize + tileSize / 2),
          );
        }
      }
    }

    if (newPositions.isNotEmpty) {
      setState(() {
        explosionPositions = newPositions;
        showParticles = true;
      });
    }
  }

  @override
  void dispose() {
    gameManager.removeListener(_onStateChange);
    gameManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Softer, matte slate and navy tones instead of very harsh blacks
            colors: [Color(0xFF1C1C28), Color(0xFF232334), Color(0xFF2A2A3E)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack( 
            children: [
              Column(
                children: [
                  TopBarWidget(gameManager: gameManager),
                  ObjectiveBarWidget(gameManager: gameManager),
                  PowerUpBarWidget(gameManager: gameManager),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GlassContainer(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AnimatedBoard(gameManager: gameManager),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (showParticles)
                Positioned.fill(
                  child: ParticleSystem(
                    explosionPositions: explosionPositions,
                    // Pulled the neon colors of the explosion effects toward matte pastel tones
                    colors: [
                      Colors.purple.shade300, 
                      Colors.orange.shade300, 
                      const Color(0xFF4DB6AC), // Matte turquoise instead of neon cyan
                      Colors.pink.shade300
                    ],
                    onFinished: () => setState(() => showParticles = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        // Matte anthracite matching the main theme instead of pure black/dark purple for the dialog background
        backgroundColor: const Color(0xFF2A2A35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(
            // Easy-on-the-eyes matte turquoise and soft red/pink instead of neon cyan and neon pink
            color: won ? const Color(0xFF4DB6AC) : const Color(0xFFE57373)
          )
        ),
        title: Text(
          won ? "KAZANDIN! 🚀" : "ELENDİN! 💥", 
          textAlign: TextAlign.center, 
          // Matte white with reduced opacity instead of pure white
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold)
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Button backgrounds pulled toward the same soft colors
              backgroundColor: won ? const Color(0xFF4DB6AC) : const Color(0xFFE57373)
            ),
            onPressed: () {
              Navigator.pop(dialogContext); 
              if (won) gameManager.nextLevel(); else gameManager.retryLevel();
            },
            child: Text(
              won ? "SONRAKİ BÖLÜM" : "TEKRAR DENE", 
              // Button text in the dark navy of the main background instead of pure black
              style: const TextStyle(color: Color(0xFF1C1C28), fontWeight: FontWeight.bold)
            ),
          )
        ],
      ),
    );
  }
}