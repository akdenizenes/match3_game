enum TileColor { purple, orange, yellow, cyan, pink, green, none } // NEW: 'none' added
enum TileType { normal, stripedHorizontal, stripedVertical, wrapped, colorBomb, propeller }

class Tile {
  final String id;
  TileColor color;
  TileType type;
  bool isMatched;
  bool isExploding;
  bool isTargeted; 
  bool isHinted;   
  
  bool isObstacle; 
  bool isGoal;     
  
  TileType? typeToBecome;
  int row;
  int col;
  
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
    this.isObstacle = false, 
    this.isGoal = false,     
    this.typeToBecome,
    required this.row,
    required this.col,
    this.mergeTargetRow,
    this.mergeTargetCol,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'color': color.index,
    'type': type.index,
    'row': row,
    'col': col,
    'isObstacle': isObstacle,
    'isGoal': isGoal,
  };

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