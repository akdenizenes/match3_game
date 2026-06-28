import 'package:flutter/material.dart';
import 'dart:math';
import '../models/tile.dart';
import '../models/level_data.dart';

enum GameState { playing, won, lost }

class GameManager extends ChangeNotifier {
  final int rows = 8;
  final int cols = 8;
  List<List<Tile?>> board = [];
  
  int score = 0;
  int moves = 0;
  bool isAnimating = false;

  int? lastSwapRow;
  int? lastSwapCol;

  late LevelData currentLevel;
  Map<TileColor, int> collectedColors = {};
  GameState gameState = GameState.playing;

  GameManager() {
    _loadLevel(1);
  }

  // --- 6'LIK KURALA GÖRE DÖNGÜSEL BÖLÜM MOTORU ---
  LevelData _generateLevelData(int levelNum) {
    int cycle = (levelNum - 1) ~/ 6; 
    int step = (levelNum - 1) % 6;   

    int baseTarget = 15 + (cycle * 5); 
    int baseScore = 2000 + (cycle * 1500); 
    int moveCount = 25 - (cycle > 4 ? 5 : cycle); 

    List<TileColor> getRandomColors(int count) {
      List<TileColor> colors = TileColor.values.toList();
      colors.shuffle();
      return colors.take(count).toList();
    }

    if (step >= 0 && step <= 2) {
      if (step == 0) {
        return LevelData(levelNumber: levelNum, maxMoves: moveCount + 2, targetColors: {getRandomColors(1)[0]: baseTarget});
      } else if (step == 1) {
        var cls = getRandomColors(2);
        return LevelData(levelNumber: levelNum, maxMoves: moveCount, targetColors: {cls[0]: baseTarget, cls[1]: baseTarget});
      } else {
        // DÜZELTME: Sadece skor değil, artık 1 tane de renk hedefi var
        var cls = getRandomColors(1);
        return LevelData(levelNumber: levelNum, maxMoves: moveCount, targetScore: baseScore, targetColors: {cls[0]: baseTarget + 5});
      }
    } 
    else if (step == 3 || step == 4) {
      // ORTA (4 ve 5. Bölümler: Hedefler ve Skor Büyür)
      int medTarget = baseTarget + 8;
      var cls = getRandomColors(2);
      return LevelData(levelNumber: levelNum, maxMoves: moveCount - 2, targetScore: baseScore, targetColors: {cls[0]: medTarget, cls[1]: medTarget});
    } 
    else {
      // ZOR (6. Bölüm: Boss Seviyesi - 3 Renk Birden Toplama ve Yüksek Skor)
      int hardTarget = baseTarget + 15;
      var cls = getRandomColors(3);
      return LevelData(
        levelNumber: levelNum, 
        maxMoves: moveCount - 4, 
        targetScore: baseScore * 2, 
        targetColors: {cls[0]: hardTarget, cls[1]: hardTarget, cls[2]: hardTarget}
      );
    }
  }

  void _loadLevel(int levelNum) {
    currentLevel = _generateLevelData(levelNum);
    moves = currentLevel.maxMoves;
    score = 0;
    collectedColors.clear();
    gameState = GameState.playing;
    _initializeBoard();
  }

  // --- AÇILIŞTA OTOMATİK PATLAMALARI ENGELLEYEN YÜKLEME ---
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
          
          // Ana board boş olduğu için oluşturduğumuz temp listelere bakıyoruz
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
    
