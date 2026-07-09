import 'tile.dart';

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

  LevelData({
    required this.levelNumber,
    required this.maxMoves,
    this.targetScore,
    this.targetColors,
  });
}