import 'damageable.dart';

// ---------------- BLOCKERS ----------------

/// Box: breaks only from an adjacent match. Blasts don't affect it.
class Box extends Blocker {
  @override String get kind => 'box';
  @override int hp;
  Box({this.hp = 1});

  @override
  bool acceptsDamage(DamageSource s) =>
      s == DamageSource.adjacentMatch || s == DamageSource.manual;

  @override
  bool takeDamage(DamageSource s) {
    if (!acceptsDamage(s) || isDestroyed) return false;
    hp--;
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {'kind': kind, 'hp': hp};
}

/// Stone block: 2 layers, blasts break it too.
class StoneBlock extends Blocker {
  @override String get kind => 'stone';
  @override int hp;
  StoneBlock({this.hp = 2});

  @override
  bool acceptsDamage(DamageSource s) => s != DamageSource.match;

  @override
  bool takeDamage(DamageSource s) {
    if (!acceptsDamage(s) || isDestroyed) return false;
    hp--;
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {'kind': kind, 'hp': hp};
}

// ---------------- OVERLAYS ----------------

/// Ice: sits on top of a tile, takes damage from everything, doesn't lock the tile.
class Ice extends CellOverlay {
  @override String get kind => 'ice';
  @override int hp;
  Ice({this.hp = 1});

  @override bool get locksTile => false;
  @override bool get drawsAboveTile => true;

  @override bool acceptsDamage(DamageSource s) => true;

  @override
  bool takeDamage(DamageSource s) {
    // In line with the other obstacles: even though acceptsDamage always
    // returns true, we keep the guard here so nothing breaks if you make ice
    // selective later.
    if (!acceptsDamage(s) || isDestroyed) return false;
    hp--;
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {'kind': kind, 'hp': hp};
}

/// Honey: locks the tile beneath it. Only an adjacent match/blast breaks it.
class Honey extends CellOverlay {
  @override String get kind => 'honey';
  @override int hp;
  Honey({this.hp = 1});

  @override bool get locksTile => true;
  @override bool get drawsAboveTile => true;

  // Because of locksTile, a match can't form on this cell anyway.
  @override bool acceptsDamage(DamageSource s) => s != DamageSource.match;

  @override
  bool takeDamage(DamageSource s) {
    if (!acceptsDamage(s) || isDestroyed) return false;
    hp--;
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {'kind': kind, 'hp': hp};
}

/// Jelly: sits UNDER the tile. Cleared when a match happens there.
class Jelly extends CellOverlay {
  @override String get kind => 'jelly';
  @override int hp;
  Jelly({this.hp = 1});

  @override bool get locksTile => false;
  @override bool get drawsAboveTile => false;

  @override
  bool acceptsDamage(DamageSource s) =>
      s == DamageSource.match ||
      s == DamageSource.blast ||
      s == DamageSource.colorBomb ||
      s == DamageSource.propeller;

  @override
  bool takeDamage(DamageSource s) {
    if (!acceptsDamage(s) || isDestroyed) return false;
    hp--;
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {'kind': kind, 'hp': hp};
}

// ---------------- REGISTRY ----------------

/// When you add a new obstacle, add ONLY one line here.
Blocker? blockerFromJson(dynamic j) {
  if (j == null) return null;
  final map = Map<String, dynamic>.from(j);
  final hp = map['hp'] as int? ?? 1;
  return switch (map['kind'] as String) {
    'box' => Box(hp: hp),
    'stone' => StoneBlock(hp: hp),
    _ => null,
  };
}

CellOverlay? overlayFromJson(dynamic j) {
  if (j == null) return null;
  final map = Map<String, dynamic>.from(j);
  final hp = map['hp'] as int? ?? 1;
  return switch (map['kind'] as String) {
    'ice' => Ice(hp: hp),
    'honey' => Honey(hp: hp),
    'jelly' => Jelly(hp: hp),
    _ => null,
  };
}