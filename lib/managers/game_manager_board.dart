part of 'game_manager.dart';

extension GameManagerBoard on GameManager {
  /// Cell iskeletini kurar ve `currentLevel.layout` varsa
  /// void / blocker / overlay / walls yerleşimini uygular.
  void _createEmptyCells() {
    final layout = currentLevel.layout;

    cells = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        // Layout yoksa ya da boyutu tutmuyorsa düz hücre kur.
        if (layout == null || r >= layout.length || c >= layout[r].length) {
          return Cell(row: r, col: c);
        }

        // CellConfig.build() void + blocker + overlay + walls'un
        // HEPSİNİ kurar. Elle Cell(...) yazma → alan düşürürsün.
        return layout[r][c].build(r, c);
      });
    });
  }

  void _initializeBoard() {
    _createEmptyCells();
    final random = Random();

    // TileColor.none silindi → tüm değerler oynanabilir renk.
    const playableColors = TileColor.values;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Void hücre veya blocker varsa taş koyma.
        if (!cells[r][c].canHoldTile) continue;

        TileColor newColor;
        bool isInvalid;

        do {
          isInvalid = false;
          newColor = playableColors[random.nextInt(playableColors.length)];

          // Yatay üçlü
          if (c >= 2 &&
              tileAt(r, c - 1)?.color == newColor &&
              tileAt(r, c - 2)?.color == newColor) {
            isInvalid = true;
          }
          // Dikey üçlü
          else if (r >= 2 &&
              tileAt(r - 1, c)?.color == newColor &&
              tileAt(r - 2, c)?.color == newColor) {
            isInvalid = true;
          }
          // Kare (2x2)
          else if (r >= 1 &&
              c >= 1 &&
              tileAt(r - 1, c)?.color == newColor &&
              tileAt(r, c - 1)?.color == newColor &&
              tileAt(r - 1, c - 1)?.color == newColor) {
            isInvalid = true;
          }
        } while (isInvalid);

        setTile(
          r,
          c,
          ColorTile(
            id: 'init_${r}_${c}_${random.nextInt(100000)}',
            color: newColor,
            row: r,
            col: c,
          ),
        );
      }
    }
  }
}