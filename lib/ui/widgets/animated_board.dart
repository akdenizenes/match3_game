import 'package:flutter/material.dart';
import '../../models/color_tile.dart';
import '../../models/cell.dart';
import '../../models/damageable.dart';
import '../../models/propeller_flight.dart';
import '../../models/tile_palette.dart';
import '../../managers/game_manager.dart';

class AnimatedBoard extends StatelessWidget {
  final GameManager gameManager;
  const AnimatedBoard({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    if (gameManager.cells.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4DB6AC)));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final double tileSize = constraints.maxWidth / gameManager.cols;

      return SizedBox(
        width: constraints.maxWidth,
        height: tileSize * gameManager.rows,
        child: Stack(
          children: [
            // Layer 1: static ground, jelly, blockers, walls.
            RepaintBoundary(
              child:
                  _StaticCellLayer(gameManager: gameManager, tileSize: tileSize),
            ),

            // Layer 2: animated tiles.
            for (final cell in _allCells)
              if (cell.tile != null)
                AnimatedPositioned(
                  key: ValueKey(cell.tile!.id),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  top: cell.tile!.row * tileSize,
                  left: cell.tile!.col * tileSize,
                  width: tileSize,
                  height: tileSize,
                  child: GestureDetector(
                    onTap: () =>
                        gameManager.tapTile(cell.tile!.row, cell.tile!.col),
                    onPanUpdate: (d) => _handleSwipe(d, cell.tile!),
                    child: _buildTileUI(cell.tile!, locked: cell.isLocked),
                  ),
                ),

            // Layer 3: overlays drawn on top of the tile (honey, ice).
            for (final cell in _allCells)
              if (cell.overlay?.drawsAboveTile ?? false)
                Positioned(
                  left: cell.col * tileSize,
                  top: cell.row * tileSize,
                  width: tileSize,
                  height: tileSize,
                  child: IgnorePointer(
                    child: _OverlayVisual(overlay: cell.overlay!),
                  ),
                ),

            // Layer 4: flying propellers. Above everything else.
            for (final flight in gameManager.activeFlights)
              _FlightVisual(
                key: ValueKey(flight.id),
                flight: flight,
                tileSize: tileSize,
              ),
          ],
        ),
      );
    });
  }

  Iterable<Cell> get _allCells =>
      gameManager.cells.expand((row) => row).where((c) => !c.isVoid);

  Widget _buildTileUI(ColorTile tile, {required bool locked}) {
    // Neutral (special) tiles do not draw their own color.
    final (Color base, Color glow) = _tilePalette(tile);
    final tileColor =
        locked ? Color.lerp(base, Colors.grey.shade700, 0.5)! : base;
    final glowColor = locked ? tileColor : glow;

    return TweenAnimationBuilder<double>(
      key: ValueKey('pulse_${tile.id}'),
      tween: Tween(begin: 1.0, end: tile.isHinted ? 1.15 : 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutSine,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The tile: rotation, swelling, explosion.
          AnimatedRotation(
            turns: tile.isExploding ? 0.15 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeIn,
            child: AnimatedScale(
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
                    // Neutral tiles are set apart with a thin white border.
                    border: tile.isNeutral
                        ? Border.all(color: Colors.white38, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: tile.isExploding
                            ? Colors.white
                            : glowColor.withOpacity(locked ? 0.4 : 0.95),
                        blurRadius: tile.isExploding ? 10.0 : 4.0,
                        spreadRadius: tile.isExploding ? 4.0 : 1.0,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(locked ? 0.2 : 0.6),
                        blurRadius: 1.0,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Center(child: _getTileIcon(tile.type)),
                ),
              ),
            ),
          ),

          // 2. Propeller targeting reticle. Pulses during flight.
          AnimatedScale(
            scale: tile.isTargeted ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: _PulsingReticle(active: tile.isTargeted),
          ),

          // 3. Hint star.
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
                    spreadRadius: 4.0,
                  )
                ],
              ),
              child: const Icon(Icons.star_rounded,
                  color: Colors.white, size: 28.0),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns (body color, glow color).
  ///
  /// A normal tile's color comes from a SINGLE SOURCE: TileColorPalette.main.
  /// The objective bar reads from the same place, so a mismatch is impossible.
  /// Special tiles carry no color: a dark neutral body plus a type-specific glow.
  /// Whether a rocket is horizontal/vertical is read from the icon, not the body.
  (Color, Color) _tilePalette(ColorTile tile) => switch (tile.type) {
        // Rocket: steel body, cool white glow.
        TileType.stripedHorizontal ||
        TileType.stripedVertical =>
          (const Color(0xFF48505E), const Color(0xFFE0E6ED)),

        // Bomb: dark charcoal body, orange glow.
        TileType.wrapped => (const Color(0xFF3A2E28), const Color(0xFFFF9E40)),

        // Propeller: dark petrol body, turquoise glow.
        TileType.propeller => (const Color(0xFF2E3A40), const Color(0xFF64FFDA)),

        // Color bomb: black body, purple glow.
        TileType.colorBomb => (Colors.black, const Color(0xFFB14DFF)),

        // Normal tile: its own color from the palette.
        TileType.normal => (tile.color.main, tile.color.main),
      };

  /// Direction is distinguished here: a double arrow, independent of the body.
  Widget? _getTileIcon(TileType type) => switch (type) {
        TileType.stripedHorizontal => const Icon(
            Icons.keyboard_double_arrow_right_rounded,
            color: Colors.white,
            size: 30.0),
        TileType.stripedVertical => const Icon(
            Icons.keyboard_double_arrow_down_rounded,
            color: Colors.white,
            size: 30.0),
        TileType.colorBomb =>
          const Icon(Icons.blur_circular, color: Color(0xFFB14DFF), size: 32.0),
        TileType.wrapped => const Icon(Icons.local_fire_department,
            color: Color(0xFFFF9E40), size: 26.0),
        TileType.propeller =>
          const Icon(Icons.send_rounded, color: Color(0xFF64FFDA), size: 28.0),
        TileType.normal => null,
      };

  void _handleSwipe(DragUpdateDetails details, ColorTile tile) {
    if (gameManager.isAnimating) return;
    if (details.delta.distance < 2.5) return;

    int dx = 0, dy = 0;
    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      dx = details.delta.dx > 0 ? 1 : -1;
    } else {
      dy = details.delta.dy > 0 ? 1 : -1;
    }

    final nR = tile.row + dy;
    final nC = tile.col + dx;

    if (gameManager.canPass(tile.row, tile.col, nR, nC)) {
      gameManager.swapTiles(tile.row, tile.col, nR, nC);
    }
  }
}

