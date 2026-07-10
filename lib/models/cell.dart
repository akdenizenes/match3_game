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

/// Board'un atomik birimi. Grid artık Cell[][].
class Cell {
  final int row;
  final int col;

  /// Grid dışı delik (L şeklinde board vs.). Hiçbir şey giremez.
  final bool isVoid;

  ColorTile? tile;
  Blocker? blocker;
  CellOverlay? overlay;

  /// Bu hücrenin kenarlarındaki duvarlar.
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

  // --- Eski bool'ların yeni karşılıkları ---
  bool get isObstacle => blocker != null;
  bool get isLocked => overlay?.locksTile ?? false;

  /// Taş tutabilir mi? (spawn/gravity hedefi olabilir mi)
  bool get canHoldTile => !isVoid && blocker == null;

  bool get isEmpty => canHoldTile && tile == null;

  /// Eşleşmeye girebilir mi?
  bool get isMatchable => !isVoid && tile != null && !isLocked;

  bool hasWall(Side s) => walls.contains(s);

  /// Bu hücrede hâlâ kırılacak bir hedef var mı? (_checkWinCondition için)
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