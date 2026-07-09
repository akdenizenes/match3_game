enum TileColor { purple, orange, yellow, cyan, pink, green }
enum TileType { normal, stripedHorizontal, stripedVertical, wrapped, colorBomb, propeller }

class Tile {
  final String id;
  TileColor color;
  TileType type;
  bool isMatched;
  bool isExploding;
  bool isTargeted; // Used for Propeller targeting crosshair
  bool isHinted;   // Used for the idle Hint system (Star icon)
  
  // NEW ADDITIONS
  bool isObstacle; // Flags if the tile is an obstacle (e.g., ice, box)
  bool isGoal;     // Flags if the tile is a specific level goal
  
  TileType? typeToBecome;
  int row;
  int col;
  
  // Coordinates for the merge target during a 4+ tile match animation
  int? mergeTargetRow; 
  int? mergeTargetCol;

  Tile({
    required this.id,
    required this.color,
    this.type = TileType.normal,
    this.isMatched = false,
    this.isExploding = false,
    this.isTargeted = false, 
    this.isHinted = false,
    this.isObstacle = false, // Not an obstacle by default
    this.isGoal = false,     // Not a goal by default
    this.typeToBecome,
    required this.row,
    required this.col,
    this.mergeTargetRow,
    this.mergeTargetCol,
  });

  // Converts the tile to JSON for saving to local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'color': color.index,
    'type': type.index,
    'row': row,
    'col': col,
    'isObstacle': isObstacle,
    'isGoal': isGoal,
  };

  // Reconstructs the tile object from the saved JSON data
  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      id: json['id'],
      color: TileColor.values[json['color']],
      type: TileType.values[json['type']],
      row: json['row'],
      col: json['col'],
      isTargeted: false, 
      isHinted: false,
      isMatched: false,
      isExploding: false,
      isObstacle: json['isObstacle'] ?? false,
      isGoal: json['isGoal'] ?? false,
    );
  }
}