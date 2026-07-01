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
        children: [
          // 1. Çekiç (Hammer)
          _boosterButton(
            Icons.gavel, 
            () => gameManager.preparePowerUp('hammer'), 
            Colors.brown,
            gameManager.powerUpCounts['hammer'] ?? 0,
          ),
          // 2. Yatay Ok (Arrow)
          _boosterButton(
            Icons.arrow_forward, 
            () => gameManager.preparePowerUp('arrow'), 
            Colors.blue,
            gameManager.powerUpCounts['arrow'] ?? 0,
          ),
          // 3. Dikey Ok (Cannon)
          _boosterButton(
            Icons.swap_vert, 
            () => gameManager.preparePowerUp('cannon'), 
            Colors.red,
            gameManager.powerUpCounts['cannon'] ?? 0,
          ),
          // 4. Soytarı Şapkası (Jester) - İŞTE BAHSETTİĞİM GÜNCELLEME BURADA
          _boosterButton(
            Icons.face, 
            () async { 
              // Soytarı için anında kullanıma izin ver
              if (gameManager.powerUpCounts['jester']! > 0) {
                gameManager.consumePowerUp('jester'); // Burada düşür
                await gameManager.useJesterHat();
              }
            }, 
            Colors.purple,
            gameManager.powerUpCounts['jester'] ?? 0,
          ),
        ],
      ),
    );
  }

  // Güçlendirici Butonu Tasarımı (Sayı Rozeti Eklenmiş Hali)
  Widget _boosterButton(IconData icon, VoidCallback onPressed, Color color, int count) {
    bool hasUses = count > 0;

    return GestureDetector(
      onTap: hasUses ? onPressed : null, // Sıfırsa tıklamayı tamamen kapat
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ana Buton (Hakkı bittiyse %40 saydamlaşır, sönük görünür)
          Opacity(
            opacity: hasUses ? 1.0 : 0.4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3), 
                shape: BoxShape.circle, 
                border: Border.all(color: color, width: 2)
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
          // Kalan Sayı Rozeti (Sağ üst köşedeki küçük yuvarlak)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 12
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}