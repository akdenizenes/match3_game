import 'color_tile.dart';

/// A single propeller currently flying on screen.
///
/// The manager places this into [GameManager.activeFlights], waits out the
/// flight duration, then removes it from the list and destroys the target.
/// The widget side listens to the list and draws a Tween from `from` → `to`.
class PropellerFlight {
  /// Every flight is unique — the widget resets its Tween by this id.
  final String id;

  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;

  /// The special tile the propeller carries. Set on combos (rocket, bomb),
  /// null on a plain propeller flight.
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