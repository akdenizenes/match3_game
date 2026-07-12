/// Where the damage came from. Obstacles react differently by source:
/// a box only breaks from an adjacent match, honey breaks from anything, etc.
enum DamageSource {
  match,          // a tile matched on this cell
  adjacentMatch,  // a match happened on a neighboring cell
  blast,          // a striped/wrapped blast
  colorBomb,
  propeller,
  manual,         // debug / booster (hammer)
}

/// Anything that can take damage (Blocker, CellOverlay).
abstract class Damageable {
  /// Serialization key. The registry reads this to build the right class.
  String get kind;

  int get hp;

  /// The body lives here. Subclasses inherit it via `extends`.
  bool get isDestroyed => hp <= 0;

  bool acceptsDamage(DamageSource source);

  /// Applies the damage. Returns true if it actually took damage.
  bool takeDamage(DamageSource source);

  Map<String, dynamic> toJson();
}

/// An obstacle occupying a tile's spot (box, stone block, ice cube...).
/// extends → the isDestroyed body is inherited.
abstract class Blocker extends Damageable {
  /// Until it breaks, a tile can't enter / fall into this cell.
  bool get blocksMovement => true;
}

/// A layer sitting above/below a tile (honey, jelly, ice).
/// NOTE: named "CellOverlay" so it doesn't clash with Flutter's Overlay class.
abstract class CellOverlay extends Damageable {
  /// Can the tile above match? (honey: no → locksTile = true)
  bool get locksTile => false;

  /// Drawn above the tile (honey, ice), or below it (jelly)?
  bool get drawsAboveTile => true;
}