// ===========================================================
// FLYING PROPELLER
// ===========================================================

/// Flies a propeller from `from` to `to`.
///
/// A straight line looks dull, so we draw a slight arc (a perpendicular
/// deviation at the midpoint of the path). The propeller spins on its own
/// axis, leaves a fading trail behind it, and carries the special tile it
/// is transporting alongside it.
class _FlightVisual extends StatelessWidget {
  final PropellerFlight flight;
  final double tileSize;

  const _FlightVisual({
    super.key,
    required this.flight,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    final from = Offset(
      flight.fromCol * tileSize + tileSize / 2,
      flight.fromRow * tileSize + tileSize / 2,
    );
    final to = Offset(
      flight.toCol * tileSize + tileSize / 2,
      flight.toRow * tileSize + tileSize / 2,
    );

    // Perpendicular deviation at the midpoint, proportional to distance.
    final delta = to - from;
    final dist = delta.distance;
    final perp = dist == 0
        ? Offset.zero
        : Offset(-delta.dy / dist, delta.dx / dist) * (dist * 0.18);

    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: flight.duration,
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) {
            // Quadratic Bezier: from -> (midpoint + deviation) -> to.
            final ctrl = Offset.lerp(from, to, 0.5)! + perp;
            final inv = 1 - t;
            final pos = from * (inv * inv) +
                ctrl * (2 * inv * t) +
                to * (t * t);

            // Shrinks and settles toward the end.
            final scale = 1.0 - (t * t) * 0.35;

            return Stack(
              children: [
                // Trail: slightly behind the propeller, faded.
                if (t > 0.08)
                  _flightDot(
                    Offset.lerp(from, pos, 0.82)!,
                    opacity: (1 - t) * 0.35,
                    size: tileSize * 0.30,
                  ),
                if (t > 0.16)
                  _flightDot(
                    Offset.lerp(from, pos, 0.9)!,
                    opacity: (1 - t) * 0.55,
                    size: tileSize * 0.38,
                  ),

                // The propeller itself.
                Positioned(
                  left: pos.dx - tileSize / 2,
                  top: pos.dy - tileSize / 2,
                  width: tileSize,
                  height: tileSize,
                  child: Transform.scale(
                    scale: scale,
                    // Spins 3 full turns.
                    child: Transform.rotate(
                      angle: t * 6.2831853 * 3,
                      child: _propellerBody(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _flightDot(Offset pos, {required double opacity, required double size}) {
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF64FFDA).withOpacity(opacity.clamp(0.0, 1.0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64FFDA).withOpacity(opacity * 0.6),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _propellerBody() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF2E3A40),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF64FFDA), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64FFDA).withOpacity(0.9),
                blurRadius: 14,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.send_rounded,
                color: Color(0xFF64FFDA), size: 24.0),
          ),
        ),

        // Carried special tile: a badge pinned to the propeller's back.
        if (flight.carriedType != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: _carriedIcon(flight.carriedType!),
            ),
          ),
      ],
    );
  }

  Widget _carriedIcon(TileType type) => switch (type) {
        TileType.stripedHorizontal => const Icon(
            Icons.keyboard_double_arrow_right_rounded,
            color: Colors.white,
            size: 16.0),
        TileType.stripedVertical => const Icon(
            Icons.keyboard_double_arrow_down_rounded,
            color: Colors.white,
            size: 16.0),
        TileType.wrapped => const Icon(Icons.local_fire_department,
            color: Color(0xFFFF9E40), size: 16.0),
        _ => const SizedBox.shrink(),
      };
}

