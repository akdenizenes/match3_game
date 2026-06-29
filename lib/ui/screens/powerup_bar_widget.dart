import 'package:flutter/material.dart';
import '../../managers/game_manager.dart';

class PowerUpBarWidget extends StatelessWidget {
  final GameManager gameManager;
  const PowerUpBarWidget({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
       // --- powerup_bar_widget.dart İçindeki Butonlar ---
        children: [
          _boosterButton(Icons.gavel, () => gameManager.preparePowerUp('hammer'), Colors.brown),
          _boosterButton(Icons.arrow_forward, () => gameManager.preparePowerUp('arrow'), Colors.blue),
          _boosterButton(Icons.blur_on, () => gameManager.preparePowerUp('cannon'), Colors.red),
          
          // YENİ HALİ: Soytarı şapkası artık hedef seçmeyi BEKLEMEZ, direkt motoru ateşler!
          _boosterButton(Icons.face, () async {
            await gameManager.useJesterHat();
          }, Colors.purple),
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
}