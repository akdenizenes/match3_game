part of 'game_manager.dart';

extension GameManagerBoard on GameManager {
  /// Builds the cell skeleton and, if `currentLevel.layout` exists, applies
  /// the void / blocker / overlay / walls placement.
  void _createEmptyCells() {
    final layout = currentLevel.layout;

    cells = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        // If there's no layout or its size doesn't match, build a plain cell.
        if (layout == null || r >= layout.length || c >= layout[r].length) {
          return Cell(row: r, col: c);
        }

        // CellConfig.build() sets up ALL of void + blocker + overlay + walls.
        // Writing Cell(...) by hand → you'd drop fields.
        return layout[r][c].build(r, c);
      });
    });
  }

  void _initializeBoard() {
    _createEmptyCells();
    final random = Random();

    // TileColor.none was removed → every value is a playable color.
    const playableColors = TileColor.values;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Don't place a tile if the cell is void or has a blocker.
        if (!cells[r][c].canHoldTile) continue;

        TileColor newColor;
        bool isInvalid;

        do {
          isInvalid = false;
          newColor = playableColors[random.nextInt(playableColors.length)];

          // Horizontal triple
          if (c >= 2 &&
              tileAt(r, c - 1)?.color == newColor &&
              tileAt(r, c - 2)?.color == newColor) {
            isInvalid = true;
          }
          // Vertical triple
          else if (r >= 2 &&
              tileAt(r - 1, c)?.color == newColor &&
              tileAt(r - 2, c)?.color == newColor) {
            isInvalid = true;
          }
          // Square (2x2)
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