import 'package:flutter/material.dart';
import 'dart:math';
import '../models/tile.dart';
import '../models/level_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ALT DOSYALARI SİSTEME BAĞLIYORUZ ---
part 'game_manager_board.dart';
part 'game_manager_matches.dart';
part 'game_manager_powerups.dart';

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

  // --- YENİ EKLENDİ: GÜÇLENDİRİCİ ENVANTERİ ---
  Map<String, int> powerUpCounts = {
    'hammer': 10,
    'arrow': 10,
    'cannon': 10,
    'jester': 10,
  };

  // --- GÜÇLENDİRİCİ BEKLEME STATE'LERİ ---
  bool isPowerUpWaiting = false;
  String? activePowerUpType; 

  // --- YENİ EKLENDİ: GÜÇLENDİRİCİ KULLANMA KONTROLÜ ---
  bool consumePowerUp(String type) {
    if ((powerUpCounts[type] ?? 0) > 0) {
      powerUpCounts[type] = powerUpCounts[type]! - 1;
      saveData();
      notifyListeners();
      return true; // Kullanıma izin ver
    }
    return false; // Bittiği için izin verme
  }


  void preparePowerUp(String type) {
    
    isPowerUpWaiting = true;
    activePowerUpType = type;
    notifyListeners();
  }

  late LevelData currentLevel;
  Map<TileColor, int> collectedColors = {};
  GameState gameState = GameState.playing;

