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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Saf beyaz yerine %85 opaklıkla kırılmış mat beyaz
              Text(
                "SKOR\n${gameManager.score}", 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white.withOpacity(0.85)
                )
              ),
              
              // Neon cyan (0xFF00FFFF) yerine göz yormayan mat turkuaz (0xFF4DB6AC)
              Text(
                "BÖLÜM ${gameManager.currentLevel.levelNumber}", 
                textAlign: TextAlign.center, 
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w900, 
                  color: Color(0xFF4DB6AC) 
                )
              ),
              
              // Saf beyaz yerine %85 opaklıkla kırılmış mat beyaz
              Text(
                "HAMLE\n${gameManager.moves}", 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white.withOpacity(0.5)
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}