    // Tahta tamamen hatasız oluştuktan sonra ana board'a eşitliyoruz
    board = tempBoard;
    notifyListeners();
  }

  void nextLevel() { _loadLevel(currentLevel.levelNumber + 1); }
  void retryLevel() { _loadLevel(currentLevel.levelNumber); }

  // --- ÖZEL TAŞLARA DİREKT TIKLAYINCA (onTap) PATLAMA GÜCÜ ---
  Future<void> tapTile(int r, int c) async {
    if (isAnimating || gameState != GameState.playing) return;
    Tile? tile = board[r][c];
    if (tile == null || tile.type == TileType.normal) return;

    isAnimating = true;
    moves--;

    if (tile.type == TileType.colorBomb) {
      TileColor randomColor = TileColor.values[Random().nextInt(TileColor.values.length)];
      _activateColorBomb(randomColor);
    }

    tile.isMatched = true;
    await _processMatches();
    _checkWinCondition();
    isAnimating = false;
    notifyListeners();
  }

  // --- KAYDIRILINCA KURAL ARANMAYAN KOMBO SİSTEMİ ---
  Future<void> swapTiles(int r1, int c1, int r2, int c2) async {
    if (isAnimating || gameState != GameState.playing) return;
    isAnimating = true;
    moves--;
    
    lastSwapRow = r2; 
    lastSwapCol = c2;

    Tile? t1 = board[r1][c1];
    Tile? t2 = board[r2][c2];

    board[r1][c1] = t2;
    board[r2][c2] = t1;
    t2?.row = r1; t2?.col = c1;
    t1?.row = r2; t1?.col = c2;
    
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    // Büyük İkili Kombo Kontrolleri
    if (t1 != null && t2 != null && t1.type != TileType.normal && t2.type != TileType.normal) {
      bool comboTriggered = false;

      if (t1.type == TileType.wrapped && t2.type == TileType.wrapped) {
        // BOMBA + BOMBA (80 karo devasa temizlik)
        _activateDoubleWrappedCombo(r2, c2);
        comboTriggered = true;
      } 
      else if ((t1.type == TileType.wrapped && (t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical)) ||
               (t2.type == TileType.wrapped && (t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical))) {
        // BOMBA + ROKET (Yatay ve dikey 3 sıra/sütun temizliği)
        _activateStripedWrappedCombo(r2, c2);
        comboTriggered = true;
      }
    
      else if ((t1.type == TileType.colorBomb && t2.type == TileType.wrapped) || 
               (t2.type == TileType.colorBomb && t1.type == TileType.wrapped)) {
        // BOMBA + IŞIK TOPU (En çok bulunan rengi bombaya dönüştürme)
        _activateColorBombWrappedCombo();
        comboTriggered = true;
      }
      // ROKET + ROKET (Yeni eklendi)
      else if ((t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical) && 
               (t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical)) {
        for (int i = 0; i < cols; i++) if (board[r2][i] != null) board[r2][i]!.isMatched = true;
        for (int i = 0; i < rows; i++) if (board[i][c2] != null) board[i][c2]!.isMatched = true;
        comboTriggered = true;
      }
      // IŞIK TOPU + ROKET / TNT (Sadece normal özel taşları dönüştürsün)
      else if (t1.type == TileType.colorBomb && (t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical || t2.type == TileType.wrapped)) { 
        _convertMostFrequentToSpecial(t2.type); 
        comboTriggered = true; 
      }
      else if (t2.type == TileType.colorBomb && (t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical || t1.type == TileType.wrapped)) { 
        _convertMostFrequentToSpecial(t1.type); 
        comboTriggered = true; 
      }
      
      else if (t1.type == TileType.colorBomb && t2.type == TileType.colorBomb) {
        // IŞIK TOPU + IŞIK TOPU (Tüm ekranı yok etme)
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            if (board[r][c] != null) board[r][c]!.isMatched = true;
          }
        }
        comboTriggered = true;
      }
      
      if (comboTriggered) {
        t1.isMatched = true;
        t2.isMatched = true;
        await _processMatches();
        _checkWinCondition();
        isAnimating = false;
        notifyListeners();
        return;
      }
    }

    // Tekli Işık Topu Kaydırma Kullanımı
    if (t1 != null && t2 != null && (t1.type == TileType.colorBomb || t2.type == TileType.colorBomb)) {
      Tile bomb = t1.type == TileType.colorBomb ? t1 : t2;
      Tile target = t1.type == TileType.colorBomb ? t2 : t1;
      _activateColorBomb(target.color);
      bomb.isMatched = true;
      await _processMatches();
      _checkWinCondition();
      isAnimating = false;
      notifyListeners();
      return;
    }

    // Herhangi bir özel taş kaydırıldıysa kural aranmadan tetiği çek
    bool isT1Special = t1?.type == TileType.stripedHorizontal || t1?.type == TileType.stripedVertical || t1?.type == TileType.wrapped;
    bool isT2Special = t2?.type == TileType.stripedHorizontal || t2?.type == TileType.stripedVertical || t2?.type == TileType.wrapped;

    if (isT1Special || isT2Special) {
      if (isT1Special) t1!.isMatched = true;
      if (isT2Special) t2!.isMatched = true;
      _checkMatches(); 
      await _processMatches();
      _checkWinCondition();
      isAnimating = false;
      notifyListeners();
      return;
    }

    // Normal Taşlar İçin Eşleşme Taraması
    bool matchFound = _checkMatches();

    if (!matchFound) {
      board[r1][c1] = t1;
      board[r2][c2] = t2;
      t1?.row = r1; t1?.col = c1;
      t2?.row = r2; t2?.col = c2;
      moves++;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
    } else {
      await _processMatches();
      _checkWinCondition();
    }

    isAnimating = false;
    notifyListeners();
  }

  // --- KOMBO TETİKLEYİCİ METOTLARI ---
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

  // --- T VE L KESİŞİM ALGILAYAN GELİŞMİŞ EŞLEŞME TARAYICI ---
  bool _checkMatches() {
    bool found = false;
    List<List<bool>> hMatched = List.generate(rows, (_) => List.filled(cols, false));
    List<List<bool>> vMatched = List.generate(rows, (_) => List.filled(cols, false));
    List<List<bool>> isColorBombTarget = List.generate(rows, (_) => List.filled(cols, false));

    // Yatay Tarama Döngüsü
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 2; c++) {
        if (board[r][c] == null) continue;
        int matchLength = 1;
        while (c + matchLength < cols && board[r][c + matchLength] != null && board[r][c]!.color == board[r][c + matchLength]!.color) {
          matchLength++;
        }

        if (matchLength >= 3) {
          found = true;
          for (int i = 0; i < matchLength; i++) {
            hMatched[r][c + i] = true;
            if (matchLength >= 5) isColorBombTarget[r][c + i] = true;
          }
          if (matchLength == 4) {
            int targetC = c + matchLength ~/ 2;
            for (int i = 0; i < matchLength; i++) {
              if (lastSwapRow == r && lastSwapCol == c + i) targetC = c + i;
            }
            board[r][targetC]!.typeToBecome = TileType.stripedVertical;
          }
          c += matchLength - 1;
        }
      }
    }

    // Dikey Tarama Döngüsü
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows - 2; r++) {
        if (board[r][c] == null) continue;
        int matchLength = 1;
        while (r + matchLength < rows && board[r + matchLength][c] != null && board[r][c]!.color == board[r + matchLength][c]!.color) {
          matchLength++;
        }

        if (matchLength >= 3) {
          found = true;
          for (int i = 0; i < matchLength; i++) {
            vMatched[r + i][c] = true;
            if (matchLength >= 5) isColorBombTarget[r + i][c] = true;
          }
          if (matchLength == 4) {
            int targetR = r + matchLength ~/ 2;
            for (int i = 0; i < matchLength; i++) {
              if (lastSwapRow == r + i && lastSwapCol == c) targetR = r + i;
            }
            if (board[targetR][c]!.typeToBecome == null) board[targetR][c]!.typeToBecome = TileType.stripedHorizontal;
          }
          r += matchLength - 1;
        }
      }
    }

    // T/L Kesişimlerini Filtreleme ve İşaretleme
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (hMatched[r][c] || vMatched[r][c]) {
          board[r][c]!.isMatched = true;

          if (isColorBombTarget[r][c]) {
            board[r][c]!.typeToBecome = TileType.colorBomb;
          } 
          else if (hMatched[r][c] && vMatched[r][c]) {
            board[r][c]!.typeToBecome = TileType.wrapped; // Kesişimler dinamite döner
          }
        }
      }
    }
    return found;
  }

  // --- ZİNCİRLEME REAKSİYON SİMÜLASYONU VE DÜŞME MOTORU ---
  Future<void> _processMatches() async {
    bool specialTriggered;
    do {
      specialTriggered = false;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (board[r][c] != null && board[r][c]!.isMatched && board[r][c]!.typeToBecome == null) {
            
            // Dikey / Yatay Roket Ateşlemesi
            if (board[r][c]!.type == TileType.stripedHorizontal) {
              board[r][c]!.type = TileType.normal;
              for (int i = 0; i < cols; i++) {
                if (board[r][i] != null && !board[r][i]!.isMatched) {
                  board[r][i]!.isMatched = true;
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
            // Dinamit Patlaması (3x3 Çevre Yok Etme)
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

    // Taşları Tahtadan Silme veya Dönüştürme
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

    // Yerçekimi İle Hücreleri Aşağı Kaydırma
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

    // Tavandan Yeni Kristalleri Düşürme
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

    // Zincirleme Eşleşme Kontrolü (Kombo Şelalesi)
    if (_checkMatches()) {
      await _processMatches();
    }
  }

  void _checkWinCondition() {
    bool isWon = true;
    if (currentLevel.targetScore != null && score < currentLevel.targetScore!) isWon = false;
    
    if (currentLevel.targetColors != null) {
      currentLevel.targetColors!.forEach((color, targetAmount) {
        if ((collectedColors[color] ?? 0) < targetAmount) isWon = false;
      });
    }

    if (isWon) {
      gameState = GameState.won;
    } else if (moves <= 0) {
      gameState = GameState.lost;
    }
    notifyListeners();
  }
  // ... Yukarıda _processMatches() gibi fonksiyonlar var ...


  // BURAYA YAPIŞTIRIYORSUN AYNEN ŞU ŞEKİLDE:

  // --- GÜÇLENDİRİCİLER (HAMLE HARCAMAZ) ---

  // 1. Kraliyet Çekici: Tek bir karoyu kırar
  Future<void> useRoyalHammer(int r, int c) async {
    if (board[r][c] != null) {
      board[r][c]!.isMatched = true;
      await _processMatches();
      _checkWinCondition();
    }
  }

  // 2. Ok İşareti: Seçilen yatay satırı temizler
  Future<void> useArrowBooster(int r) async {
    for (int c = 0; c < cols; c++) {
      if (board[r][c] != null) board[r][c]!.isMatched = true;
    }
    await _processMatches();
    _checkWinCondition();
  }

  // 3. Top: Seçilen dikey sütunu temizler
  Future<void> useCannonBooster(int c) async {
    for (int r = 0; r < rows; r++) {
      if (board[r][c] != null) board[r][c]!.isMatched = true;
    }
    await _processMatches();
    _checkWinCondition();
  }

  // 4. Soytarı Şapkası: Tahtayı karıştırır
  void useJesterHat() {
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
  }
  // --- YARDIMCI METOT: EN ÇOK BULUNAN RENGİ ÖZEL TAŞA DÖNÜŞTÜR ---
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
} // <--- Bu GameManager sınıfının en sonundaki kapanış parantezidir!



