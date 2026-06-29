part of 'game_manager.dart';

extension GameManagerBoard on GameManager {
  
  // --- AÇILIŞTA OTOMATİK PATLAMALARI ENGELLEYEN VE ÇÖKMEYEN YÜKLEME ---
  void _initializeBoard() {
    final random = Random();
    List<List<Tile?>> tempBoard = [];

    for (int r = 0; r < rows; r++) {
      List<Tile?> currentRow = [];
      for (int c = 0; c < cols; c++) {
        TileColor? color;
        bool isValid = false;

        while (!isValid) {
          color = TileColor.values[random.nextInt(TileColor.values.length)];
          
          bool hasMatchLeft = (c >= 2 && currentRow[c - 1]?.color == color && currentRow[c - 2]?.color == color);
          bool hasMatchUp = (r >= 2 && tempBoard[r - 1][c]?.color == color && tempBoard[r - 2][c]?.color == color);

          if (!hasMatchLeft && !hasMatchUp) {
            isValid = true;
          }
        }

        currentRow.add(
          Tile(
            id: 'tile_${r}_${c}_${random.nextInt(100000)}',
            color: color!,
            row: r,
            col: c,
          )
        );
      }
      tempBoard.add(currentRow);
    }
    
    board = tempBoard;
    notifyListeners();
  }
}