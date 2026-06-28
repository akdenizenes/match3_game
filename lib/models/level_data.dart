import 'tile.dart';

class LevelData {
  final int levelNumber;
  final int maxMoves;
  final int? targetScore;
  final Map<TileColor, int>? targetColors;

  LevelData({
    required this.levelNumber,
    required this.maxMoves,
    this.targetScore,
    this.targetColors,
  });
}