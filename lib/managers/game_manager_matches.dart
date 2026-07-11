part of 'game_manager.dart';

extension GameManagerMatches on GameManager {

  void _activateDoubleWrappedCombo(int rowIdx, int colIdx) {
    for (int r = max(0, rowIdx - 4); r <= min(rows - 1, rowIdx + 4); r++) {
      for (int c = max(0, colIdx - 4); c <= min(cols - 1, colIdx + 4); c++) {
        markForDestruction(r, c, DamageSource.blast);
      }
    }
    score += 1000;
  }

  void _activateStripedWrappedCombo(int rowIdx, int colIdx) {
    for (int r = max(0, rowIdx - 1); r <= min(rows - 1, rowIdx + 1); r++) {
      for (int c = 0; c < cols; c++) {
        markForDestruction(r, c, DamageSource.blast);
      }
    }
    for (int c = max(0, colIdx - 1); c <= min(cols - 1, colIdx + 1); c++) {
      for (int r = 0; r < rows; r++) {
        markForDestruction(r, c, DamageSource.blast);
      }
    }
    score += 800;
  }

  /// Tahtadaki en yaygın normal rengi bulur.
  TileColor? _mostFrequentColor() {
    final counts = <TileColor, int>{};
    for (var row in cells) {
      for (var cell in row) {
        final t = cell.tile;
        if (t != null && t.type == TileType.normal && !cell.isLocked) {
          counts[t.color] = (counts[t.color] ?? 0) + 1;
        }
      }
    }
    TileColor? best;
    int maxC = 0;
    counts.forEach((k, v) {
      if (v > maxC) {
        maxC = v;
        best = k;
      }
    });
    return best;
  }

