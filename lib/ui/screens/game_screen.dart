import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';
import '../../models/tile.dart';
import '../widgets/animated_board.dart';
import '../widgets/glass_container.dart';

// HATA BURADAYDI: StatefulWidget yerine StatelessWidget olması gerekiyordu, düzeltildi.
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

  @override
  void initState() {
    super.initState();
    gameManager.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted) return;
    setState(() {});

    if (gameManager.gameState == GameState.won) {
      _showEndDialog(true);
    } else if (gameManager.gameState == GameState.lost) {
      _showEndDialog(false);
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
          child: Column(
            children: [
              _buildTopScoreBar(),
              _buildObjectiveBar(),
              _buildBoosterBar(),
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
        ),
      ),
    );
  }
  // --- GÜÇLENDİRİCİLERİ EKRANA ÇİZEN METOTLAR ---
  Widget _buildBoosterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _boosterButton(Icons.gavel, () => gameManager.useRoyalHammer(0, 0), Colors.brown), // Çekiç
          _boosterButton(Icons.arrow_forward, () => gameManager.useArrowBooster(0), Colors.blue), // Ok
          _boosterButton(Icons.blur_on, () => gameManager.useCannonBooster(0), Colors.red), // Top
          _boosterButton(Icons.face, () => gameManager.useJesterHat(), Colors.purple), // Soytarı
        ],
      ),
    );
  }

  Widget _boosterButton(IconData icon, VoidCallback onPressed, Color color) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3), 
          shape: BoxShape.circle, 
          border: Border.all(color: color, width: 2)
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }


  Widget _buildTopScoreBar() {
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

  Widget _buildObjectiveBar() {
    final targets = gameManager.currentLevel.targetColors;
    if (targets == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: targets.entries.map((e) {
              int collected = gameManager.collectedColors[e.key] ?? 0;
              bool done = collected >= e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: _getObjectiveColor(e.key), shape: BoxShape.circle),
                      child: done ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                    ),
                    const SizedBox(width: 8),
                    Text("$collected / ${e.value}", style: TextStyle(color: done ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
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

  void _showEndDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF140726),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: won ? const Color(0xFF00FFFF) : const Color(0xFFFF007F))),
        title: Text(won ? "KAZANDIN! 🚀" : "ELENDİN! 💥", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: won ? const Color(0xFF00FFFF) : const Color(0xFFFF007F)),
            onPressed: () {
              Navigator.pop(context);
              if (won) gameManager.nextLevel(); else gameManager.retryLevel();
            },
            child: Text(won ? "SONRAKİ SEKTÖR" : "TEKRAR DENE", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}