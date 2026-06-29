import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';
import '../widgets/animated_board.dart';
import '../widgets/glass_container.dart';

// --- BÖLDÜĞÜMÜZ YENİ DOSYALARI ÇAĞIRIYORUZ ---
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

// İŞTE KAZAYLA SİLİNEN O SINIF BURASIYDI:
class GameScreenContent extends StatefulWidget {
  const GameScreenContent({super.key});

  @override
  State<GameScreenContent> createState() => _GameScreenContentState();
}

class _GameScreenContentState extends State<GameScreenContent> {
  final GameManager gameManager = GameManager();
  
  // YENİ SİGORTA: Ekranda halihazırda bir kutu var mı?
  bool isDialogShowing = false; 

  @override
  void initState() {
    super.initState();
    gameManager.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted) return;
    setState(() {});

    // Oyun oynanıyorsa (yeni bölüme geçildiyse) sigortayı aç
    if (gameManager.gameState == GameState.playing) {
      isDialogShowing = false;
    }

    // EĞER KUTU YOKSA VE OYUN BİTTİYSE: (Sadece 1 kez çalışır)
    if (!isDialogShowing) {
      if (gameManager.gameState == GameState.won) {
        isDialogShowing = true; // Kapıyı kilitle
        _showEndDialog(true);
      } else if (gameManager.gameState == GameState.lost) {
        isDialogShowing = true; // Kapıyı kilitle
        _showEndDialog(false);
      }
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
              Navigator.pop(dialogContext); // Kutu kilidini çözer
              if (won) gameManager.nextLevel(); else gameManager.retryLevel();
            },
            child: Text(won ? "SONRAKİ BÖLÜM" : "TEKRAR DENE", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}