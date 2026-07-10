import 'package:flutter/material.dart';
import 'color_tile.dart';

/// Oyundaki TEK renk kaynağı.
/// Tahta, görev çubuğu, partiküller, hepsi buradan okur.
/// Bir rengi değiştireceksen SADECE burayı değiştir.
extension TileColorPalette on TileColor {
  Color get main => switch (this) {
        TileColor.purple => const Color(0xFFB14DFF),
        TileColor.orange => const Color(0xFFFF6B00),
        TileColor.yellow => const Color(0xFFFFD700),
        TileColor.cyan => const Color(0xFF00FFFF),
        TileColor.pink => const Color(0xFFFF007F),
        TileColor.green => const Color(0xFF00FF66),
      };

  /// Küçük ikonlarda / koyu zeminde okunaklı olsun diye hafif açığı.
  Color get soft => Color.lerp(main, Colors.white, 0.25)!;

  String get label => switch (this) {
        TileColor.purple => 'Mor',
        TileColor.orange => 'Turuncu',
        TileColor.yellow => 'Sarı',
        TileColor.cyan => 'Camgöbeği',
        TileColor.pink => 'Pembe',
        TileColor.green => 'Yeşil',
      };
}