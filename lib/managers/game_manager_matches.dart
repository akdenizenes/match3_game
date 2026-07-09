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

  // Now async, takes center coordinates, and creates a radial delay
  Future<void> _activateColorBomb(TileColor targetColor, int startR, int startC) async {
    List<Tile> targets = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null && board[r][c]!.color == targetColor) {
          targets.add(board[r][c]!);
        }
      }
    }

    // Sort targets by distance from the activated ColorBomb (Creates a shockwave effect)
    targets.sort((a, b) {
      double distA = sqrt(pow(a.row - startR, 2) + pow(a.col - startC, 2));
      double distB = sqrt(pow(b.row - startR, 2) + pow(b.col - startC, 2));
      return distA.compareTo(distB);
    });

    // Staggered targeting (Chain Lightning effect)
    for (var t in targets) {
      t.isTargeted = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 40)); 
    }
    
    await Future.delayed(const Duration(milliseconds: 200));

    for (var t in targets) {
      t.isTargeted = false;
      t.isMatched = true;
      score += 20;
    }
  }

  bool _checkMatches() {
    bool found = false;
    List<List<bool>> hMatched = List.generate(rows, (_) => List.filled(cols, false));
    List<List<bool>> vMatched = List.generate(rows, (_) => List.filled(cols, false));
    List<List<bool>> sqMatched = List.generate(rows, (_) => List.filled(cols, false)); 

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 2; c++) {
        if (board[r][c] == null || board[r][c]!.type == TileType.colorBomb) continue;
        
        int matchLength = 1;
        while (c + matchLength < cols && 
               board[r][c + matchLength] != null && 
               board[r][c]!.color == board[r][c + matchLength]!.color && 
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
          if (matchLength >= 4) {
            for (int i = 0; i < matchLength; i++) {
              if (board[r][c + i] != null) {
                board[r][c + i]!.mergeTargetRow = r;
                board[r][c + i]!.mergeTargetCol = targetC;
              }
            }
          }
          c += matchLength - 1;
        }
      }
    }

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows - 2; r++) {
        if (board[r][c] == null || board[r][c]!.type == TileType.colorBomb) continue;
        
        int matchLength = 1;
        while (r + matchLength < rows && 
               board[r + matchLength][c] != null && 
               board[r][c]!.color == board[r + matchLength][c]!.color && 
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
          if (matchLength >= 4) {
            for (int i = 0; i < matchLength; i++) {
              if (board[r + i][c] != null) {
                board[r + i][c]!.mergeTargetRow = targetR;
                board[r + i][c]!.mergeTargetCol = c;
              }
            }
          }
          r += matchLength - 1;
        }
      }
    }

    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols - 1; c++) {
        var t1 = board[r][c];
        var t2 = board[r][c + 1];
        var t3 = board[r + 1][c];
        var t4 = board[r + 1][c + 1];

        if (t1 == null || t1.type == TileType.colorBomb) continue;

        if (t2 != null && t3 != null && t4 != null &&
            t1.color == t2.color && t1.color == t3.color && t1.color == t4.color &&
            t2.type != TileType.colorBomb && t3.type != TileType.colorBomb && t4.type != TileType.colorBomb) {
          
          found = true;
          int targetR = r;
          int targetC = c;

          if (lastSwapRow == r && lastSwapCol == c) { targetR = r; targetC = c; }
          else if (lastSwapRow == r && lastSwapCol == c + 1) { targetR = r; targetC = c + 1; }
          else if (lastSwapRow == r + 1 && lastSwapCol == c) { targetR = r + 1; targetC = c; }
          else if (lastSwapRow == r + 1 && lastSwapCol == c + 1) { targetR = r + 1; targetC = c + 1; }

          sqMatched[r][c] = true;
          sqMatched[r][c + 1] = true;
          sqMatched[r + 1][c] = true;
          sqMatched[r + 1][c + 1] = true;

          if (board[targetR][targetC]!.typeToBecome == null) {
            board[targetR][targetC]!.typeToBecome = TileType.propeller;
          }

          t1.mergeTargetRow = targetR; t1.mergeTargetCol = targetC;
          t2.mergeTargetRow = targetR; t2.mergeTargetCol = targetC;
          t3.mergeTargetRow = targetR; t3.mergeTargetCol = targetC;
          t4.mergeTargetRow = targetR; t4.mergeTargetCol = targetC;
        }
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (hMatched[r][c] || vMatched[r][c] || sqMatched[r][c]) {
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
    
    List<Future<void>> pendingFlights = []; 

    do {
      specialTriggered = false;
      bool hasSpecialExplosion = false; 
      safeLoopLimit++;
      if (safeLoopLimit > 50) break;

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (board[r][c] != null && board[r][c]!.isMatched) {
            
            if (board[r][c]!.type == TileType.stripedHorizontal) {
              board[r][c]!.type = TileType.normal; 
              hasSpecialExplosion = true; 
              for (int i = 0; i < cols; i++) {
                if (board[r][i] != null && !board[r][i]!.isMatched) {
                  board[r][i]!.isMatched = true; 
                  specialTriggered = true;
                }
              }
            }
            else if (board[r][c]!.type == TileType.stripedVertical) {
              board[r][c]!.type = TileType.normal;
              hasSpecialExplosion = true;
              for (int i = 0; i < rows; i++) {
                if (board[i][c] != null && !board[i][c]!.isMatched) {
                  board[i][c]!.isMatched = true;
                  specialTriggered = true;
                }
              }
            }
            else if (board[r][c]!.type == TileType.wrapped) {
              board[r][c]!.type = TileType.normal;
              hasSpecialExplosion = true;
              for (int i = max(0, r - 1); i <= min(rows - 1, r + 1); i++) {
                for (int j = max(0, c - 1); j <= min(cols - 1, c + 1); j++) {
                  if (board[i][j] != null && !board[i][j]!.isMatched) {
                    board[i][j]!.isMatched = true;
                    specialTriggered = true;
                  }
                }
              }
            }
            else if (board[r][c]!.type == TileType.propeller) {
              board[r][c]!.type = TileType.normal;
              hasSpecialExplosion = true;
              
              for (int i = max(0, r - 1); i <= min(rows - 1, r + 1); i++) {
                for (int j = max(0, c - 1); j <= min(cols - 1, c + 1); j++) {
                  if ((i == r || j == c) && board[i][j] != null && !board[i][j]!.isMatched) {
                    board[i][j]!.isMatched = true;
                    specialTriggered = true;
                  }
                }
              }
              pendingFlights.add(_triggerPropellerFlightAsync());
            }
          }
        }
      }

      if (hasSpecialExplosion) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 250));
      }

    } while (specialTriggered);

    if (pendingFlights.isNotEmpty) {
      await Future.wait(pendingFlights);
    }

    bool hasExplosions = false; 
    List<Offset> explosionPoints = []; 

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null && board[r][c]!.isMatched) {
          if (board[r][c]!.typeToBecome != null) {
            board[r][c]!.type = board[r][c]!.typeToBecome!;
            board[r][c]!.typeToBecome = null;
            board[r][c]!.isMatched = false;

            // YENİ: Dönüşen özel taşların (çizgili, pervane vb.) renklerini 'none' yaparak bağımsızlaştırıyoruz
            if (board[r][c]!.type != TileType.normal) {
              board[r][c]!.color = TileColor.none;
            }

            board[r][c]!.mergeTargetRow = null;
            board[r][c]!.mergeTargetCol = null;
            score += 50;
          } else {
            // YENİ: Sadece gerçek renge sahip taşları toplananlar listesine ekle
            if (board[r][c]!.color != TileColor.none) {
              collectedColors[board[r][c]!.color] = (collectedColors[board[r][c]!.color] ?? 0) + 1;
            }
            
            if (board[r][c]!.mergeTargetRow != null && board[r][c]!.mergeTargetCol != null) {
              board[r][c]!.row = board[r][c]!.mergeTargetRow!;
              board[r][c]!.col = board[r][c]!.mergeTargetCol!;
            }
            
            board[r][c]!.isExploding = true;
            hasExplosions = true;
            explosionPoints.add(Offset(c.toDouble(), r.toDouble())); 
            
            score += 10;
          }
        }
      }
    }

    if (hasExplosions) {
      if (onExplosion != null) onExplosion!(explosionPoints);
      notifyListeners(); 
      await Future.delayed(const Duration(milliseconds: 250)); 
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (board[r][c] != null && board[r][c]!.isExploding) {
            board[r][c] = null;
          }
        }
      }
    }

    notifyListeners();
    if (!hasExplosions) await Future.delayed(const Duration(milliseconds: 200));

    // Düşme mantığı
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

    // YENİ: Tahtaya yeni düşecek taşlarda asla 'none' (renksiz) taş gelmesini istemiyoruz
    final random = Random();
    final playableColors = TileColor.values.where((c) => c != TileColor.none).toList();
    
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (board[r][c] == null) {
          board[r][c] = Tile(
            id: 'new_${r}_${c}_${random.nextInt(100000)}',
            color: playableColors[random.nextInt(playableColors.length)], // Güncellendi
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
  }

  // Uses the centralized isPriorityTarget system to find goals
  Future<void> _triggerPropellerFlightAsync() async {
    List<Tile> priorityTargets = [];
    List<Tile> normalTargets = [];
    
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        Tile? currentTile = board[r][c];
        
        // Exclude already matched, targeted, or other propeller tiles
        if (currentTile != null && !currentTile.isMatched && !currentTile.isTargeted && currentTile.type != TileType.propeller) {
          
          // Check if this tile is a priority goal (e.g. pink candy)
          if (isPriorityTarget(currentTile)) {
            priorityTargets.add(currentTile);
          } else if (currentTile.type == TileType.normal) {
            normalTargets.add(currentTile); // Fallback target
          }
          
        }
      }
    }

    // Select target based on priority
    Tile? selectedTarget;
    if (priorityTargets.isNotEmpty) {
      priorityTargets.shuffle(); 
      selectedTarget = priorityTargets.first;
    } else if (normalTargets.isNotEmpty) {
      normalTargets.shuffle(); 
      selectedTarget = normalTargets.first;
    }

    // Trigger flight animation and destroy target
    if (selectedTarget != null) {
      selectedTarget.isTargeted = true;
      notifyListeners(); 
      
      await Future.delayed(const Duration(milliseconds: 500)); 
      
      selectedTarget.isTargeted = false;
      selectedTarget.isMatched = true; 
    }
  }
}