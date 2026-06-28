enum TileColor { purple, orange, yellow, cyan, pink, green }
// YENİ: propeller (Pervane) eklendi
enum TileType { normal, stripedHorizontal, stripedVertical, wrapped, colorBomb, propeller }

class Tile {
  final String id;
  TileColor color;
  TileType type;
  bool isMatched;
  TileType? typeToBecome;
  int row;
  int col;

  Tile({
    required this.id,
    required this.color,
    this.type = TileType.normal,
    this.isMatched = false,
    this.typeToBecome,
    required this.row,
    required this.col,
  });
}