  void _activateColorBombWrappedCombo() {
    final mostColor = _mostFrequentColor();
    if (mostColor != null) {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final t = tileAt(r, c);
          if (t != null && t.color == mostColor) {
            t.type = TileType.wrapped;
            markForDestruction(r, c, DamageSource.colorBomb);
          }
        }
      }
    }
    score += 1200;
  }

  Future<void> _activateColorBomb(
      TileColor targetColor, int startR, int startC) async {
    final targets = <ColorTile>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final t = tileAt(r, c);
        if (t != null && t.color == targetColor && cells[r][c].isMatchable) {
          targets.add(t);
        }
      }
    }

    targets.sort((a, b) {
      final dA = sqrt(pow(a.row - startR, 2) + pow(a.col - startC, 2));
      final dB = sqrt(pow(b.row - startR, 2) + pow(b.col - startC, 2));
      return dA.compareTo(dB);
    });

    for (final t in targets) {
      t.isTargeted = true;
      notify();
      await Future.delayed(const Duration(milliseconds: 40));
    }

    await Future.delayed(const Duration(milliseconds: 200));

    for (final t in targets) {
      t.isTargeted = false;
      markForDestruction(t.row, t.col, DamageSource.colorBomb);
      score += 20;
    }
  }

  // ===========================================================
  // EŞLEŞME TARAMASI
  // ===========================================================

  bool _checkMatches() {
    bool found = false;
    final hMatched = List.generate(rows, (_) => List.filled(cols, false));
    final vMatched = List.generate(rows, (_) => List.filled(cols, false));
    final sqMatched = List.generate(rows, (_) => List.filled(cols, false));

    // --- Yatay ---
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 2; c++) {
        final color = matchColorAt(r, c);
        if (color == null) continue;

        int len = 1;
        while (matchColorAt(r, c + len) == color) {
          len++;
        }

        if (len >= 3) {
          found = true;
          int targetC = c + len ~/ 2;
          for (int i = 0; i < len; i++) {
            hMatched[r][c + i] = true;
            if (lastSwapRow == r && lastSwapCol == c + i) targetC = c + i;
          }

          if (len >= 5) {
            tileAt(r, targetC)!.typeToBecome = TileType.colorBomb;
          } else if (len == 4) {
            tileAt(r, targetC)!.typeToBecome = TileType.stripedVertical;
          }
          if (len >= 4) {
            for (int i = 0; i < len; i++) {
              tileAt(r, c + i)!
                ..mergeTargetRow = r
                ..mergeTargetCol = targetC;
            }
          }
          c += len - 1;
        }
      }
    }

    // --- Dikey ---
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows - 2; r++) {
        final color = matchColorAt(r, c);
        if (color == null) continue;

        int len = 1;
        while (matchColorAt(r + len, c) == color) {
          len++;
        }

        if (len >= 3) {
          found = true;
          int targetR = r + len ~/ 2;
          for (int i = 0; i < len; i++) {
            vMatched[r + i][c] = true;
            if (lastSwapRow == r + i && lastSwapCol == c) targetR = r + i;
          }

          final target = tileAt(targetR, c)!;
          if (len >= 5) {
            target.typeToBecome = TileType.colorBomb;
          } else if (len == 4 && target.typeToBecome == null) {
            target.typeToBecome = TileType.stripedHorizontal;
          }
          if (len >= 4) {
            for (int i = 0; i < len; i++) {
              tileAt(r + i, c)!
                ..mergeTargetRow = targetR
                ..mergeTargetCol = c;
            }
          }
          r += len - 1;
        }
      }
    }

    // --- Kare (2x2) ---
    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols - 1; c++) {
        final color = matchColorAt(r, c);
        if (color == null) continue;
        if (matchColorAt(r, c + 1) != color) continue;
        if (matchColorAt(r + 1, c) != color) continue;
        if (matchColorAt(r + 1, c + 1) != color) continue;

        found = true;
        int targetR = r, targetC = c;
        for (final (rr, cc) in [(r, c), (r, c + 1), (r + 1, c), (r + 1, c + 1)]) {
          sqMatched[rr][cc] = true;
          if (lastSwapRow == rr && lastSwapCol == cc) {
            targetR = rr;
            targetC = cc;
          }
        }

        if (tileAt(targetR, targetC)!.typeToBecome == null) {
          tileAt(targetR, targetC)!.typeToBecome = TileType.propeller;
        }
        for (final (rr, cc) in [(r, c), (r, c + 1), (r + 1, c), (r + 1, c + 1)]) {
          tileAt(rr, cc)!
            ..mergeTargetRow = targetR
            ..mergeTargetCol = targetC;
        }
      }
    }

    // --- İşaretleme ---
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!(hMatched[r][c] || vMatched[r][c] || sqMatched[r][c])) continue;
        if (!markForDestruction(r, c, DamageSource.match)) continue;

        final t = tileAt(r, c)!;
        if (t.typeToBecome == null && hMatched[r][c] && vMatched[r][c]) {
          t.typeToBecome = TileType.wrapped;
        }
      }
    }
    return found;
  }

  // ===========================================================
  // PATLAMA / ÇÖKME / DOLDURMA
  // ===========================================================

  /// [hitThisMove] bu HAMLE boyunca hasar görmüş engelleri tutar.
  /// Cascade'in alt turlarına aynı set geçilir: bir kutu, kaç eşleşme
  /// değerse değsin ve kaç tur zincirlenirse zincirlensin, tek hamlede
  /// en fazla 1 hasar alır.
  Future<void> _processMatches({
    int cascadeDepth = 0,
    Set<Cell>? hitThisMove,
  }) async {
    final hitCells = hitThisMove ?? <Cell>{};

    bool specialTriggered;
    int safeLoopLimit = 0;
    final pendingFlights = <Future<void>>[];

    do {
      specialTriggered = false;
      bool hasSpecialExplosion = false;
      if (++safeLoopLimit > 50) break;

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final t = tileAt(r, c);
          if (t == null || !t.isMatched || t.type == TileType.normal) continue;

          final type = t.type;
          t.type = TileType.normal; // tek sefer tetiklensin
          hasSpecialExplosion = true;

          switch (type) {
            case TileType.stripedHorizontal:
              for (int i = 0; i < cols; i++) {
                if (markForDestruction(r, i, DamageSource.blast)) {
                  specialTriggered = true;
                }
              }
            case TileType.stripedVertical:
              for (int i = 0; i < rows; i++) {
                if (markForDestruction(i, c, DamageSource.blast)) {
                  specialTriggered = true;
                }
              }
            case TileType.wrapped:
              for (int i = max(0, r - 1); i <= min(rows - 1, r + 1); i++) {
                for (int j = max(0, c - 1); j <= min(cols - 1, c + 1); j++) {
                  if (markForDestruction(i, j, DamageSource.blast)) {
                    specialTriggered = true;
                  }
                }
              }
            case TileType.propeller:
              for (int i = max(0, r - 1); i <= min(rows - 1, r + 1); i++) {
                for (int j = max(0, c - 1); j <= min(cols - 1, c + 1); j++) {
                  if (i != r && j != c) continue;
                  if (markForDestruction(i, j, DamageSource.propeller)) {
                    specialTriggered = true;
                  }
                }
              }
              pendingFlights.add(_triggerPropellerFlightAsync(r, c));
            default:
              hasSpecialExplosion = false;
          }
        }
      }

      if (hasSpecialExplosion) {
        notify();
        await Future.delayed(const Duration(milliseconds: 250));
      }
    } while (specialTriggered);

    if (pendingFlights.isNotEmpty) await Future.wait(pendingFlights);

    // --- Dönüşüm + toplama ---
    bool hasExplosions = false;
    final explosionPoints = <Offset>[];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final t = tileAt(r, c);
        if (t == null || !t.isMatched) continue;

        if (t.typeToBecome != null) {
          t.type = t.typeToBecome!;
          t.typeToBecome = null;
          t.isMatched = false;
          t.mergeTargetRow = null;
          t.mergeTargetCol = null;
          score += 50;
          continue;
        }

        // colorBomb renksiz sayılır; diğer her taş göreve yazılır.
        if (t.type != TileType.colorBomb) {
          collectedColors[t.color] = (collectedColors[t.color] ?? 0) + 1;
        }

        if (t.mergeTargetRow != null && t.mergeTargetCol != null) {
          t.row = t.mergeTargetRow!;
          t.col = t.mergeTargetCol!;
        }

        damageNeighbors(r, c, hitCells); // kutular komşu eşleşmeden kırılır
        t.isExploding = true;
        hasExplosions = true;
        explosionPoints.add(Offset(c.toDouble(), r.toDouble()));
        score += 10;
      }
    }

    if (hasExplosions) {
      onExplosion?.call(explosionPoints);
      notify();
      await Future.delayed(const Duration(milliseconds: 250));
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (tileAt(r, c)?.isExploding ?? false) clearTile(r, c);
        }
      }
    }

    notify();
    if (!hasExplosions) await Future.delayed(const Duration(milliseconds: 200));

    await _collapseAndRefill();

    if (cascadeDepth < 20 && _checkMatches()) {
      await _processMatches(
        cascadeDepth: cascadeDepth + 1,
        hitThisMove: hitCells, // aynı hamle → kutu tekrar hasar almasın
      );
    }
  }

  // ===========================================================
  // YERÇEKİMİ (dik + çapraz)
  // ===========================================================

  /// Taşı fr,fc → tr,tc taşır. Kilitli taş (bal altı) düşmez.
  bool _tryMove(int fr, int fc, int tr, int tc, {required bool diagonal}) {
    if (!inBounds(fr, fc)) return false;
    final from = cells[fr][fc];
    if (from.tile == null || from.isLocked) return false;

    final ok = diagonal ? canSlide(fr, fc, tr, tc) : canPass(fr, fc, tr, tc);
    if (!ok) return false;

    final t = from.tile!;
    from.tile = null;
    setTile(tr, tc, t);
    return true;
  }

  /// Tek adım yerçekimi — İKİ FAZLI.
  ///
  /// FAZ 1: Tüm dik düşüşleri dener. Bu turda tek bir taş bile dik
  /// düştüyse hemen döner; çapraz faza GEÇMEZ. Böylece bir sütun
  /// tamamen düz akıp oturmadan hiçbir taş yana kaymaz — Royal Match
  /// mantığı: taş her zaman önce düz iner.
  ///
  /// FAZ 2: Buraya yalnızca hiçbir taş dik düşemezken gelinir. Yani
  /// kalan boşlukların dik yolu artık kalıcı olarak kapalıdır
  /// (blocker / void / alt duvar). Bu boşluklar üst-sol ve üst-sağ
  /// çapraz komşulardan beslenir. Engel altındaki boşluk yandan dolar,
  /// V şeklindeki boşluklar merkeze çapraz çekilir.
  bool _gravityStep() {
    // --- FAZ 1: Dik düşüş ---
    bool movedVertical = false;
    for (int r = rows - 1; r >= 1; r--) {
      for (int c = 0; c < cols; c++) {
        if (!cells[r][c].isEmpty) continue;
        if (_tryMove(r - 1, c, r, c, diagonal: false)) {
          movedVertical = true;
        }
      }
    }
    // Dik akış sürdükçe çaprazı beklet → şelale hep düz iner.
    if (movedVertical) return true;

    // --- FAZ 2: Çapraz kayma ---
    bool movedDiagonal = false;
    for (int r = rows - 1; r >= 1; r--) {
      for (int c = 0; c < cols; c++) {
        if (!cells[r][c].isEmpty) continue;

        // Rastgele yön: hep soldan gelirse tahta bir tarafa yığılır.
        final dirs = Random().nextBool() ? [-1, 1] : [1, -1];
        for (final dc in dirs) {
          final sc = c + dc;
          if (!inBounds(r - 1, sc)) continue;
          if (_tryMove(r - 1, sc, r, c, diagonal: true)) {
            movedDiagonal = true;
            break;
          }
        }
      }
    }
    return movedDiagonal;
  }

  /// Bu hücre yeni taş üretebilen bir "spawn ağzı" mı?
  ///
  /// Ağız olmasının iki yolu var:
  ///   1. Tahtanın tepesi (r == 0)
  ///   2. Hemen üstü VOID — yukarıdan asla taş gelemez, kendi ağzı olmalı.
  ///
  /// Blocker'ın altı ağız SAYILMAZ: kutu geçicidir, kırılınca sütun açılır.
  /// Orası çapraz kayma ile beslenir.
  bool _isSpawnMouth(int r, int c) {
    final cell = cells[r][c];
    if (!cell.isEmpty) return false;      // void/blocker/dolu → ağız değil
    if (cell.hasWall(Side.top)) return false;

    if (r == 0) return true;

    final above = cells[r - 1][c];
    if (above.isVoid) return true;
    if (above.hasWall(Side.bottom)) return true;

    return false;
  }

  /// Tüm spawn ağızlarına birer taş üretir.
  /// _collapseAndRefill önce yerçekimini tüketiyor, yani çapraz kayma
  /// her zaman spawn'dan önceliklidir.
  bool _spawnStep() {
    final random = Random();
    bool spawned = false;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!_isSpawnMouth(r, c)) continue;

        setTile(
          r,
          c,
          ColorTile(
            id: 'new_${r}_${c}_${random.nextInt(100000)}',
            color: TileColor.values[random.nextInt(TileColor.values.length)],
            row: r,
            col: c,
          ),
        );
        spawned = true;
      }
    }
    return spawned;
  }

  Future<void> _collapseAndRefill() async {
    int guard = 0;
    while (guard++ < 200) {
      if (_gravityStep()) {
        notify();
        await Future.delayed(const Duration(milliseconds: 60));
        continue;
      }
      if (_spawnStep()) {
        notify();
        await Future.delayed(const Duration(milliseconds: 60));
        continue;
      }
      break;
    }
    notify();
  }

  // ===========================================================
  // PERVANE UÇUŞU
  // ===========================================================

  /// Pervanenin vuruşu bu hücredeki engele işler mi?
  /// (jöle, bal, taş blok, buz → evet. kutu → hayır.)
  bool _propellerCanDamage(Cell cell) {
    final ov = cell.overlay;
    if (ov != null && ov.acceptsDamage(DamageSource.propeller)) return true;
    final bl = cell.blocker;
    if (bl != null && bl.acceptsDamage(DamageSource.propeller)) return true;
    return false;
  }

  /// Bu hücrede pervanenin DOĞRUDAN kıramadığı bir hedef var mı? (kutu)
  /// Bunlara ancak komşu taşı patlatıp damageNeighbors ile ulaşılır.
  bool _needsNeighborHit(Cell cell) {
    if (!cell.hasGoal) return false;
    return !_propellerCanDamage(cell);
  }

  /// Pervane bu taşı gerçekten yok edebilir mi?
  bool _isValidTileTarget(Cell cell) {
    final t = cell.tile;
    if (t == null || t.isMatched || t.isTargeted) return false;
    if (t.type == TileType.propeller) return false;
    if (cell.isLocked) return false; // bal altındaki taş yok edilemez
    return true;
  }

  /// Bir hedef türünün ne kadarı hâlâ tamamlanmamış? 0.0 = bitti, 1.0 = hiç el atılmadı.
  ///
  /// Sabit katman sırası yanlış davranıyordu: tahtada tek bir buz kaldıysa
  /// pervane sonsuza kadar ona gidip hedef rengi görmezden geliyordu.
  /// Artık EN GERİDE kalan hedef kazanıyor.
  double _remainingRatio({required int done, required int total}) {
    if (total <= 0) return 0.0;
    return ((total - done) / total).clamp(0.0, 1.0);
  }

  /// Engel hedefleri için: kaçı hâlâ ayakta?
  /// Toplam sayıyı bilmiyoruz (bölüm başındaki sayı saklanmıyor), o yüzden
  /// "kalan engel sayısı" doğrudan bir aciliyet ölçüsü olarak kullanılıyor.
  double _blockerUrgency() {
    final left = remainingBlockers;
    if (left == 0) return 0.0;
    // 1 engel kaldıysa aciliyet yüksek olmalı ama renk hedefini ezmemeli.
    return (left / (left + 4)).clamp(0.15, 0.85);
  }

  /// Renk hedefleri için: toplanmamış oranların en büyüğü.
  double _colorUrgency() {
    final targets = currentLevel.targetColors;
    if (targets == null || targets.isEmpty) return 0.0;

    double worst = 0.0;
    targets.forEach((color, need) {
      final have = collectedColors[color] ?? 0;
      final ratio = _remainingRatio(done: have, total: need);
      if (ratio > worst) worst = ratio;
    });
    return worst;
  }

  /// Pervanenin hedeflerini ÖNCELİK SIRASIYLA döner.
  ///
  /// İki büyük hedef ailesi yarışır: ENGELLER ve RENKLER.
  /// Hangisinde daha geriysen o aile öne geçer. Aile içinde:
  ///   - engeller: doğrudan kırılabilenler, yoksa kutu komşusu
  ///   - renkler: en çok eksik olan renk
  /// Hiçbiri yoksa normal taş.
  ///
  /// Hem tek pervane uçuşu hem de pervane komboları bunu kullanır.
  List<Cell> propellerTargetsOrdered() {
    final directGoals = <Cell>[];
    final nextToStubborn = <Cell>[];
    final colorGoals = <Cell>[];
    final normal = <Cell>[];

    // İnatçı hedefler (kutu): doğrudan vurulamaz, komşusundan kırılır.
    final stubborn = <Cell>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = cells[r][c];
        if (_needsNeighborHit(cell)) stubborn.add(cell);
        if (cell.hasGoal && _propellerCanDamage(cell)) directGoals.add(cell);
      }
    }

    const deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final box in stubborn) {
      for (final (dr, dc) in deltas) {
        final n = cellAt(box.row + dr, box.col + dc);
        if (n == null || n.hasGoal) continue;
        if (_isValidTileTarget(n)) nextToStubborn.add(n);
      }
    }

    // En çok eksik olan rengi bul; sadece O renge ait taşları topla.
    TileColor? neediestColor;
    double worstRatio = 0.0;
    currentLevel.targetColors?.forEach((color, need) {
      final have = collectedColors[color] ?? 0;
      final ratio = _remainingRatio(done: have, total: need);
      if (ratio > worstRatio) {
        worstRatio = ratio;
        neediestColor = color;
      }
    });

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = cells[r][c];
        if (cell.hasGoal) continue;
        if (!_isValidTileTarget(cell)) continue;

        final t = cell.tile!;
        if (t.type != TileType.normal) continue;

        if (neediestColor != null && t.color == neediestColor) {
          colorGoals.add(cell);
        } else {
          normal.add(cell);
        }
      }
    }

    // --- Aile seçimi: kim daha geride? ---
    final blockerNeed = _blockerUrgency();
    final colorNeed = _colorUrgency();

    final blockerTiers = <List<Cell>>[directGoals, nextToStubborn];
    final colorTiers = <List<Cell>>[colorGoals];

    final ordered = <List<Cell>>[
      if (blockerNeed >= colorNeed) ...blockerTiers else ...colorTiers,
      if (blockerNeed >= colorNeed) ...colorTiers else ...blockerTiers,
      normal,
    ];

    for (final tier in ordered) {
      tier.shuffle();
    }

    final seen = <Cell>{};
    return [
      for (final tier in ordered)
        for (final cell in tier)
          if (seen.add(cell)) cell,
    ];
  }

  Future<void> _triggerPropellerFlightAsync(int fromR, int fromC) async {
    final targets = propellerTargetsOrdered();
    if (targets.isEmpty) return;
    final selected = targets.first;

    // 1. Hedefi kilitle (nişangah belirir)
    selected.tile?.isTargeted = true;
    notify();
    await Future.delayed(const Duration(milliseconds: 180));

    // 2. Pervane kaynaktan hedefe uçar
    await flyPropeller(
      fromRow: fromR,
      fromCol: fromC,
      toRow: selected.row,
      toCol: selected.col,
    );

    // 3. Kondu, patlat
    selected.tile?.isTargeted = false;
    markForDestruction(selected.row, selected.col, DamageSource.propeller);
    notify();
  }
}