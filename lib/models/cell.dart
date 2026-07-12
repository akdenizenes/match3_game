import 'color_tile.dart';
import 'damageable.dart';
import 'obstacles.dart';

enum Side { top, right, bottom, left }

extension SideX on Side {
  Side get opposite => switch (this) {
        Side.top => Side.bottom,
        Side.bottom => Side.top,
        Side.left => Side.right,
        Side.right => Side.left,
      };
}

/// The board's atomic unit. The grid is now Cell[][].
class Cell {
  final int row;
  final int col;

  /// A hole outside the grid (L-shaped board etc.). Nothing can enter it.
  final bool isVoid;

  ColorTile? tile;
  Blocker? blocker;
  CellOverlay? overlay;

  /// The walls on this cell's edges.
  final Set<Side> walls;

  Cell({
    required this.row,
    required this.col,
    this.isVoid = false,
    this.tile,
    this.blocker,
    this.overlay,
    Set<Side>? walls,
  }) : walls = walls ?? <Side>{};

  // --- New equivalents of the old bools ---
  bool get isObstacle => blocker != null;
  bool get isLocked => overlay?.locksTile ?? false;

  /// Can it hold a tile? (can it be a spawn/gravity target)
  bool get canHoldTile => !isVoid && blocker == null;

  bool get isEmpty => canHoldTile && tile == null;

  /// Can it take part in a match?
  bool get isMatchable => !isVoid && tile != null && !isLocked;

  bool hasWall(Side s) => walls.contains(s);

  /// Is there still a breakable target in this cell? (for _checkWinCondition)
  bool get hasGoal => blocker != null || overlay != null;

  Map<String, dynamic> toJson() => {
        'v': isVoid,
        'w': walls.map((s) => s.index).toList(),
        't': tile?.toJson(),
        'b': blocker?.toJson(),
        'o': overlay?.toJson(),
      };

  factory Cell.fromJson(int row, int col, Map<String, dynamic> j) => Cell(
        row: row,
        col: col,
        isVoid: j['v'] as bool? ?? false,
        walls: ((j['w'] as List?) ?? [])
            .map((i) => Side.values[i as int])
            .toSet(),
        tile: j['t'] == null
            ? null
            : ColorTile.fromJson(Map<String, dynamic>.from(j['t'])),
        blocker: blockerFromJson(j['b']),
        overlay: overlayFromJson(j['o']),
      );
}