/// Targeting reticle. Pulses like a heartbeat while the target is locked.
class _PulsingReticle extends StatelessWidget {
  final bool active;
  const _PulsingReticle({required this.active});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: active ? 1.15 : 0.85),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.8),
              blurRadius: 6.0,
              spreadRadius: 2.0,
            )
          ],
        ),
        child: const Icon(Icons.my_location_rounded,
            color: Colors.white, size: 40.0),
      ),
    );
  }
}

// ===========================================================
// STATIC LAYER
// ===========================================================

class _StaticCellLayer extends StatelessWidget {
  final GameManager gameManager;
  final double tileSize;
  const _StaticCellLayer({required this.gameManager, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int r = 0; r < gameManager.rows; r++)
          for (int c = 0; c < gameManager.cols; c++)
            Positioned(
              left: c * tileSize,
              top: r * tileSize,
              width: tileSize,
              height: tileSize,
              child: _CellVisual(cell: gameManager.cells[r][c]),
            ),
      ],
    );
  }
}

class _CellVisual extends StatelessWidget {
  final Cell cell;
  const _CellVisual({required this.cell});

  @override
  Widget build(BuildContext context) {
    if (cell.isVoid) return const SizedBox.shrink();

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: (cell.row + cell.col) % 2 == 0
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        if (!(cell.overlay?.drawsAboveTile ?? true))
          _OverlayVisual(overlay: cell.overlay!),
        if (cell.blocker != null) _BlockerVisual(blocker: cell.blocker!),
        if (cell.walls.isNotEmpty)
          CustomPaint(size: Size.infinite, painter: _WallPainter(cell.walls)),
      ],
    );
  }
}

class _BlockerVisual extends StatelessWidget {
  final Blocker blocker;
  const _BlockerVisual({required this.blocker});

  @override
  Widget build(BuildContext context) {
    final isStone = blocker.kind == 'stone';
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: isStone ? const Color(0xFF6D6D7A) : const Color(0xFF8D6E4A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black.withOpacity(0.35), width: 2),
        ),
        child: Center(
          child: Text(
            blocker.hp > 1 ? '${blocker.hp}' : '',
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _OverlayVisual extends StatelessWidget {
  final CellOverlay overlay;
  const _OverlayVisual({required this.overlay});

  @override
  Widget build(BuildContext context) {
    // Returns (main color, fill opacity, border color).
    // Opacities lowered from 0.55 to ~0.30 so the tile underneath stays readable.
    final (Color color, double fill, Color border) = switch (overlay.kind) {
      // Honey: warm amber, low fill so the tile remains selectable.
      'honey' => (const Color(0xFFFFC107), 0.30, const Color(0xFFFFA000)),
      // Ice: cool light blue.
      'ice'   => (const Color(0xFF81D4FA), 0.30, const Color(0xFFB3E5FC)),
      // Jelly: vivid pink.
      'jelly' => (const Color(0xFFEC407A), 0.26, const Color(0xFFF48FB1)),
      _       => (Colors.grey, 0.30, Colors.grey),
    };

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // A subtle bright gradient instead of a flat color gives a "goo/coating" feel.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity((fill + 0.12).clamp(0.0, 1.0)),
            color.withOpacity(fill),
          ],
        ),
        border: overlay.drawsAboveTile
            ? Border.all(color: border.withOpacity(0.9), width: 2)
            : null,
      ),
      // Small highlight dot in the top-left for a glass/jelly shine.
      child: overlay.drawsAboveTile
          ? Align(
              alignment: const Alignment(-0.5, -0.5),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            )
          : null,
    );
  }
}

class _WallPainter extends CustomPainter {
  final Set<Side> walls;
  _WallPainter(this.walls);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (final w in walls) {
      final (Offset a, Offset b) = switch (w) {
        Side.top => (Offset.zero, Offset(s.width, 0)),
        Side.bottom => (Offset(0, s.height), Offset(s.width, s.height)),
        Side.left => (Offset.zero, Offset(0, s.height)),
        Side.right => (Offset(s.width, 0), Offset(s.width, s.height)),
      };
      canvas.drawLine(a, b, p);
    }
  }

  @override
  bool shouldRepaint(_WallPainter old) => old.walls != walls;
}