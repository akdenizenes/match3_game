import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import '../models/color_tile.dart';
import '../models/cell.dart';
import '../models/damageable.dart';
import '../models/obstacles.dart';
import '../models/level_data.dart';
import '../models/levels.dart';
import '../models/propeller_flight.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'game_manager_board.dart';
part 'game_manager_matches.dart';
part 'game_manager_powerups.dart';

enum GameState { playing, won, lost }

class GameManager extends ChangeNotifier {
  final int rows = 8;
  final int cols = 8;

  
  static const String _boardKey = 'saved_board_v2';

  static const int kDebugStartLevel = 0;

  
  List<List<Cell>> cells = [];

  int score = 0;
  int moves = 0;
  bool isAnimating = false;

  int? lastSwapRow;
  int? lastSwapCol;

  Function(List<Offset>)? onExplosion;
  Timer? _hintTimer;

  Map<String, int> powerUpCounts = {
    'hammer': 10,
    'arrow': 10,
    'cannon': 10,
    'jester': 10,
  };

  bool isPowerUpWaiting = false;
  String? activePowerUpType;

  /// Şu anda ekranda uçan pervaneler. Widget bunu okuyup çizer.
  final List<PropellerFlight> activeFlights = [];
  int _flightCounter = 0;

  late LevelData currentLevel;
  Map<TileColor, int> collectedColors = {};
  GameState gameState = GameState.playing;

  GameManager() {
    // _initGame async bitene kadar geçici olarak doğru seviyeyi göster.
    currentLevel = _generateLevelData(kDebugStartLevel > 0 ? kDebugStartLevel : 1);
    _initGame();
  }

  // ===========================================================
  // BİLDİRİM (extension'lar için public köprü)
  // ===========================================================

  /// notifyListeners() @protected + @visibleForTesting olduğu için,
  /// aynı dosyanın `part`'ı olan extension'lardan bile doğrudan
  /// çağrılamaz (analyzer uyarı verir). Extension'lar UI'ı yenilemek
  /// için notifyListeners() yerine bu public köprüyü çağırır.
  void notify() => notifyListeners();

  // ===========================================================
  // GRID ERİŞİM HELPER'LARI  (tüm extension'lar bunları kullanır)
  // ===========================================================

