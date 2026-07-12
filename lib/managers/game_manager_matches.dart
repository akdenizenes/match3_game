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

  /// Finds the most frequent normal color on the board.
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
  // MATCH SCANNING
  // ===========================================================

  bool _checkMatches() {
    bool found = false;
    final hMatched = List.generate(rows, (_) => List.filled(cols, false));
    final vMatched = List.generate(rows, (_) => List.filled(cols, false));
    final sqMatched = List.generate(rows, (_) => List.filled(cols, false));

    // --- Horizontal ---
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

    // --- Vertical ---
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

    // --- Square (2x2) ---
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

    // --- Marking ---
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
  // EXPLOSION / COLLAPSE / REFILL
  // ===========================================================

  /// [hitThisMove] holds the obstacles that took damage during THIS move.
  /// The same set is passed to the lower rounds of the cascade: no matter
  /// how many matches a box is worth and no matter how many rounds it chains
  /// through, it takes at most 1 damage per move.
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
          t.type = TileType.normal; // trigger only once
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

    // --- Transformation + collection ---
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

        // colorBomb counts as colorless; every other tile is credited to the goal.
        if (t.type != TileType.colorBomb) {
          collectedColors[t.color] = (collectedColors[t.color] ?? 0) + 1;
        }

        if (t.mergeTargetRow != null && t.mergeTargetCol != null) {
          t.row = t.mergeTargetRow!;
          t.col = t.mergeTargetCol!;
        }

        damageNeighbors(r, c, hitCells); // boxes break from adjacent matches
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
        hitThisMove: hitCells, // same move → box shouldn't take damage again
      );
    }
  }

  // ===========================================================
  // GRAVITY (vertical + diagonal)
  // ===========================================================

  /// Moves a tile fr,fc → tr,tc. A locked tile (under honey) doesn't fall.
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

  /// Single gravity step — TWO-PHASE.
  ///
  /// PHASE 1: Attempt all vertical drops. If even a single tile dropped
  /// vertically this round, return immediately; do NOT proceed to the
  /// diagonal phase. This way, no tile slides sideways until a column has
  /// flowed straight down and settled — the Royal Match logic: a tile
  /// always drops straight first.
  ///
  /// PHASE 2: We only reach here when no tile can drop vertically. That is,
  /// the vertical path of the remaining gaps is now permanently blocked
  /// (blocker / void / bottom wall). These gaps are fed from the top-left
  /// and top-right diagonal neighbors. A gap under an obstacle fills from
  /// the side, and V-shaped gaps are pulled diagonally toward the center.
  bool _gravityStep() {
    // --- PHASE 1: Vertical drop ---
    bool movedVertical = false;
    for (int r = rows - 1; r >= 1; r--) {
      for (int c = 0; c < cols; c++) {
        if (!cells[r][c].isEmpty) continue;
        if (_tryMove(r - 1, c, r, c, diagonal: false)) {
          movedVertical = true;
        }
      }
    }
    // While vertical flow continues, hold off the diagonal → waterfall always straight.
    if (movedVertical) return true;

    // --- PHASE 2: Diagonal slide ---
    bool movedDiagonal = false;
    for (int r = rows - 1; r >= 1; r--) {
      for (int c = 0; c < cols; c++) {
        if (!cells[r][c].isEmpty) continue;

        // Random direction: if it always comes from the left, the board piles to one side.
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

  /// Is this cell a "spawn mouth" that can produce new tiles?
  ///
  /// There are two ways to be a mouth:
  ///   1. The top of the board (r == 0)
  ///   2. The cell directly above is VOID — no tile can ever come from above,
  ///      so it must be its own mouth.
  ///
  /// The cell below a blocker does NOT count as a mouth: the box is temporary,
  /// and once broken the column opens up. That spot is fed by diagonal sliding.
  bool _isSpawnMouth(int r, int c) {
    final cell = cells[r][c];
    if (!cell.isEmpty) return false;      // void/blocker/filled → not a mouth
    if (cell.hasWall(Side.top)) return false;

    if (r == 0) return true;

    final above = cells[r - 1][c];
    if (above.isVoid) return true;
    if (above.hasWall(Side.bottom)) return true;

    return false;
  }

  /// Produces one tile at every spawn mouth.
  /// _collapseAndRefill exhausts gravity first, so diagonal sliding always
  /// takes priority over spawning.
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
  // PROPELLER FLIGHT
  // ===========================================================

  /// Does the propeller's strike affect the obstacle in this cell?
  /// (jelly, honey, stone block, ice → yes. box → no.)
  bool _propellerCanDamage(Cell cell) {
    final ov = cell.overlay;
    if (ov != null && ov.acceptsDamage(DamageSource.propeller)) return true;
    final bl = cell.blocker;
    if (bl != null && bl.acceptsDamage(DamageSource.propeller)) return true;
    return false;
  }

  /// Is there a target in this cell that the propeller can't break DIRECTLY? (box)
  /// These can only be reached by exploding a neighbor tile via damageNeighbors.
  bool _needsNeighborHit(Cell cell) {
    if (!cell.hasGoal) return false;
    return !_propellerCanDamage(cell);
  }

  /// Can the propeller actually destroy this tile?
  bool _isValidTileTarget(Cell cell) {
    final t = cell.tile;
    if (t == null || t.isMatched || t.isTargeted) return false;
    if (t.type == TileType.propeller) return false;
    if (cell.isLocked) return false; // a tile under honey can't be destroyed
    return true;
  }

  /// How much of a given goal type is still incomplete? 0.0 = done, 1.0 = untouched.
  ///
  /// A fixed layer order was misbehaving: if a single ice remained on the board,
  /// the propeller would go to it forever and ignore the color goal.
  /// Now the MOST behind goal wins.
  double _remainingRatio({required int done, required int total}) {
    if (total <= 0) return 0.0;
    return ((total - done) / total).clamp(0.0, 1.0);
  }

  /// For obstacle goals: how many are still standing?
  /// We don't know the total count (the count at the start of the level isn't
  /// stored), so the "remaining obstacle count" is used directly as an urgency measure.
  double _blockerUrgency() {
    final left = remainingBlockers;
    if (left == 0) return 0.0;
    // If 1 obstacle is left, urgency should be high but must not override the color goal.
    return (left / (left + 4)).clamp(0.15, 0.85);
  }

  /// For color goals: the largest of the uncollected ratios.
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

  /// Returns the propeller's targets in PRIORITY ORDER.
  ///
  /// Two big goal families compete: OBSTACLES and COLORS.
  /// Whichever you're more behind on moves ahead. Within a family:
  ///   - obstacles: directly breakable ones, otherwise a box neighbor
  ///   - colors: the most-missing color
  /// If none exist, a normal tile.
  ///
  /// Both single propeller flights and propeller combos use this.
  List<Cell> propellerTargetsOrdered() {
    final directGoals = <Cell>[];
    final nextToStubborn = <Cell>[];
    final colorGoals = <Cell>[];
    final normal = <Cell>[];

    // Stubborn goals (box): can't be hit directly, broken via a neighbor.
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

    // Find the most-missing color; collect only the tiles of THAT color.
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

    // --- Family selection: who is more behind? ---
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

    // 1. Lock onto the target (reticle appears)
    selected.tile?.isTargeted = true;
    notify();
    await Future.delayed(const Duration(milliseconds: 180));

    // 2. Propeller flies from source to target
    await flyPropeller(
      fromRow: fromR,
      fromCol: fromC,
      toRow: selected.row,
      toCol: selected.col,
    );

    // 3. Landed, detonate
    selected.tile?.isTargeted = false;
    markForDestruction(selected.row, selected.col, DamageSource.propeller);
    notify();
  }
}