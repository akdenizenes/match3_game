import 'package:flutter/material.dart';
import '../../models/tile.dart';
import '../../managers/game_manager.dart';

class AnimatedBoard extends StatelessWidget {
  final GameManager gameManager;
  const AnimatedBoard({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    // Liste boşken çizim tetiklenirse oluşacak RangeError hatasını önler
    if (gameManager.board.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FFFF)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileSize = constraints.maxWidth / gameManager.cols;

        return SizedBox(
          width: constraints.maxWidth,
          height: tileSize * gameManager.rows,
          child: Stack(
            children: gameManager.board.expand((row) => row).where((tile) => tile != null).map((tile) {
              return AnimatedPositioned(
                key: ValueKey(tile!.id),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                top: tile.row * tileSize,
                left: tile.col * tileSize,
                width: tileSize,
                height: tileSize,
                child: GestureDetector(
                  onTap: () {
                    gameManager.tapTile(tile.row, tile.col);
                  },
                  onPanUpdate: (details) {
                    _handleSwipe(details, tile);
                  },
                  child: _buildTileUI(tile),
                ),
              );
            }).toList(),
          ),
        );
      }
    );
  }

  Widget _buildTileUI(Tile tile) {
    bool isColorBomb = tile.type == TileType.colorBomb;
    Color tileColor = isColorBomb ? Colors.black : _getTileColor(tile.color);
    Color glowColor = isColorBomb ? const Color(0xFFB14DFF) : tileColor;

    // YENİ: Patlama/Birleşme anında küçülme ve saydamlaşma animasyonları
    return AnimatedScale(
      scale: tile.isExploding ? 0.0 : 1.0, // Patlıyorsa yavaşça küçül
      duration: const Duration(milliseconds: 250), // Yöneticideki bekleme süresiyle aynı
      curve: Curves.easeInBack, // İçeri doğru çekilme hissi verir
      child: AnimatedOpacity(
        opacity: tile.isExploding ? 0.0 : 1.0, // Patlıyorsa yavaşça saydamlaş
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(14),
            border: isColorBomb ? Border.all(color: Colors.white38, width: 2) : null,
            boxShadow: [
              // Patlama anında gölgeyi anlık olarak beyazlatıp büyütüyoruz (Parlayıp sönme efekti)
              BoxShadow(
                color: tile.isExploding ? Colors.white : glowColor.withOpacity(0.75), 
                blurRadius: tile.isExploding ? 20 : 12, 
                spreadRadius: tile.isExploding ? 4 : 1.5
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.25), 
                blurRadius: 2, 
                spreadRadius: -0.5
              )
            ],
          ),
          child: Center(child: _getTileIcon(tile.type)),
        ),
      ),
    );
  }

  Color _getTileColor(TileColor color) {
    switch (color) {
      case TileColor.purple: return const Color(0xFFB14DFF);
      case TileColor.orange: return const Color(0xFFFF6B00);
      case TileColor.yellow: return const Color(0xFFFFD700);
      case TileColor.cyan:   return const Color(0xFF00FFFF);
      case TileColor.pink:   return const Color(0xFFFF007F);
      case TileColor.green:  return const Color(0xFF00FF66);
    }
  }

  Widget? _getTileIcon(TileType type) {
    switch (type) {
      case TileType.stripedHorizontal:
        return const Icon(Icons.swap_horiz, color: Colors.white, size: 26);
      case TileType.stripedVertical:
        return const Icon(Icons.swap_vert, color: Colors.white, size: 26);
      case TileType.colorBomb:
        return const Icon(Icons.blur_circular, color: Color(0xFFB14DFF), size: 32);
      case TileType.wrapped:
        return const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 26);
      default:
        return null;
    }
  }

  void _handleSwipe(DragUpdateDetails details, Tile tile) {
    if (gameManager.isAnimating) return;
    if (details.delta.distance < 2.5) return;

    int dx = 0; int dy = 0;
    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      dx = details.delta.dx > 0 ? 1 : -1;
    } else {
      dy = details.delta.dy > 0 ? 1 : -1;
    }

    int nR = tile.row + dy; int nC = tile.col + dx;
    if (nR >= 0 && nR < gameManager.rows && nC >= 0 && nC < gameManager.cols) {
      gameManager.swapTiles(tile.row, tile.col, nR, nC);
    }
  }
}