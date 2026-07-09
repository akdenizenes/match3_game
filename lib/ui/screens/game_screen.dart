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
    List<Offset> newPositions = [];
    final double tileSize = MediaQuery.of(context).size.width * 0.8 / 8; 

    for (int r = 0; r < gameManager.rows; r++) {
      for (int c = 0; c < gameManager.cols; c++) {
        var tile = gameManager.board[r][c];
        if (tile != null && tile.isExploding) {
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
            // Çok sert siyahlar yerine daha soft, mat arduvaz ve lacivert tonları
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
                    // Patlama efektlerindeki neon renkleri mat pastel tonlara çektik
                    colors: [
                      Colors.purple.shade300, 
                      Colors.orange.shade300, 
                      const Color(0xFF4DB6AC), // Neon cyan yerine mat turkuaz
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
        // Dialog arkaplanı saf siyah/koyu mor yerine ana temaya uygun mat antrasit
        backgroundColor: const Color(0xFF2A2A35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(
            // Neon cyan ve neon pembe yerine göz yormayan mat turkuaz ve soft kırmızı/pembe
            color: won ? const Color(0xFF4DB6AC) : const Color(0xFFE57373)
          )
        ),
        title: Text(
          won ? "KAZANDIN! 🚀" : "ELENDİN! 💥", 
          textAlign: TextAlign.center, 
          // Saf beyaz yerine opaklığı kırılmış mat beyaz
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold)
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Buton arkaplanları da aynı soft renklere çekildi
              backgroundColor: won ? const Color(0xFF4DB6AC) : const Color(0xFFE57373)
            ),
            onPressed: () {
              Navigator.pop(dialogContext); 
              if (won) gameManager.nextLevel(); else gameManager.retryLevel();
            },
            child: Text(
              won ? "SONRAKİ BÖLÜM" : "TEKRAR DENE", 
              // Buton yazısı saf siyah yerine ana fonun koyu lacivert renginde
              style: const TextStyle(color: Color(0xFF1C1C28), fontWeight: FontWeight.bold)
            ),
          )
        ],
      ),
    );
  }
}