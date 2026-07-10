/// Hasarın nereden geldiği. Engeller kaynağa göre farklı tepki verir:
/// kutu sadece bitişik eşleşmeden kırılır, bal her şeyden vs.
enum DamageSource {
  match,          // taş bu hücrede eşleşti
  adjacentMatch,  // komşu hücrede eşleşme oldu
  blast,          // çizgili/sarmalı patlaması
  colorBomb,
  propeller,
  manual,         // debug / booster (çekiç)
}

/// Hasar alabilen her şey (Blocker, CellOverlay).
abstract class Damageable {
  /// Serileştirme anahtarı. registry bunu okuyup doğru sınıfı kurar.
  String get kind;

  int get hp;

  /// Gövdesi burada. Alt sınıflar `extends` ile miras alır.
  bool get isDestroyed => hp <= 0;

  bool acceptsDamage(DamageSource source);

  /// Hasarı uygular. Gerçekten hasar aldıysa true döner.
  bool takeDamage(DamageSource source);

  Map<String, dynamic> toJson();
}

/// Taşın yerini işgal eden engel (kutu, taş blok, buz küpü...).
/// extends → isDestroyed gövdesi miras alınır.
abstract class Blocker extends Damageable {
  /// Kırılana kadar taş bu hücreye giremez / düşemez.
  bool get blocksMovement => true;
}

/// Taşın üstünde/altında duran katman (bal, jöle, buz).
/// NOT: Flutter'ın Overlay sınıfıyla çakışmasın diye "CellOverlay".
abstract class CellOverlay extends Damageable {
  /// Üstündeki taş eşleşebilir mi? (bal: hayır → locksTile = true)
  bool get locksTile => false;

  /// Taşın üstüne mi çizilir (bal, buz), altına mı (jöle)?
  bool get drawsAboveTile => true;
}