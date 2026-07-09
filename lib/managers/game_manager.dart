import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert'; 
import 'dart:async'; 
import '../models/tile.dart';
import '../models/level_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Callback for particles
  Function(List<Offset>)? onExplosion;
  // Hint Timer
  Timer? _hintTimer;

  Map<String, int> powerUpCounts = {
    'hammer': 10,
    'arrow': 10,
    'cannon': 10,
    'jester': 10,
  };

  bool isPowerUpWaiting = false;
  String? activePowerUpType; 

// --- HINT SYSTEM METHODS ---
  
  void startHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 5), () {
      _triggerHint();
    });
  }

  void resetHintTimer() {
    _hintTimer?.cancel();
    for (var row in board) {
      for (var tile in row) {
        if (tile != null) tile.isHinted = false;
      }
    }
    notifyListeners();
    startHintTimer();
  }

  void _triggerHint() {
    // 1. CHECK FOR SPECIAL TILES (Prioritize bombs, rockets, etc. that can be tapped)
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null && board[r][c]!.type != TileType.normal) {
          board[r][c]!.isHinted = true; 
          notifyListeners();
          return; 
        }
      }
    }

    // 2. SIMULATE SWIPES (Look for a valid match-3 move)
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] == null) continue;

        // Simulate a right swipe
        if (c + 1 < cols && board[r][c+1] != null) {
          if (_wouldMatch(r, c, r, c + 1)) {
            board[r][c]!.isHinted = true; 
            notifyListeners();
            return;
          }
        }
        // Simulate a down swipe
        if (r + 1 < rows && board[r+1][c] != null) {
          if (_wouldMatch(r, c, r + 1, c)) {
            board[r][c]!.isHinted = true; 
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  // Hidden simulation for hints: Swaps tiles in memory, checks for a match, and reverts instantly.
  bool _wouldMatch(int r1, int c1, int r2, int c2) {
    Tile? temp = board[r1][c1];
    board[r1][c1] = board[r2][c2];
    board[r2][c2] = temp;

    bool match = _hasMatchAt(r1, c1) || _hasMatchAt(r2, c2);

    temp = board[r1][c1];
    board[r1][c1] = board[r2][c2];
    board[r2][c2] = temp;

    return match;
  }

  // Checks for horizontal or vertical match-3 at a specific coordinate
  bool _hasMatchAt(int r, int c) {
    if (board[r][c] == null) return false;
    TileColor color = board[r][c]!.color;
    
    // Horizontal Check
    int hCount = 1;
    for (int i = c - 1; i >= 0 && board[r][i] != null && board[r][i]!.color == color; i--) hCount++;
    for (int i = c + 1; i < cols && board[r][i] != null && board[r][i]!.color == color; i++) hCount++;
    if (hCount >= 3) return true;

    // Vertical Check
    int vCount = 1;
    for (int i = r - 1; i >= 0 && board[i][c] != null && board[i][c]!.color == color; i--) vCount++;
    for (int i = r + 1; i < rows && board[i][c] != null && board[i][c]!.color == color; i++) vCount++;
    if (vCount >= 3) return true;

    return false;
  }

  bool consumePowerUp(String type) {
    if ((powerUpCounts[type] ?? 0) > 0) {
      powerUpCounts[type] = powerUpCounts[type]! - 1;
      saveData();
      notifyListeners();
      return true;
    }
    return false; 
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
    currentLevel = _generateLevelData(1); 
    _initGame();
  }

  Future<void> saveCurrentGameState() async {
    if (gameState != GameState.playing) return; 

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_moves', moves);
    await prefs.setInt('saved_score', score);

    Map<String, int> collectedToSave = {};
    collectedColors.forEach((k, v) {
      collectedToSave[k.index.toString()] = v;
    });
    await prefs.setString('saved_collected', jsonEncode(collectedToSave));

    List<List<Map<String, dynamic>?>> boardJson = [];
    for (int r = 0; r < rows; r++) {
      List<Map<String, dynamic>?> rowJson = [];
      for (int c = 0; c < cols; c++) {
        rowJson.add(board[r][c]?.toJson());
      }
      boardJson.add(rowJson);
    }
    await prefs.setString('saved_board', jsonEncode(boardJson));
  }

  Future<void> clearSavedGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_moves');
    await prefs.remove('saved_score');
    await prefs.remove('saved_collected');
    await prefs.remove('saved_board');
  }

  Future<void> _initGame() async {
    final prefs = await SharedPreferences.getInstance();
    
    int savedLevel = prefs.getInt('current_level') ?? 1;
    
    powerUpCounts['hammer'] = prefs.getInt('pu_hammer') ?? 10;
    powerUpCounts['arrow'] = prefs.getInt('pu_arrow') ?? 10;
    powerUpCounts['cannon'] = prefs.getInt('pu_cannon') ?? 10;
    powerUpCounts['jester'] = prefs.getInt('pu_jester') ?? 10;

    String? savedBoardData = prefs.getString('saved_board');
    currentLevel = _generateLevelData(savedLevel);

    if (savedBoardData != null) {
      moves = prefs.getInt('saved_moves') ?? currentLevel.maxMoves;
      score = prefs.getInt('saved_score') ?? 0;
      
      String? savedCollected = prefs.getString('saved_collected');
      collectedColors.clear();
      if (savedCollected != null) {
        Map<String, dynamic> colMap = jsonDecode(savedCollected);
        colMap.forEach((key, value) {
          collectedColors[TileColor.values[int.parse(key)]] = value;
        });
      }

      List<dynamic> bJson = jsonDecode(savedBoardData);
      board = [];
      for (int r = 0; r < rows; r++) {
        List<Tile?> boardRow = [];
        for (int c = 0; c < cols; c++) {
          if (bJson[r][c] != null) {
            boardRow.add(Tile.fromJson(bJson[r][c]));
          } else {
            boardRow.add(null);
          }
        }
        board.add(boardRow);
      }
      gameState = GameState.playing;
    } else {
      _loadLevel(savedLevel);
    }
    
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level', currentLevel.levelNumber);
    await prefs.setInt('pu_hammer', powerUpCounts['hammer'] ?? 0);
    await prefs.setInt('pu_arrow', powerUpCounts['arrow'] ?? 0);
    await prefs.setInt('pu_cannon', powerUpCounts['cannon'] ?? 0);
    await prefs.setInt('pu_jester', powerUpCounts['jester'] ?? 0);
  }

  void checkLevelReward(int completedLevel) {
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
      powerUpCounts['hammer'] = (powerUpCounts['hammer'] ?? 0) + 1;
      powerUpCounts['arrow'] = (powerUpCounts['arrow'] ?? 0) + 1;
      powerUpCounts['cannon'] = (powerUpCounts['cannon'] ?? 0) + 1;
      powerUpCounts['jester'] = (powerUpCounts['jester'] ?? 0) + 1;
    }
    
    saveData(); 
    notifyListeners();
  }

  LevelData _generateLevelData(int levelNum) {
    int cycle = (levelNum - 1) ~/ 6; 
    int step = (levelNum - 1) % 6;   

    int baseTarget = 15 + (cycle * 5); 
    int baseScore = 2000 + (cycle * 1500); 

    List<TileColor> getRandomColors(int count) {
        List<TileColor> colors = TileColor.values.toList();
        colors.shuffle(Random(levelNum)); 
        return colors.take(count).toList();
    }

    Map<TileColor, int> levelTargets = {};
    int? currentTargetScore;

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
      currentTargetScore = baseScore * 2;
    }

    int totalRequiredTiles = 0;
    levelTargets.forEach((color, amount) {
      totalRequiredTiles += amount;
    });

    int calculatedMoves = (totalRequiredTiles * 0.4).ceil() + 10;
    
    if (currentTargetScore != null) calculatedMoves += 3;
    if (cycle > 0) calculatedMoves -= cycle * 2; 
    if (calculatedMoves < 10) calculatedMoves = 10;

    return LevelData(
      levelNumber: levelNum, 
      maxMoves: calculatedMoves, 
      targetScore: currentTargetScore, 
      targetColors: levelTargets
    );
  }

  Future<void> _loadLevel(int levelNum) async {
    await clearSavedGameState();
    currentLevel = _generateLevelData(levelNum);
    moves = currentLevel.maxMoves;
    score = 0;
    collectedColors.clear();
    gameState = GameState.playing;
    _initializeBoard();
    notifyListeners(); 
    saveCurrentGameState(); 
    resetHintTimer(); 
  }

  void nextLevel() { _loadLevel(currentLevel.levelNumber + 1); saveData(); }
  void retryLevel() { 
    clearSavedGameState(); 
    _loadLevel(currentLevel.levelNumber); 
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
       checkLevelReward(currentLevel.levelNumber);
       clearSavedGameState();
       notifyListeners();  
     } 
     else if (moves <= 0) {
       gameState = GameState.lost;
       clearSavedGameState();
       notifyListeners(); 
     }
  }

  // --- NEW: CENTRALIZED TARGETING SYSTEM FOR PROPELLERS ---
  // Determines if a tile is a priority target for the current level
  bool isPriorityTarget(Tile tile) {
    // 1. Color Goal Check: Is this color a target for the current level?
    if (currentLevel.targetColors != null && currentLevel.targetColors!.containsKey(tile.color)) {
      int targetAmount = currentLevel.targetColors![tile.color]!;
      int collectedAmount = collectedColors[tile.color] ?? 0;
      
      // If we haven't collected enough of this color yet, it's a priority target!
      if (collectedAmount < targetAmount) {
        return true; 
      }
    }

    // 2. Future-proofing: Is it an obstacle or a specific goal?
    // Once you add TileType.garden, TileType.box, etc., just add them here like:
    // if (tile.type == TileType.garden) return true;
    if (tile.isGoal || tile.isObstacle) return true;

    // Not a priority target
    return false;
  }
  // --------------------------------------------------------

