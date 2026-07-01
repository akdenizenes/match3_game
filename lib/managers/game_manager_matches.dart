part of 'game_manager.dart';

extension GameManagerMatches on GameManager {

  void _activateDoubleWrappedCombo(int rowIdx, int colIdx) {
    for (int r = max(0, rowIdx - 4); r <= min(rows - 1, rowIdx + 4); r++) {
      for (int c = max(0, colIdx - 4); c <= min(cols - 1, colIdx + 4); c++) {
        if (board[r][c] != null) board[r][c]!.isMatched = true;
      }
    }
    score += 1000;
  }

  void _activateStripedWrappedCombo(int rowIdx, int colIdx) {
    for (int r = max(0, rowIdx - 1); r <= min(rows - 1, rowIdx + 1); r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null) board[r][c]!.isMatched = true;
      }
    }
    for (int c = max(0, colIdx - 1); c <= min(cols - 1, colIdx + 1); c++) {
      for (int r = 0; r < rows; r++) {
        if (board[r][c] != null) board[r][c]!.isMatched = true;
      }
    }
    score += 800;
  }

  void _activateColorBombWrappedCombo() {
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
    counts.forEach((k, v) { if (v > maxC) { maxC = v; mostColor = k; } });

    if (mostColor != null) {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (board[r][c] != null && board[r][c]!.color == mostColor) {
            board[r][c]!.type = TileType.wrapped;
            board[r][c]!.isMatched = true;
          }
        }
      }
    }
    score += 1200;
  }

  void _activateColorBomb(TileColor targetColor) {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null && board[r][c]!.color == targetColor) {
          board[r][c]!.isMatched = true;
          score += 20;
        }
      }
    }
  }

bool _checkMatches() {
    bool found = false;
    List<List<bool>> hMatched = List.generate(rows, (_) => List.filled(cols, false));
    List<List<bool>> vMatched = List.generate(rows, (_) => List.filled(cols, false));

    // Yatay Eşleşme Kontrolü
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 2; c++) {
        // DEĞİŞİKLİK: Sadece normal taşları değil, colorBomb haricindeki her taşı kontrol et.
        if (board[r][c] == null || board[r][c]!.type == TileType.colorBomb) continue;
        
        int matchLength = 1;
        while (c + matchLength < cols && 
               board[r][c + matchLength] != null && 
               board[r][c]!.color == board[r][c + matchLength]!.color && 
               // DEĞİŞİKLİK: Yanındaki taş da colorBomb değilse eşleşmeye dahil et.
               board[r][c + matchLength]!.type != TileType.colorBomb) {
          matchLength++;
        }

        if (matchLength >= 3) {
          found = true;
          int targetC = c + matchLength ~/ 2; 
          
          for (int i = 0; i < matchLength; i++) {
            hMatched[r][c + i] = true;
            if (lastSwapRow == r && lastSwapCol == c + i) targetC = c + i;
          }
          
          if (matchLength >= 5) {
            board[r][targetC]!.typeToBecome = TileType.colorBomb;
          } else if (matchLength == 4) {
            board[r][targetC]!.typeToBecome = TileType.stripedVertical;
          }
          c += matchLength - 1;
        }
      }
    }

    // Dikey Eşleşme Kontrolü
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows - 2; r++) {
        // DEĞİŞİKLİK: Sadece normal taşları değil, colorBomb haricindeki her taşı kontrol et.
        if (board[r][c] == null || board[r][c]!.type == TileType.colorBomb) continue;
        
        int matchLength = 1;
        while (r + matchLength < rows && 
               board[r + matchLength][c] != null && 
               board[r][c]!.color == board[r + matchLength][c]!.color && 
               // DEĞİŞİKLİK: Yanındaki taş da colorBomb değilse eşleşmeye dahil et.
               board[r + matchLength][c]!.type != TileType.colorBomb) {
          matchLength++;
        }

        if (matchLength >= 3) {
          found = true;
          int targetR = r + matchLength ~/ 2;
          
          for (int i = 0; i < matchLength; i++) {
            vMatched[r + i][c] = true;
            if (lastSwapRow == r + i && lastSwapCol == c) targetR = r + i;
          }

          if (matchLength >= 5) {
            board[targetR][c]!.typeToBecome = TileType.colorBomb;
          } else if (matchLength == 4 && board[targetR][c]!.typeToBecome == null) {
            board[targetR][c]!.typeToBecome = TileType.stripedHorizontal;
          }
          r += matchLength - 1;
        }
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (hMatched[r][c] || vMatched[r][c]) {
          if (board[r][c] != null) {
            board[r][c]!.isMatched = true;

            if (board[r][c]!.typeToBecome == null && hMatched[r][c] && vMatched[r][c]) {
              board[r][c]!.typeToBecome = TileType.wrapped;
            }
          }
        }
      }
    }
    return found;
  }

