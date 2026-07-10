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
            // --- KATMAN 1: Statik zemin, jöle, blocker, duvarlar ---
            RepaintBoundary(
              child:
                  _StaticCellLayer(gameManager: gameManager, tileSize: tileSize),
            ),

            // --- KATMAN 2: Animasyonlu taşlar ---
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

            // --- KATMAN 3: Taşın ÜSTÜNE çizilen overlay'ler (bal, buz) ---
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

            // --- KATMAN 4: Uçan pervaneler. Her şeyin üstünde. ---
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
    // Nötr (özel) taşlar kendi renklerini ÇİZMEZ.
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
          // 1. Taş: dönme, şişme, patlama
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
                    // Nötr taşlar ince beyaz çerçeveyle normalden ayrılır.
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

          // 2. Pervane hedefleme (nişangah). Uçuş sırasında yanıp söner.
          AnimatedScale(
            scale: tile.isTargeted ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: _PulsingReticle(active: tile.isTargeted),
          ),

          // 3. İpucu yıldızı
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

  /// (gövde rengi, ışıma rengi)
  ///
  /// Normal taşın rengi TEK KAYNAKTAN gelir: TileColorPalette.main
  /// Görev çubuğu da aynı yerden okur → uyumsuzluk imkânsız.
  /// Özel taşlar renk taşımaz: koyu nötr gövde + tipe özgü ışık.
  /// Roketin yatay/dikey olduğu GÖVDEDEN değil, ikondan okunur.
  (Color, Color) _tilePalette(ColorTile tile) => switch (tile.type) {
        // Roket: çelik gövde, soğuk beyaz ışık
        TileType.stripedHorizontal ||
        TileType.stripedVertical =>
          (const Color(0xFF48505E), const Color(0xFFE0E6ED)),

        // Bomba: koyu kömür gövde, turuncu ışık
        TileType.wrapped => (const Color(0xFF3A2E28), const Color(0xFFFF9E40)),

        // Pervane: koyu petrol gövde, turkuaz ışık
        TileType.propeller => (const Color(0xFF2E3A40), const Color(0xFF64FFDA)),

        // Renk bombası: siyah gövde, mor ışık
        TileType.colorBomb => (Colors.black, const Color(0xFFB14DFF)),

        // Normal taş: kendi rengi — paletten
        TileType.normal => (tile.color.main, tile.color.main),
      };

  /// Yön ayrımı burada yapılır: çift ok, gövdeden bağımsız, net.
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
// UÇAN PERVANE
// ===========================================================

/// Bir pervaneyi `from` → `to` arası uçurur.
///
/// Düz çizgi sıkıcı durur; hafif bir yay çiziyoruz (uçuşun ortasında
/// yola dik yönde sapma). Pervane kendi ekseninde döner, arkasında
/// sönen bir iz bırakır, taşıdığı özel taşı yanında götürür.
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

    // Yolun ortasında, yola dik yönde sapma. Mesafeyle orantılı.
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
            // Quadratic Bézier: from → (orta + sapma) → to
            final ctrl = Offset.lerp(from, to, 0.5)! + perp;
            final inv = 1 - t;
            final pos = from * (inv * inv) +
                ctrl * (2 * inv * t) +
                to * (t * t);

            // Sona doğru küçülüp konuyor.
            final scale = 1.0 - (t * t) * 0.35;

            return Stack(
              children: [
                // İz: pervanenin biraz gerisinde, sönük
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

                // Pervanenin kendisi
                Positioned(
                  left: pos.dx - tileSize / 2,
                  top: pos.dy - tileSize / 2,
                  width: tileSize,
                  height: tileSize,
                  child: Transform.scale(
                    scale: scale,
                    // 3 tam tur döner
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

        // Taşınan özel taş: pervanenin sırtına iliştirilmiş rozet
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

/// Nişangah. Hedef kilitliyken nabız gibi atar.
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
// STATİK KATMAN
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
    final (Color color, double opacity) = switch (overlay.kind) {
      'honey' => (const Color(0xFFFFB300), 0.55),
      'ice' => (const Color(0xFF81D4FA), 0.45),
      'jelly' => (const Color(0xFFEC407A), 0.30),
      _ => (Colors.grey, 0.3),
    };

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(10),
        border: overlay.drawsAboveTile
            ? Border.all(color: color.withOpacity(0.8), width: 2)
            : null,
      ),
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