  bool inBounds(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  Cell? cellAt(int r, int c) => inBounds(r, c) ? cells[r][c] : null;

  ColorTile? tileAt(int r, int c) => inBounds(r, c) ? cells[r][c].tile : null;

  void setTile(int r, int c, ColorTile? t) {
    cells[r][c].tile = t;
    if (t != null) {
      t.row = r;
      t.col = c;
    }
  }

  void clearTile(int r, int c) => cells[r][c].tile = null;

  /// (r1,c1) → (r2,c2) komşu geçişi mümkün mü?
  /// Duvar (Side), void hücre ve blocker burada tek noktadan kontrol edilir.
  bool canPass(int r1, int c1, int r2, int c2) {
    if (!inBounds(r1, c1) || !inBounds(r2, c2)) return false;
    final a = cells[r1][c1];
    final b = cells[r2][c2];
    if (a.isVoid || !b.canHoldTile) return false;

    final Side? side = switch ((r2 - r1, c2 - c1)) {
      (1, 0) => Side.bottom,
      (-1, 0) => Side.top,
      (0, 1) => Side.right,
      (0, -1) => Side.left,
      _ => null,
    };
    if (side == null) return false; // komşu değil

    if (a.hasWall(side)) return false;
    if (b.hasWall(side.opposite)) return false;
    return true;
  }

  /// Çapraz kayma izni (yerçekimi için). Kural: kaynağın ALT duvarı ve hedefin ÜST duvarı açık olmalı; yan duvarlar da kaymayı keser.
  bool canSlide(int fr, int fc, int tr, int tc) {
    if (!inBounds(fr, fc) || !inBounds(tr, tc)) return false;
    if (tr - fr != 1) return false;         // sadece bir aşağı
    if ((tc - fc).abs() != 1) return false; // sadece bir yana

    final from = cells[fr][fc];
    final to = cells[tr][tc];
    if (from.isVoid || !to.canHoldTile) return false;

    if (from.hasWall(Side.bottom)) return false;
    if (to.hasWall(Side.top)) return false;

    final side = tc > fc ? Side.right : Side.left;
    if (from.hasWall(side)) return false;
    if (to.hasWall(side.opposite)) return false;

    return true;
  }

  // ===========================================================
  // HASAR SİSTEMİ
  // ===========================================================

  /// Hücredeki overlay/blocker hasarı emdi mi?
  /// true dönerse: taşa dokunulmaz (bal, kutu vs. darbeyi yedi).
  bool absorbDamage(int r, int c, DamageSource source) {
    final cell = cells[r][c];

    final ov = cell.overlay;
    if (ov != null) {
      final locked = ov.locksTile; // Hasar ÖNCESİ durumu oku
      if (ov.acceptsDamage(source) && ov.takeDamage(source)) score += 20;
      if (ov.isDestroyed) cell.overlay = null;
      if (locked) return true; // Bal o tur darbeyi yedi, taş korunur
    }

    final bl = cell.blocker;
    if (bl != null) {
      if (bl.acceptsDamage(source) && bl.takeDamage(source)) score += 30;
      if (bl.isDestroyed) cell.blocker = null;
      return true; // blocker hücreyi işgal ediyordu, taş zaten yok
    }

    return false;
  }

  /// TEK YIKIM KAPISI. Doğrudan `tile.isMatched = true` yazmak yasak.
  /// Yeni bir taş işaretlendiyse true döner (zincir tetiklemesi için).
  bool markForDestruction(int r, int c, DamageSource source) {
    if (!inBounds(r, c)) return false;
    final cell = cells[r][c];
    if (cell.isVoid) return false;

    if (absorbDamage(r, c, source)) return false;

    final t = cell.tile;
    if (t == null || t.isMatched) return false;
    t.isMatched = true;
    return true;
  }

  /// Bir taş kırıldığında komşu engelleri yoklar (kutular böyle kırılır).
  ///
  /// [alreadyHit] aynı patlama turunda aynı engele birden fazla hasar
  /// gitmesini engeller: bir kutuya kaç taş değerse değsin, o turda
  /// en fazla 1 hasar alır. (Cascade'in her yeni turu yeni bir Set alır.)
  void damageNeighbors(int r, int c, Set<Cell> alreadyHit) {
    const deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final (dr, dc) in deltas) {
      final n = cellAt(r + dr, c + dc);
      if (n == null) continue;
      if (n.blocker == null && n.overlay == null) continue;
      if (!alreadyHit.add(n)) continue; // bu turda zaten hasar gördü
      absorbDamage(r + dr, c + dc, DamageSource.adjacentMatch);
    }
  }

  // ===========================================================
  // PERVANE UÇUŞU (görsel state)
  // ===========================================================

  /// Bir pervaneyi kaynaktan hedefe uçurur ve uçuş bitene kadar bekler.
  /// Yok etme işini ÇAĞIRAN yapar — bu metot sadece animasyonu yönetir.
  Future<void> flyPropeller({
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
    TileType? carriedType,
    Duration duration = const Duration(milliseconds: 550),
  }) async {
    final flight = PropellerFlight(
      id: 'flight_${_flightCounter++}',
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: toRow,
      toCol: toCol,
      carriedType: carriedType,
      duration: duration,
    );

    activeFlights.add(flight);
    notifyListeners();
    await Future.delayed(duration);
    activeFlights.remove(flight);
    notifyListeners();
  }

  // ===========================================================
  // HINT SİSTEMİ
  // ===========================================================

