enum TileColor { purple, orange, yellow, cyan, pink, green }

enum TileType {
  normal,
  stripedHorizontal,
  stripedVertical,
  wrapped,
  colorBomb,
  propeller
}

/// Sadece hareket eden, eşleşen renkli taş.
/// Engel/hedef bilgisi ARTIK BURADA DEĞİL → Cell'de.
class ColorTile {
  final String id;

  /// Taş özel tipe dönüşse bile [color] KORUNUR (spawn, merge, serialize
  /// bozulmasın diye). Ama özel taşlarda bu renk artık ne çizilir ne de
  /// eşleşme/renk mantığında kullanılır → bkz. [isNeutral].
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

  /// Renk mantığından TAMAMEN çıkmış taş.
  ///
  /// Nötr taş:
  ///   • ekranda kendi rengiyle çizilmez (nötr metalik gövde)
  ///   • renk eşleşmesine girmez  (matchColorAt → null)
  ///   • colorBomb hedefi olmaz   (yeşil bomba yeşil roketi almaz)
  ///   • "N adet yeşil topla" görevine yazılmaz
  ///
  /// Şu an TÜM özel taşlar nötr. Yarın örn. wrapped'ı tekrar renkli yapmak
  /// istersen SADECE bu getter'ı değiştir, başka hiçbir yeri değil:
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