GameManager() {
    _loadLevel(1);
    _initGame();
  }

  // Oyunu açtığında telefondan eski verileri çeker
  Future<void> _initGame() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Telefondaki kayıtlı bölümü al, yoksa 1. bölümden başlat
    int savedLevel = prefs.getInt('current_level') ?? 1;
    
    // Güçlendiricileri telefondan al, yoksa başlangıç olarak 10 ver
    powerUpCounts['hammer'] = prefs.getInt('pu_hammer') ?? 10;
    powerUpCounts['arrow'] = prefs.getInt('pu_arrow') ?? 10;
    powerUpCounts['cannon'] = prefs.getInt('pu_cannon') ?? 10;
    powerUpCounts['jester'] = prefs.getInt('pu_jester') ?? 10;

    _loadLevel(savedLevel);
    notifyListeners();
  }

  // Her önemli olayda verileri telefona kaydeder
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level', currentLevel.levelNumber);
    await prefs.setInt('pu_hammer', powerUpCounts['hammer'] ?? 0);
    await prefs.setInt('pu_arrow', powerUpCounts['arrow'] ?? 0);
    await prefs.setInt('pu_cannon', powerUpCounts['cannon'] ?? 0);
    await prefs.setInt('pu_jester', powerUpCounts['jester'] ?? 0);
  }

  // --- YENİ EKLENDİ: SEVİYE SONU ÖDÜL SİSTEMİ ---
  void checkLevelReward(int completedLevel) {
    // DÜZELTME: Döngü 15'e çıkarıldığı için mod alma işlemi % 15 yapıldı!
    int cycle = completedLevel % 15; 
    if (completedLevel % 15 == 0) cycle = 15; 

    if (cycle == 5) {
      powerUpCounts['hammer'] = (powerUpCounts['hammer'] ?? 0) + 1;
    } else if (cycle == 8) {
      powerUpCounts['arrow'] = (powerUpCounts['arrow'] ?? 0) + 1;
    } else if (cycle == 10) {
      powerUpCounts['cannon'] = (powerUpCounts['cannon'] ?? 0) + 1;
    } else if (cycle == 13) {
      powerUpCounts['jester'] = (powerUpCounts['jester'] ?? 0) + 1; 
    } else if (cycle == 15) {
      // 15. bölümde (ve katlarında) hepsinden 1'er tane bonus!
      powerUpCounts['hammer'] = (powerUpCounts['hammer'] ?? 0) + 1;
      powerUpCounts['arrow'] = (powerUpCounts['arrow'] ?? 0) + 1;
      powerUpCounts['cannon'] = (powerUpCounts['cannon'] ?? 0) + 1;
      powerUpCounts['jester'] = (powerUpCounts['jester'] ?? 0) + 1;
    }
    
    saveData(); // <-- ADIM 3: Ödül verildikten sonra telefona kaydeder
    notifyListeners();
  }

  // --- DİNAMİK ZORLUK VE HAMLE MOTORU ---
  LevelData _generateLevelData(int levelNum) {
    int cycle = (levelNum - 1) ~/ 6; 
    int step = (levelNum - 1) % 6;   

    // Taban hedefler döngüye göre artar
    int baseTarget = 15 + (cycle * 5); 
    int baseScore = 2000 + (cycle * 1500); 

    List<TileColor> getRandomColors(int count) {
      List<TileColor> colors = TileColor.values.toList();
      colors.shuffle();
      return colors.take(count).toList();
    }

    Map<TileColor, int> levelTargets = {};
    int? currentTargetScore;

    // 1. AŞAMA: ÖNCE BÖLÜMÜN HEDEFLERİNİ BELİRLE
    if (step >= 0 && step <= 2) {
      if (step == 0) {
        levelTargets = {getRandomColors(1)[0]: baseTarget};
      } else if (step == 1) {
        var cls = getRandomColors(2);
        levelTargets = {cls[0]: baseTarget, cls[1]: baseTarget};
      } else {
        var cls = getRandomColors(1);
        levelTargets = {cls[0]: baseTarget + 5};
        currentTargetScore = baseScore;
      }
    } 
    else if (step == 3 || step == 4) {
      int medTarget = baseTarget + 8;
      var cls = getRandomColors(2);
      levelTargets = {cls[0]: medTarget, cls[1]: medTarget};
      currentTargetScore = baseScore;
    } 
    else {
      int hardTarget = baseTarget + 15;
      var cls = getRandomColors(3);
      levelTargets = {cls[0]: hardTarget, cls[1]: hardTarget, cls[2]: hardTarget};
      currentTargetScore = baseScore * 2; // Boss seviyesinde çift skor
    }

    // 2. AŞAMA: DİNAMİK HAMLE HESAPLAMA (Makine Öğrenimi Mantığı)
    int totalRequiredTiles = 0;
    levelTargets.forEach((color, amount) {
      totalRequiredTiles += amount;
    });

    // Formül: Toplam toplanacak taşların %40'ı + 10 taban hamle
    // Örnek: (30 taş * 0.4) = 12 + 10 = 22 Hamle.
    int calculatedMoves = (totalRequiredTiles * 0.4).ceil() + 10;
    
    // Eğer bölüm bizden yüksek skor yapmamızı da istiyorsa ekstra 3 hamle ateşle
    if (currentTargetScore != null) {
       calculatedMoves += 3;
    }
    
    // Oyuncu seviyeleri geçtikçe (cycle arttıkça) hata payını kıs, oyuncuyu terlet
    if (cycle > 0) {
       calculatedMoves -= cycle * 2; 
    }

    // Güvenlik Kilidi: Ne olursa olsun hiçbir bölüm 10 hamleden az olamaz
    if (calculatedMoves < 10) calculatedMoves = 10;

    return LevelData(
      levelNumber: levelNum, 
      maxMoves: calculatedMoves, // Hamle artık yapay olarak hesaplanıyor!
      targetScore: currentTargetScore, 
      targetColors: levelTargets
    );
  }

  void _loadLevel(int levelNum) {
    currentLevel = _generateLevelData(levelNum);
    moves = currentLevel.maxMoves;
    score = 0;
    collectedColors.clear();
    gameState = GameState.playing;
    _initializeBoard();
  }

  void nextLevel() { _loadLevel(currentLevel.levelNumber + 1); saveData(); }
  void retryLevel() { _loadLevel(currentLevel.levelNumber); }

  void _checkWinCondition() {
     bool isWon = true;
     if (currentLevel.targetScore != null && score < currentLevel.targetScore!) isWon = false;
    
      if (currentLevel.targetColors != null) {
        currentLevel.targetColors!.forEach((color, targetAmount) {
          if ((collectedColors[color] ?? 0) < targetAmount) isWon = false;
        });
      }

      // --- KRİTİK SIRALAMA DEĞİŞİKLİĞİ ---
      // 1. Önce kazanıp kazanmadığına bak. Eğer kazandıysan, hamle 0 olsa bile kazandın!
      if (isWon) {
        gameState = GameState.won;

        // --- YENİ EKLENDİ: KAZANINCA ÖDÜLÜ VER ---
        checkLevelReward(currentLevel.levelNumber);
        
        notifyListeners();  
      } 
      // 2. Eğer kazanmadıysan ve hamle bittiyse o zaman kaybettin de.
      else if (moves <= 0) {
       gameState = GameState.lost;
       notifyListeners(); 
      }
    }

  Future<void> tapTile(int r, int c) async {
    if (gameState != GameState.playing) return;

    if (isPowerUpWaiting) {
      isPowerUpWaiting = false;
      String powerUp = activePowerUpType!;
      activePowerUpType = null;

      // Tahtaya basıldığı an hakkını düşür!
      consumePowerUp(powerUp);

      if (powerUp == 'hammer') {
        await useRoyalHammer(r, c);
      } else if (powerUp == 'arrow') {
        await useArrowBooster(r);
      } else if (powerUp == 'cannon') {
        await useCannonBooster(c);
      } else if (powerUp == 'jester') {
        useJesterHat();
      }

      if (_checkMatches()) {
        await _processMatches();
      }
      
      notifyListeners();
      return; 
    }

    if (isAnimating) return;
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

    if (t1 != null && t2 != null && t1.type != TileType.normal && t2.type != TileType.normal) {
      bool comboTriggered = false;

      if (t1.type == TileType.wrapped && t2.type == TileType.wrapped) {
        _activateDoubleWrappedCombo(r2, c2);
        comboTriggered = true;
      } 
      else if ((t1.type == TileType.wrapped && (t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical)) ||
               (t2.type == TileType.wrapped && (t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical))) {
        _activateStripedWrappedCombo(r2, c2);
        comboTriggered = true;
      }
      else if ((t1.type == TileType.colorBomb && t2.type == TileType.wrapped) || 
               (t2.type == TileType.colorBomb && t1.type == TileType.wrapped)) {
        _activateColorBombWrappedCombo();
        comboTriggered = true;
      }
      else if ((t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical) && 
               (t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical)) {
        for (int i = 0; i < cols; i++) if (board[r2][i] != null) board[r2][i]!.isMatched = true;
        for (int i = 0; i < rows; i++) if (board[i][c2] != null) board[i][c2]!.isMatched = true;
        comboTriggered = true;
      }
      else if (t1.type == TileType.colorBomb && (t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical || t2.type == TileType.wrapped)) { 
        _convertMostFrequentToSpecial(t2.type); 
        comboTriggered = true; 
      }
      else if (t2.type == TileType.colorBomb && (t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical || t1.type == TileType.wrapped)) { 
        _convertMostFrequentToSpecial(t1.type); 
        comboTriggered = true; 
      }
      else if (t1.type == TileType.colorBomb && t2.type == TileType.colorBomb) {
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
    }

    // --- KRİTİK GÜNCELLEME: HER TÜRLÜ İŞLEM SONRASI KAZANMA KONTROLÜ ---
    _checkWinCondition(); 

    isAnimating = false;
    notifyListeners();
  }
}



