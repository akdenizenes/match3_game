part of 'game_manager.dart';

extension GameManagerPowerups on GameManager {

  Future<void> useRoyalHammer(int r, int c) async {
    if (board[r][c] != null) {
      board[r][c]!.isMatched = true;
      await _processMatches();
      _checkWinCondition();
    }
  }

  Future<void> useArrowBooster(int r) async {
    for (int c = 0; c < cols; c++) {
      if (board[r][c] != null) board[r][c]!.isMatched = true;
    }
    await _processMatches();
    _checkWinCondition();
  }

  Future<void> useCannonBooster(int c) async {
    for (int r = 0; r < rows; r++) {
      if (board[r][c] != null) board[r][c]!.isMatched = true;
    }
    await _processMatches();
    _checkWinCondition();
  }

  Future<void> useJesterHat() async {
    List<Tile> allTiles = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null) {
          allTiles.add(board[r][c]!);
        }
      }
    }
    
    // Shuffle all existing tiles on the board.
    allTiles.shuffle(); 
    
    int index = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null) {
          board[r][c] = allTiles[index];
          board[r][c]!.row = r;
          board[r][c]!.col = c;
          index++;
        }
      }
    }
    notifyListeners();
    // Await animation completion.
    await Future.delayed(const Duration(milliseconds: 300)); 

    // Failsafe: Resolve any accidental matches caused by the shuffle.
    if (_checkMatches()) {
      await _processMatches();
    }
    _checkWinCondition();
  }

  void _convertMostFrequentToSpecial(TileType specialType) {
    Map<TileColor, int> counts = {};
    for (var r in board) {
      for (var t in r) {
        if (t != null && t.type == TileType.normal) {
          counts[t.color] = (counts[t.color] ?? 0) + 1;
        }
      }
    }
    
    TileColor? mostColor;
    int maxC = 0;
    counts.forEach((color, count) {
      if (count > maxC) {
        maxC = count;
        mostColor = color;
      }
    });

    if (mostColor != null) {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (board[r][c] != null && board[r][c]!.color == mostColor) {
            board[r][c]!.type = specialType;
            board[r][c]!.isMatched = true;
          }
        }
      }
    }
  }
}