import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';
import '../widgets/animated_board.dart';
import '../widgets/glass_container.dart';
import '../widgets/particle_system.dart'; // NEW: Import your particle system

// --- IMPORTED WIDGET COMPONENTS ---
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

  // NEW: Particle system state variables
  bool showParticles = false;
  List<Offset> explosionPositions = [];

  @override
  void initState() {
    super.initState();
    gameManager.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted) return;

    // NEW: Listen for explosions to trigger particles
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

  // NEW: Scans the board for tiles marked 'isExploding'
  void _checkForExplosions() {
    List<Offset> newPositions = [];
    // Assuming standard tile size calculation matches AnimatedBoard logic (maxWidth / cols)
    final double tileSize = MediaQuery.of(context).size.width * 0.8 / 8; // Approximated

    for (int r = 0; r < gameManager.rows; r++) {
      for (int c = 0; c < gameManager.cols; c++) {
        var tile = gameManager.board[r][c];
        if (tile != null && tile.isExploding) {
          // Add center position of exploding tile
          newPositions.add(Offset(c * tileSize + tileSize/2, r * tileSize + tileSize/2));
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
            colors: [Color(0xFF03030F), Color(0xFF0A0A26), Color(0xFF1B0A33)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack( // NEW: Stack allows particles to float over the board
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
              // NEW: Particle Overlay Layer
              if (showParticles)
                Positioned.fill(
                  child: ParticleSystem(
                    explosionPositions: explosionPositions,
                    colors: const [Colors.purple, Colors.orange, Colors.cyan, Colors.pink],
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
        backgroundColor: const Color(0xFF140726),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: won ? const Color(0xFF00FFFF) : const Color(0xFFFF007F))),
        title: Text(won ? "KAZANDIN! 🚀" : "ELENDİN! 💥", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: won ? const Color(0xFF00FFFF) : const Color(0xFFFF007F)),
            onPressed: () {
              Navigator.pop(dialogContext); 
              if (won) gameManager.nextLevel(); else gameManager.retryLevel();
            },
            child: Text(won ? "SONRAKİ BÖLÜM" : "TEKRAR DENE", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}