Future<void> _processMatches({int cascadeDepth = 0}) async {
    bool specialTriggered;
    int safeLoopLimit = 0;

    do {
      specialTriggered = false;
      safeLoopLimit++;
      if (safeLoopLimit > 50) break;

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          // KRİTİK DEĞİŞİKLİK: Burada sadece 'isMatched' olanları değil, 
          // özel yeteneği olanları ÖNCELİKLİ tetikliyoruz.
          if (board[r][c] != null && board[r][c]!.isMatched) {
            
            // 1. ÖNCE ÖZEL TAŞIN KENDİ ETKİSİNİ TETİKLE (Eğer hala special ise)
            if (board[r][c]!.type == TileType.stripedHorizontal) {
              board[r][c]!.type = TileType.normal; // Patladı, normale döndü
              for (int i = 0; i < cols; i++) {
                if (board[r][i] != null && !board[r][i]!.isMatched) {
                  board[r][i]!.isMatched = true; // Yanındakini de patlat
                  specialTriggered = true;
                }
              }
            }
            else if (board[r][c]!.type == TileType.stripedVertical) {
              board[r][c]!.type = TileType.normal;
              for (int i = 0; i < rows; i++) {
                if (board[i][c] != null && !board[i][c]!.isMatched) {
                  board[i][c]!.isMatched = true;
                  specialTriggered = true;
                }
              }
            }
            else if (board[r][c]!.type == TileType.wrapped) {
              board[r][c]!.type = TileType.normal;
              for (int i = max(0, r - 1); i <= min(rows - 1, r + 1); i++) {
                for (int j = max(0, c - 1); j <= min(cols - 1, c + 1); j++) {
                  if (board[i][j] != null && !board[i][j]!.isMatched) {
                    board[i][j]!.isMatched = true;
                    specialTriggered = true;
                  }
                }
              }
            }

          }
        }
      }
    } while (specialTriggered);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null && board[r][c]!.isMatched) {
          if (board[r][c]!.typeToBecome != null) {
            board[r][c]!.type = board[r][c]!.typeToBecome!;
            board[r][c]!.typeToBecome = null;
            board[r][c]!.isMatched = false;
            score += 50;
          } else {
            collectedColors[board[r][c]!.color] = (collectedColors[board[r][c]!.color] ?? 0) + 1;
            board[r][c] = null;
            score += 10;
          }
        }
      }
    }
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));

    for (int c = 0; c < cols; c++) {
      int emptySpaces = 0;
      for (int r = rows - 1; r >= 0; r--) {
        if (board[r][c] == null) {
          emptySpaces++;
        } else if (emptySpaces > 0) {
          board[r + emptySpaces][c] = board[r][c];
          board[r + emptySpaces][c]!.row = r + emptySpaces;
          board[r][c] = null;
        }
      }
    }
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));

    final random = Random();
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (board[r][c] == null) {
          board[r][c] = Tile(
            id: 'new_${r}_${c}_${random.nextInt(100000)}',
            color: TileColor.values[random.nextInt(TileColor.values.length)],
            row: r,
            col: c,
          );
        }
      }
    }
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));

    if (cascadeDepth < 20 && _checkMatches()) {
      await _processMatches(cascadeDepth: cascadeDepth + 1);
    }
    if (cascadeDepth < 20 && _checkMatches()) {
      await _processMatches(cascadeDepth: cascadeDepth + 1);
    }
  }
}