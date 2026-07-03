import 'package:flutter/material.dart';
import '../../models/tile.dart';
import '../../managers/game_manager.dart';

class AnimatedBoard extends StatelessWidget {
  final GameManager gameManager;
  const AnimatedBoard({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
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
            // Filters out null values to prevent layout errors
            children: gameManager.board.expand((row) => row).whereType<Tile>().map((tile) {
              return AnimatedPositioned(
                key: ValueKey(tile.id),
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

    // Hint Pulse Effect: Animates only when isHinted is true
    return TweenAnimationBuilder<double>(
      key: ValueKey('pulse_${tile.id}'),
      tween: Tween(begin: 1.0, end: tile.isHinted ? 1.15 : 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutSine,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. ORIGINAL TILE ANIMATION (Rotation, Swelling, and Explosion)
          AnimatedRotation(
            turns: tile.isExploding ? 0.15 : 0.0, 
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeIn,
            child: AnimatedScale(
              // Swells by 10% (1.1) right before exploding, then shrinks to 0
              scale: tile.isExploding ? 0.0 : (tile.isMatched ? 1.1 : 1.0), 
              duration: const Duration(milliseconds: 250), 
              curve: tile.isExploding ? Curves.easeInBack : Curves.elasticOut,
              child: AnimatedOpacity(
                opacity: tile.isExploding ? 0.0 : 1.0, 
                duration: const Duration(milliseconds: 200),
                child: Container(
                  margin: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(14),
                    border: isColorBomb ? Border.all(color: Colors.white38, width: 2) : null,
                    boxShadow: [
                      // Outer vibrant glow
                      BoxShadow(
                        color: tile.isExploding ? Colors.white : glowColor.withOpacity(0.95), 
                        blurRadius: tile.isExploding ? 10.0 : 4.0, 
                        spreadRadius: tile.isExploding ? 4.0 : 1.0
                      ),
                      // Inner bright highlight to make colors pop
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6), 
                        blurRadius: 1.0, 
                        spreadRadius: 0.5
                      )
                    ],
                  ),
                  child: Center(child: _getTileIcon(tile.type)),
                ),
              ),
            ),
          ),

          // 2. PROPELLER TARGETING OVERLAY (isTargeted)
          AnimatedScale(
            scale: tile.isTargeted ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.8), 
                    blurRadius: 6.0, 
                    spreadRadius: 2.0  
                  )
                ]
              ),
              child: const Icon(
                Icons.my_location_rounded, // Sniper / Target Icon
                color: Colors.white,
                size: 40.0,
              ),
            ),
          ),

          // 3. IDLE HINT OVERLAY (isHinted)
          AnimatedScale(
            scale: tile.isHinted ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellowAccent.withOpacity(0.6), 
                    blurRadius: 12.0, 
                    spreadRadius: 4.0  
                  )
                ]
              ),
              child: const Icon(
                Icons.star_rounded, // Glowing Star Icon for hints
                color: Colors.white,
                size: 28.0,
              ),
            ),
          ),
        ],
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
      default: return Colors.transparent; 
    }
  }

  Widget? _getTileIcon(TileType type) {
    switch (type) {
      case TileType.stripedHorizontal:
        return const Icon(Icons.swap_horiz, color: Colors.white, size: 26.0);
      case TileType.stripedVertical:
        return const Icon(Icons.swap_vert, color: Colors.white, size: 26.0);
      case TileType.colorBomb:
        return const Icon(Icons.blur_circular, color: Color(0xFFB14DFF), size: 32.0);
      case TileType.wrapped:
        return const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 26.0);
      case TileType.propeller:
        return const Icon(Icons.send_rounded, color: Colors.white, size: 28.0);
      default:
        return null;
    }
  }

  void _handleSwipe(DragUpdateDetails details, Tile tile) {
    if (gameManager.isAnimating) return;
    // Prevent micro-swipes from triggering accidental swaps
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