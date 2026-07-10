// test/level_generation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:match3_game/models/levels.dart';

void main() {
  test('16-500 arası her bölüm oynanabilir', () {
    for (int lvl = 16; lvl <= 500; lvl++) {
      final layout = layoutForLevel(lvl, 8, 8)!;

      for (int c = 0; c < 8; c++) {
        for (int r = 0; r < 2; r++) {
          final cfg = layout[r][c];
          expect(cfg.isVoid || cfg.blockerKind != null, isFalse,
              reason: 'Bölüm $lvl: üst satırda engel var ($r,$c)');
        }

        final columnBlocked = List.generate(8, (r) => layout[r][c])
            .every((cfg) => cfg.isVoid || cfg.blockerKind != null);
        expect(columnBlocked, isFalse, reason: 'Bölüm $lvl: sütun $c kapalı');
      }

      int blockers = 0;
      for (final row in layout) {
        for (final cfg in row) {
          if (cfg.isVoid || cfg.blockerKind != null) blockers++;
        }
      }
      expect(blockers / 64, lessThanOrEqualTo(0.23),
          reason: 'Bölüm $lvl: çok yoğun');
    }
  });
}