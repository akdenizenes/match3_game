part of 'game_manager.dart';

extension GameManagerBoard on GameManager {
void _initializeBoard() {
    board = List.generate(rows, (_) => List.filled(cols, null));
    final random = Random();
    
    // YENİ: Başlangıçta sadece normal renkleri kullan ('none' hariç)
    final playableColors = TileColor.values.where((c) => c != TileColor.none).toList();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        TileColor newColor;
        bool isInvalid;
        
        do {
          isInvalid = false;
          // Değişen satır:
          newColor = playableColors[random.nextInt(playableColors.length)]; 
          
          if (c >= 2 && board[r][c - 1]?.color == newColor && board[r][c - 2]?.color == newColor) {
            isInvalid = true;
          }
          else if (r >= 2 && board[r - 1][c]?.color == newColor && board[r - 2][c]?.color == newColor) {
            isInvalid = true;
          }
          else if (r >= 1 && c >= 1 && 
                   board[r - 1][c]?.color == newColor && 
                   board[r][c - 1]?.color == newColor && 
                   board[r - 1][c - 1]?.color == newColor) {
            isInvalid = true;
          }
        } while (isInvalid); 

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