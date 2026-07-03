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
    await Future.delayed(const Duration(milliseconds: 300)); 

    if (_checkMatches()) {
      await _processMatches();
    }
    _checkWinCondition();
  }

  // UPDATED: Spreads the crosshair targeting outwards from the combo location
  Future<void> _convertMostFrequentToSpecialTargeted(TileType specialType, int startR, int startC) async {
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
      List<Tile> targetedTiles = [];
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (board[r][c] != null && board[r][c]!.color == mostColor) {
            targetedTiles.add(board[r][c]!);
          }
        }
      }
      
      // Sort by distance to create the sweeping visual distribution
      targetedTiles.sort((a, b) {
        double distA = sqrt(pow(a.row - startR, 2) + pow(a.col - startC, 2));
        double distB = sqrt(pow(b.row - startR, 2) + pow(b.col - startC, 2));
        return distA.compareTo(distB);
      });

      for (var tile in targetedTiles) {
        tile.isTargeted = true; 
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 30)); // Delay between targets
      }
      
      await Future.delayed(const Duration(milliseconds: 300)); 

      for (var tile in targetedTiles) {
        tile.isTargeted = false; 
        tile.type = specialType; 
        tile.isMatched = true;   
      }
    }
  }

  // UPDATED: Creates a massive, outward shockwave effect on the entire board
  Future<void> _activateDoubleColorBombCombo(int startR, int startC) async {
    List<Tile> allTiles = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null) {
          allTiles.add(board[r][c]!);
        }
      }
    }
    
    // Sort all tiles radially from the center of the combo
    allTiles.sort((a, b) {
      double distA = sqrt(pow(a.row - startR, 2) + pow(a.col - startC, 2));
      double distB = sqrt(pow(b.row - startR, 2) + pow(b.col - startC, 2));
      return distA.compareTo(distB);
    });

    for (var t in allTiles) {
      t.isMatched = true; // Triggers the pre-explosion swelling animation
      if (allTiles.indexOf(t) % 3 == 0) notifyListeners(); // Optimize frame rates
      await Future.delayed(const Duration(milliseconds: 15)); // Ripple delay
    }
    
    notifyListeners();
    score += 5000;
  }

  Future<void> _activateColorBombSpecialCombo(TileType specialType, int startR, int startC) async {
    await _convertMostFrequentToSpecialTargeted(specialType, startR, startC);
    score += 2000;
  }

  Future<void> _activateDoublePropellerCombo(int startR, int startC) async {
    for (int r = max(0, startR - 1); r <= min(rows - 1, startR + 1); r++) {
      for (int c = max(0, startC - 1); c <= min(cols - 1, startC + 1); c++) {
        if (board[r][c] != null) board[r][c]!.isMatched = true;
      }
    }

    List<Tile> possibleTargets = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null && !board[r][c]!.isMatched && board[r][c]!.type == TileType.normal) {
          possibleTargets.add(board[r][c]!);
        }
      }
    }

    possibleTargets.shuffle();
    int targetsToHit = min(3, possibleTargets.length);
    List<Tile> selectedTargets = possibleTargets.take(targetsToHit).toList();

    for (var target in selectedTargets) {
      target.isTargeted = true;
    }
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500)); 

    for (var target in selectedTargets) {
      target.isTargeted = false;
      target.isMatched = true;
      score += 100;
    }
    score += 500;
  }

  Future<void> _activatePropellerSpecialCombo(int startR, int startC, TileType carriedType) async {
    for (int r = max(0, startR - 1); r <= min(rows - 1, startR + 1); r++) {
      for (int c = max(0, startC - 1); c <= min(cols - 1, startC + 1); c++) {
        if (board[r][c] != null) board[r][c]!.isMatched = true;
      }
    }

    List<Tile> possibleTargets = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null && !board[r][c]!.isMatched && board[r][c]!.type == TileType.normal) {
          possibleTargets.add(board[r][c]!);
        }
      }
    }

    if (possibleTargets.isNotEmpty) {
      possibleTargets.shuffle();
      Tile target = possibleTargets.first;
      
      target.isTargeted = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 600)); 
      
      target.isTargeted = false;
      board[target.row][target.col]!.type = carriedType;
      board[target.row][target.col]!.isMatched = true;
    }
    score += 300;
  }

  Future<bool> executeSpecialCombo(Tile t1, Tile t2) async {
    bool isT1Special = t1.type != TileType.normal;
    bool isT2Special = t2.type != TileType.normal;
    
    if (!isT1Special || !isT2Special) return false;

    t1.isMatched = true;
    t2.isMatched = true;

    if (t1.type == TileType.colorBomb && t2.type == TileType.colorBomb) {
      await _activateDoubleColorBombCombo(t2.row, t2.col);
      return true;
    }

    if (t1.type == TileType.colorBomb || t2.type == TileType.colorBomb) {
      TileType otherType = (t1.type == TileType.colorBomb) ? t2.type : t1.type;
      await _activateColorBombSpecialCombo(otherType, t2.row, t2.col);
      return true;
    }

    if (t1.type == TileType.propeller && t2.type == TileType.propeller) {
      await _activateDoublePropellerCombo(t2.row, t2.col);
      return true;
    }

    bool isT1Propeller = t1.type == TileType.propeller;
    bool isT2Propeller = t2.type == TileType.propeller;
    
    if (isT1Propeller || isT2Propeller) {
      TileType otherType = isT1Propeller ? t2.type : t1.type;
      if (otherType == TileType.stripedHorizontal || otherType == TileType.stripedVertical || otherType == TileType.wrapped) {
        await _activatePropellerSpecialCombo(t2.row, t2.col, otherType);
        return true;
      }
    }

    return false;
  }
}