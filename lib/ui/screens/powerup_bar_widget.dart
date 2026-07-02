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
          // 1. Hammer Power-Up
          _boosterButton(
            Icons.gavel, 
            () => gameManager.preparePowerUp('hammer'), 
            Colors.brown,
            gameManager.powerUpCounts['hammer'] ?? 0,
          ),
          // 2. Arrow Power-Up (Horizontal)
          _boosterButton(
            Icons.arrow_forward, 
            () => gameManager.preparePowerUp('arrow'), 
            Colors.blue,
            gameManager.powerUpCounts['arrow'] ?? 0,
          ),
          // 3. Cannon Power-Up (Vertical)
          _boosterButton(
            Icons.swap_vert, 
            () => gameManager.preparePowerUp('cannon'), 
            Colors.red,
            gameManager.powerUpCounts['cannon'] ?? 0,
          ),
          // 4. Jester Hat Power-Up (Instant Use)
          _boosterButton(
            Icons.face, 
            () async { 
              // Jester triggers immediately without waiting for a tile selection.
              if (gameManager.powerUpCounts['jester']! > 0) {
                gameManager.consumePowerUp('jester'); 
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

  // Power-up button UI with inventory badge.
  Widget _boosterButton(IconData icon, VoidCallback onPressed, Color color, int count) {
    bool hasUses = count > 0;

    return GestureDetector(
      onTap: hasUses ? onPressed : null, // Disable tap if inventory is empty.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main button icon (dims to 40% opacity if depleted).
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
          // Inventory count badge (top right).
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