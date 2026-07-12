import 'color_tile.dart';
import 'cell.dart';
import 'obstacles.dart';

/// A cell's initial configuration. Level design is written with this.
class CellConfig {
  final bool isVoid;
  final Set<Side> walls;
  final String? blockerKind; // 'box', 'stone'
  final String? overlayKind; // 'honey', 'ice', 'jelly'
  final int hp;

  const CellConfig({
    this.isVoid = false,
    this.walls = const {},
    this.blockerKind,
    this.overlayKind,
    this.hp = 1,
  });

  Cell build(int r, int c) => Cell(
        row: r,
        col: c,
        isVoid: isVoid,
        walls: Set.of(walls),
        blocker: blockerKind == null
            ? null
            : blockerFromJson({'kind': blockerKind, 'hp': hp}),
        overlay: overlayKind == null
            ? null
            : overlayFromJson({'kind': overlayKind, 'hp': hp}),
      );
}

/// Holds the configuration and goals for a specific level.
class LevelData {
  final int levelNumber;

  /// The maximum number of moves the player has to complete the level.
  final int maxMoves;

  /// Optional target score required to pass the level.
  final int? targetScore;

  /// A map of colors and their required amounts to complete the level.
  /// Example: { TileColor.cyan: 15, TileColor.purple: 10 }
  /// The Propeller power-up uses this to find priority targets!
  final Map<TileColor, int>? targetColors;

  /// Cell skeleton. null means a plain empty grid.
  /// If provided, it must be rows×cols in size.
  final List<List<CellConfig>>? layout;

  LevelData({
    required this.levelNumber,
    required this.maxMoves,
    this.targetScore,
    this.targetColors,
    this.layout,
  });
}