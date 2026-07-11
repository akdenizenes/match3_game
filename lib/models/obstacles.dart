import 'damageable.dart';

// ---------------- BLOCKERS ----------------

/// Kutu: sadece komşu eşleşmeyle kırılır. Patlamalar işlemez.
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

/// Taş blok: 2 katmanlı, patlamalar da kırar.
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

/// Buz: taşın üstünde, her şeyden hasar alır, taşı kilitlemez.
class Ice extends CellOverlay {
  @override String get kind => 'ice';
  @override int hp;
  Ice({this.hp = 1});

  @override bool get locksTile => false;
  @override bool get drawsAboveTile => true;

  @override bool acceptsDamage(DamageSource s) => true;

  @override
  bool takeDamage(DamageSource s) {
    // Diğer engellerle aynı hizada: acceptsDamage her zaman true dönse de
    // guard'ı burada tutuyoruz ki ileride buzu seçici yaparsan bozulmasın.
    if (!acceptsDamage(s) || isDestroyed) return false;
    hp--;
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {'kind': kind, 'hp': hp};
}

/// Bal: altındaki taşı kilitler. Sadece komşu eşleşme/patlama kırar.
class Honey extends CellOverlay {
  @override String get kind => 'honey';
  @override int hp;
  Honey({this.hp = 1});

  @override bool get locksTile => true;
  @override bool get drawsAboveTile => true;

  // locksTile yüzünden bu hücrede match zaten oluşamaz.
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

/// Jöle: taşın ALTINDA. Taş orada eşleşince silinir.
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

/// Yeni engel eklediğinde SADECE buraya bir satır ekle.
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