Future<void> tapTile(int r, int c) async {
    resetHintTimer(); 
    if (gameState != GameState.playing) return;

    if (isPowerUpWaiting) {
      isPowerUpWaiting = false;
      String powerUp = activePowerUpType!;
      activePowerUpType = null;

      consumePowerUp(powerUp);

      if (powerUp == 'hammer') await useRoyalHammer(r, c);
      else if (powerUp == 'arrow') await useArrowBooster(r);
      else if (powerUp == 'cannon') await useCannonBooster(c);
      else if (powerUp == 'jester') await useJesterHat();

      if (_checkMatches()) await _processMatches();
      
      _checkWinCondition();
      notifyListeners();
      saveCurrentGameState(); 
      return; 
    }

    if (isAnimating) return;
    Tile? tile = board[r][c];
    if (tile == null || tile.type == TileType.normal) return;

    isAnimating = true;
    moves--;

    if (tile.type == TileType.colorBomb) {
      TileColor randomColor = TileColor.values[Random().nextInt(TileColor.values.length)];
      await _activateColorBomb(randomColor, r, c); 
      tile.type = TileType.normal; // Prevent double trigger by the engine
    }
    // NOT: Pervane için olan özel çağırmayı buradan sildik.
    // Motor (processMatches) pervaneyi gördüğü an tek bir uçuşu kendisi başlatacak!

    tile.isMatched = true;
    await _processMatches();
    
    _checkWinCondition();
    isAnimating = false;
    notifyListeners();
    saveCurrentGameState(); 
  }

  Future<void> swapTiles(int r1, int c1, int r2, int c2) async {
    resetHintTimer(); 
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

    bool comboTriggered = false;

    if (t1 != null && t2 != null && t1.type != TileType.normal && t2.type != TileType.normal) {
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
      else {
         comboTriggered = await executeSpecialCombo(t1, t2);
      }
      
      if (comboTriggered) {
        t1.type = TileType.normal; // Prevent double triggers after combo
        t2.type = TileType.normal; // Prevent double triggers after combo
        t1.isMatched = true;
        t2.isMatched = true;
        await _processMatches();
        _checkWinCondition();
        isAnimating = false;
        notifyListeners();
        saveCurrentGameState(); 
        return;
      }
    }

    if (t1 != null && t2 != null && (t1.type == TileType.colorBomb || t2.type == TileType.colorBomb)) {
      Tile bomb = t1.type == TileType.colorBomb ? t1 : t2;
      Tile target = t1.type == TileType.colorBomb ? t2 : t1;
      await _activateColorBomb(target.color, bomb.row, bomb.col);
      
      bomb.type = TileType.normal; // Prevent double triggers
      bomb.isMatched = true;
      
      await _processMatches();
      _checkWinCondition();
      isAnimating = false;
      notifyListeners();
      saveCurrentGameState(); 
      return;
    }

    bool isT1Special = t1?.type != null && t1!.type != TileType.normal && t1.type != TileType.colorBomb;
    bool isT2Special = t2?.type != null && t2!.type != TileType.normal && t2.type != TileType.colorBomb;

    if (isT1Special || isT2Special) {
      if (isT1Special) t1!.isMatched = true;
      if (isT2Special) t2!.isMatched = true;
      
      _checkMatches(); 
      await _processMatches();
      _checkWinCondition();
      isAnimating = false;
      notifyListeners();
      saveCurrentGameState(); 
      return;
    }

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

    _checkWinCondition(); 
    isAnimating = false;
    notifyListeners();
    saveCurrentGameState(); 
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }
}