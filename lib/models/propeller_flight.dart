import 'color_tile.dart';

/// Ekranda uçmakta olan tek bir pervane.
///
/// Manager bunu [GameManager.activeFlights] listesine koyar, uçuş süresi
/// kadar bekler, sonra listeden çıkarıp hedefi yok eder. Widget tarafı
/// listeyi dinleyip `from` → `to` arası bir Tween çizer.
class PropellerFlight {
  /// Her uçuş benzersiz — widget Tween'i bu id ile sıfırlar.
  final String id;

  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;

  /// Pervanenin taşıdığı özel taş. Kombolarda dolu (roket, bomba),
  /// düz pervane uçuşunda null.
  final TileType? carriedType;

  final Duration duration;

  const PropellerFlight({
    required this.id,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.carriedType,
    this.duration = const Duration(milliseconds: 550),
  });
}