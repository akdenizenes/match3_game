import 'package:flutter/material.dart';
import 'color_tile.dart';

/// The ONE color source in the game.
/// The board, goal bar, particles — everything reads from here.
/// If you want to change a color, change ONLY here.
extension TileColorPalette on TileColor {
  Color get main => switch (this) {
        TileColor.purple => const Color(0xFFB14DFF),
        TileColor.orange => const Color(0xFFFF6B00),
        TileColor.yellow => const Color(0xFFFFD700),
        TileColor.cyan => const Color(0xFF00FFFF),
        TileColor.pink => const Color(0xFFFF007F),
        TileColor.green => const Color(0xFF00FF66),
      };

  /// A slightly lighter shade so it stays readable on small icons / dark backgrounds.
  Color get soft => Color.lerp(main, Colors.white, 0.25)!;

  String get label => switch (this) {
        TileColor.purple => 'Purple',
        TileColor.orange => 'Orange',
        TileColor.yellow => 'Yellow',
        TileColor.cyan => 'Cyan',
        TileColor.pink => 'Pink',
        TileColor.green => 'Green',
      };
}