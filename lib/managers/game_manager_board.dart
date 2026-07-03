part of 'game_manager.dart';

extension GameManagerBoard on GameManager {
  void _initializeBoard() {
    board = List.generate(rows, (_) => List.filled(cols, null));
    final random = Random();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        TileColor newColor;
        bool isInvalid;
        
        do {
          isInvalid = false;
          // Pick a random color
          newColor = TileColor.values[random.nextInt(TileColor.values.length)];
          
          // 1. Horizontal Match Check (Look at the 2 tiles to the left)
          if (c >= 2 && board[r][c - 1]?.color == newColor && board[r][c - 2]?.color == newColor) {
            isInvalid = true;
          }
          // 2. Vertical Match Check (Look at the 2 tiles above)
          else if (r >= 2 && board[r - 1][c]?.color == newColor && board[r - 2][c]?.color == newColor) {
            isInvalid = true;
          }
          // 3. NEW: 2x2 Propeller Check (Look left, up, and top-left diagonal)
          // Ensures a propeller doesn't spawn already completed at the start of a level
          else if (r >= 1 && c >= 1 && 
                   board[r - 1][c]?.color == newColor && 
                   board[r][c - 1]?.color == newColor && 
                   board[r - 1][c - 1]?.color == newColor) {
            isInvalid = true;
          }
          
        } while (isInvalid); // Loop instantly picks another color if the chosen one creates a match

        // Place the safe tile
        board[r][c] = Tile(
          id: 'init_${r}_${c}_${random.nextInt(100000)}',
          color: newColor,
          row: r,
          col: c,
        );
      }
    }
  }
}