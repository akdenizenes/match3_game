enum TileColor { purple, orange, yellow, cyan, pink, green }
enum TileType { normal, stripedHorizontal, stripedVertical, wrapped, colorBomb, propeller }

class Tile {
  final String id;
  TileColor color;
  TileType type;
  bool isMatched;
  bool isExploding;
  TileType? typeToBecome;
  int row;
  int col;
  
  // Coordinates for the merge target during a 4+ tile match animation.
  int? mergeTargetRow; 
  int? mergeTargetCol;

  Tile({
    required this.id,
    required this.color,
    this.type = TileType.normal,
    this.isMatched = false,
    this.isExploding = false,
    this.typeToBecome,
    required this.row,
    required this.col,
    this.mergeTargetRow,
    this.mergeTargetCol,
  });
}