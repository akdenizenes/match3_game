enum TileColor { purple, orange, yellow, cyan, pink, green }

enum TileType {
  normal,
  stripedHorizontal,
  stripedVertical,
  wrapped,
  colorBomb,
  propeller
}

/// A colored tile that only moves and matches.
/// Obstacle/goal info is NO LONGER HERE → it lives on the Cell.
class ColorTile {
  final String id;

  /// [color] is PRESERVED even when the tile turns into a special type (so
  /// spawn, merge and serialize don't break). But on special tiles this color
  /// is no longer drawn, nor used in match/color logic → see [isNeutral].
  TileColor color;
  TileType type;

  bool isMatched;
  bool isExploding;
  bool isTargeted;
  bool isHinted;

  TileType? typeToBecome;
  int row;
  int col;

  int? mergeTargetRow;
  int? mergeTargetCol;

  ColorTile({
    required this.id,
    required this.color,
    this.type = TileType.normal,
    this.isMatched = false,
    this.isExploding = false,
    this.isTargeted = false,
    this.isHinted = false,
    this.typeToBecome,
    required this.row,
    required this.col,
    this.mergeTargetRow,
    this.mergeTargetCol,
  });

  bool get isSpecial => type != TileType.normal;

  bool get isStriped =>
      type == TileType.stripedHorizontal || type == TileType.stripedVertical;

  /// A tile completely removed from color logic.
  ///
  /// A neutral tile:
  ///   • isn't drawn in its own color on screen (neutral metallic body)
  ///   • doesn't take part in color matching  (matchColorAt → null)
  ///   • isn't a colorBomb target             (a green bomb won't grab a green rocket)
  ///   • isn't counted toward "collect N green" goals
  ///
  /// Right now ALL special tiles are neutral. If tomorrow you want e.g. wrapped
  /// to be colored again, change ONLY this getter, nothing else:
  ///   bool get isNeutral => isSpecial && type != TileType.wrapped;
  bool get isNeutral => isSpecial;

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.index,
        'type': type.index,
        'row': row,
        'col': col,
      };

  factory ColorTile.fromJson(Map<String, dynamic> json) => ColorTile(
        id: json['id'],
        color: TileColor.values[json['color']],
        type: TileType.values[json['type']],
        row: json['row'],
        col: json['col'],
      );
}