  void startHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 5), _triggerHint);
  }

  void resetHintTimer() {
    _hintTimer?.cancel();
    for (var row in cells) {
      for (var cell in row) {
        cell.tile?.isHinted = false;
      }
    }
    notifyListeners();
    startHintTimer();
  }

  void _triggerHint() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final t = tileAt(r, c);
        if (t != null && t.isSpecial && cells[r][c].isMatchable) {
          t.isHinted = true;
          notifyListeners();
          return;
        }
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!cells[r][c].isMatchable) continue;

        if (canPass(r, c, r, c + 1) && (cellAt(r, c + 1)?.isMatchable ?? false)) {
          if (_wouldMatch(r, c, r, c + 1)) {
            tileAt(r, c)!.isHinted = true;
            notifyListeners();
            return;
          }
        }
        if (canPass(r, c, r + 1, c) && (cellAt(r + 1, c)?.isMatchable ?? false)) {
          if (_wouldMatch(r, c, r + 1, c)) {
            tileAt(r, c)!.isHinted = true;
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  bool _wouldMatch(int r1, int c1, int r2, int c2) {
    final tmp = cells[r1][c1].tile;
    cells[r1][c1].tile = cells[r2][c2].tile;
    cells[r2][c2].tile = tmp;

    final match = _hasMatchAt(r1, c1) || _hasMatchAt(r2, c2);

    final tmp2 = cells[r1][c1].tile;
    cells[r1][c1].tile = cells[r2][c2].tile;
    cells[r2][c2].tile = tmp2;

    return match;
  }

  bool _hasMatchAt(int r, int c) {
    final color = matchColorAt(r, c);
    if (color == null) return false;

    int h = 1;
    for (int i = c - 1; matchColorAt(r, i) == color; i--) h++;
    for (int i = c + 1; matchColorAt(r, i) == color; i++) h++;
    if (h >= 3) return true;

    int v = 1;
    for (int i = r - 1; matchColorAt(i, c) == color; i--) v++;
    for (int i = r + 1; matchColorAt(i, c) == color; i++) v++;
    return v >= 3;
  }

  /// Eşleşmeye katılabilen rengi döner; kilitli / colorBomb / boş ise null.
  TileColor? matchColorAt(int r, int c) {
    if (!inBounds(r, c)) return null;
    final cell = cells[r][c];
    if (!cell.isMatchable) return null;
    final t = cell.tile!;
    if (t.type == TileType.colorBomb) return null;
    return t.color;
  }

  // ===========================================================
  // POWER-UP / SEVİYE / KAYIT
  // ===========================================================

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

  Future<void> saveCurrentGameState() async {
    if (gameState != GameState.playing) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_moves', moves);
    await prefs.setInt('saved_score', score);

    final collectedToSave = <String, int>{};
    collectedColors.forEach((k, v) => collectedToSave[k.index.toString()] = v);
    await prefs.setString('saved_collected', jsonEncode(collectedToSave));

    // Tüm hücre yapısı kaydediliyor (tile, blocker, overlay, duvar, void).
    final boardJson = [
      for (int r = 0; r < rows; r++)
        [for (int c = 0; c < cols; c++) cells[r][c].toJson()]
    ];
    await prefs.setString(_boardKey, jsonEncode(boardJson));
  }

  Future<void> clearSavedGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_moves');
    await prefs.remove('saved_score');
    await prefs.remove('saved_collected');
    await prefs.remove(_boardKey);
    await prefs.remove('saved_board'); // eski formatın çöpünü de süpür
  }

  Future<void> _initGame() async {
    final prefs = await SharedPreferences.getInstance();

    // TEST modu: eski kaydı tamamen sil, seviyeyi zorla.
    if (kDebugStartLevel > 0) {
      await clearSavedGameState();
      await prefs.remove('current_level');
    }

    final savedLevel = kDebugStartLevel > 0
        ? kDebugStartLevel
        : (prefs.getInt('current_level') ?? 1);

    powerUpCounts['hammer'] = prefs.getInt('pu_hammer') ?? 10;
    powerUpCounts['arrow'] = prefs.getInt('pu_arrow') ?? 10;
    powerUpCounts['cannon'] = prefs.getInt('pu_cannon') ?? 10;
    powerUpCounts['jester'] = prefs.getInt('pu_jester') ?? 10;

    // Zorlama açıkken eski tahta hiç okunmaz → aşağıda _loadLevel temiz kurar.
    final savedBoardData =
        kDebugStartLevel > 0 ? null : prefs.getString(_boardKey);

    currentLevel = _generateLevelData(savedLevel);

    bool loaded = false;
    if (savedBoardData != null) {
      try {
        final bJson = jsonDecode(savedBoardData) as List<dynamic>;
        final restored = List.generate(
          rows,
          (r) => List.generate(
            cols,
            (c) => Cell.fromJson(r, c, Map<String, dynamic>.from(bJson[r][c])),
          ),
        );

        // Sağlamlık kontrolü: hiç taş yoksa kayıt bozuk demektir.
        final tileCount = restored
            .expand((row) => row)
            .where((cell) => cell.tile != null)
            .length;

        if (tileCount > 0) {
          cells = restored;
          moves = prefs.getInt('saved_moves') ?? currentLevel.maxMoves;
          score = prefs.getInt('saved_score') ?? 0;

          collectedColors.clear();
          final savedCollected = prefs.getString('saved_collected');
          if (savedCollected != null) {
            (jsonDecode(savedCollected) as Map<String, dynamic>)
                .forEach((k, v) {
              collectedColors[TileColor.values[int.parse(k)]] = v as int;
            });
          }

          gameState = GameState.playing;
          loaded = true;
        }
      } catch (_) {
        // Bozuk / eski format → aşağıda temiz seviye yüklenir.
      }
    }

    if (!loaded) {
      await _loadLevel(savedLevel);
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

    void give(String k) => powerUpCounts[k] = (powerUpCounts[k] ?? 0) + 1;

    switch (cycle) {
      case 5:
        give('hammer');
      case 8:
        give('arrow');
      case 10:
        give('cannon');
      case 13:
        give('jester');
      case 15:
        give('hammer');
        give('arrow');
        give('cannon');
        give('jester');
    }

    saveData();
    notifyListeners();
  }

  LevelData _generateLevelData(int levelNum) {
    final baseTarget = 15 + (levelNum * 2);
    final baseScore = 2000 + (levelNum * 300);

    List<TileColor> getRandomColors(int count) {
      final colors = List<TileColor>.from(TileColor.values);
      colors.shuffle(Random(levelNum));
      return colors.take(count).toList();
    }

    final levelTargets = <TileColor, int>{};
    int? currentTargetScore;

    int colorCount;
    if (levelNum <= 2) {
      colorCount = 1;
    } else if (levelNum <= 5) {
      colorCount = 2;
    } else {
      colorCount = 2 + (levelNum % 3);
    }
    colorCount = min(colorCount, TileColor.values.length);

    for (final color in getRandomColors(colorCount)) {
      levelTargets[color] = baseTarget;
    }

    if (levelNum % 3 == 0 || levelNum % 4 == 0) currentTargetScore = baseScore;

    int calculatedMoves = (baseTarget * colorCount * 0.35).ceil() + 10;
    if (currentTargetScore != null) calculatedMoves += 3;
    if (calculatedMoves < 10) calculatedMoves = 10;

    // Engel yerleşimi artık models/levels.dart'taki ASCII haritalardan gelir.
    final layout = layoutForLevel(levelNum, rows, cols);

    return LevelData(
      levelNumber: levelNum,
      maxMoves: calculatedMoves,
      targetScore: currentTargetScore,
      targetColors: levelTargets,
      layout: layout,
    );
  }

  Future<void> _loadLevel(int levelNum) async {
    await clearSavedGameState();
    currentLevel = _generateLevelData(levelNum);

    // Bölüm numarasını BURADA yaz. nextLevel/retryLevel dışarıdan
    // saveData() çağırırsa currentLevel henüz güncellenmemiş olabiliyordu
    // (yarış durumu) ve prefs'e eski bölüm yazılıyordu.
    await saveData();

    moves = currentLevel.maxMoves;
    score = 0;
    collectedColors.clear();
    gameState = GameState.playing;
    _initializeBoard();
    notifyListeners();
    saveCurrentGameState();
    resetHintTimer();
  }

  Future<void> nextLevel() async {
    // saveData() artık _loadLevel'ın içinde, doğru anda çalışıyor.
    await _loadLevel(currentLevel.levelNumber + 1);
  }

  Future<void> retryLevel() async {
    // _loadLevel zaten clearSavedGameState() ile başlıyor —
    // ayrıca çağırmak ikinci bir yarış yaratıyordu.
    await _loadLevel(currentLevel.levelNumber);
  }

  void _checkWinCondition() {
    bool isWon = true;
    if (currentLevel.targetScore != null && score < currentLevel.targetScore!) {
      isWon = false;
    }
    currentLevel.targetColors?.forEach((color, amount) {
      if ((collectedColors[color] ?? 0) < amount) isWon = false;
    });

    // Blocker VE overlay'ler hedef sayılır (kutu kır / jöle temizle seviyeleri)
    for (var row in cells) {
      for (var cell in row) {
        if (cell.hasGoal) isWon = false;
      }
    }

    if (isWon) {
      gameState = GameState.won;
      checkLevelReward(currentLevel.levelNumber);
      clearSavedGameState();
      notifyListeners();
    } else if (moves <= 0) {
      gameState = GameState.lost;
      clearSavedGameState();
      notifyListeners();
    }
  }

  /// Tahtada kalan kırılmamış engel sayısı (objective bar için).
  int get remainingBlockers {
    int n = 0;
    for (var row in cells) {
      for (var cell in row) {
        if (cell.hasGoal) n++;
      }
    }
    return n;
  }

  /// Pervanenin hedef seçimi. Blocker/overlay varsa taştan önce o gelir.
  bool isPriorityCell(Cell cell) {
    if (cell.hasGoal) return true;

    final t = cell.tile;
    if (t == null) return false;

    final target = currentLevel.targetColors?[t.color];
    if (target != null && (collectedColors[t.color] ?? 0) < target) return true;

    return false;
  }

  // ===========================================================
  // OYUNCU GİRDİSİ
  // ===========================================================

  Future<void> tapTile(int r, int c) async {
    resetHintTimer();
    if (gameState != GameState.playing) return;

    if (isPowerUpWaiting) {
      isPowerUpWaiting = false;
      final powerUp = activePowerUpType!;
      activePowerUpType = null;
      consumePowerUp(powerUp);

      switch (powerUp) {
        case 'hammer':
          await useRoyalHammer(r, c);
        case 'arrow':
          await useArrowBooster(r);
        case 'cannon':
          await useCannonBooster(c);
        case 'jester':
          await useJesterHat();
      }

      if (_checkMatches()) await _processMatches();
      _checkWinCondition();
      notifyListeners();
      saveCurrentGameState();
      return;
    }

    if (isAnimating) return;
    final cell = cells[r][c];
    if (!cell.isMatchable) return; // kilitli/boş hücreye tap yok
    final tile = cell.tile!;
    if (tile.type == TileType.normal) return;

    isAnimating = true;
    moves--;

    if (tile.type == TileType.colorBomb) {
      final randomColor =
          TileColor.values[Random().nextInt(TileColor.values.length)];
      await _activateColorBomb(randomColor, r, c);
      tile.type = TileType.normal;
    }

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

    // Duvar / blocker / void kontrolü tek satırda.
    if (!canPass(r1, c1, r2, c2)) return;
    if (!cells[r1][c1].isMatchable || !cells[r2][c2].isMatchable) return;

    isAnimating = true;
    moves--;

    lastSwapRow = r2;
    lastSwapCol = c2;

    final t1 = cells[r1][c1].tile!;
    final t2 = cells[r2][c2].tile!;

    setTile(r1, c1, t2);
    setTile(r2, c2, t1);

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    Future<void> finish() async {
      await _processMatches();
      _checkWinCondition();
      isAnimating = false;
      notifyListeners();
      saveCurrentGameState();
    }

    // --- Özel taş kombinasyonları ---
    if (t1.isSpecial && t2.isSpecial) {
      bool comboTriggered = false;

      if (t1.type == TileType.wrapped && t2.type == TileType.wrapped) {
        _activateDoubleWrappedCombo(r2, c2);
        comboTriggered = true;
      } else if ((t1.type == TileType.wrapped && t2.isStriped) ||
          (t2.type == TileType.wrapped && t1.isStriped)) {
        _activateStripedWrappedCombo(r2, c2);
        comboTriggered = true;
      } else if ((t1.type == TileType.colorBomb &&
              t2.type == TileType.wrapped) ||
          (t2.type == TileType.colorBomb && t1.type == TileType.wrapped)) {
        _activateColorBombWrappedCombo();
        comboTriggered = true;
      } else if (t1.isStriped && t2.isStriped) {
        for (int i = 0; i < cols; i++) {
          markForDestruction(r2, i, DamageSource.blast);
        }
        for (int i = 0; i < rows; i++) {
          markForDestruction(i, c2, DamageSource.blast);
        }
        comboTriggered = true;
      } else {
        comboTriggered = await executeSpecialCombo(t1, t2);
      }

      if (comboTriggered) {
        t1.type = TileType.normal;
        t2.type = TileType.normal;
        t1.isMatched = true;
        t2.isMatched = true;
        await finish();
        return;
      }
    }

    // --- ColorBomb + normal taş ---
    if (t1.type == TileType.colorBomb || t2.type == TileType.colorBomb) {
      final bomb = t1.type == TileType.colorBomb ? t1 : t2;
      final target = identical(bomb, t1) ? t2 : t1;
      await _activateColorBomb(target.color, bomb.row, bomb.col);
      bomb.type = TileType.normal;
      bomb.isMatched = true;
      await finish();
      return;
    }

    // --- Tek özel taş ---
    final isT1Special = t1.isSpecial;
    final isT2Special = t2.isSpecial;
    if (isT1Special || isT2Special) {
      if (isT1Special) t1.isMatched = true;
      if (isT2Special) t2.isMatched = true;
      _checkMatches();
      await finish();
      return;
    }

    // --- Normal swap ---
    if (!_checkMatches()) {
      setTile(r1, c1, t1);
      setTile(r2, c2, t2);
      moves++;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      _checkWinCondition();
      isAnimating = false;
      notifyListeners();
      saveCurrentGameState();
      return;
    }

    await finish();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }
}