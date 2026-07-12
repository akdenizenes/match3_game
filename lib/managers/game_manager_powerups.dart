part of 'game_manager.dart';

extension GameManagerPowerups on GameManager {

  Future<void> useRoyalHammer(int r, int c) async {
    markForDestruction(r, c, DamageSource.manual);
    await _processMatches();
    _checkWinCondition();
  }

  Future<void> useArrowBooster(int r) async {
    for (int c = 0; c < cols; c++) {
      markForDestruction(r, c, DamageSource.blast);
    }
    await _processMatches();
    _checkWinCondition();
  }

  Future<void> useCannonBooster(int c) async {
    for (int r = 0; r < rows; r++) {
      markForDestruction(r, c, DamageSource.blast);
    }
    await _processMatches();
    _checkWinCondition();
  }

  /// Only free tiles are shuffled: locked (honey) and blocker cells remain fixed.
  Future<void> useJesterHat() async {
    final freeCells = <Cell>[];
    for (var row in cells) {
      for (var cell in row) {
        if (cell.tile != null && cell.canHoldTile && !cell.isLocked) {
          freeCells.add(cell);
        }
      }
    }

    final tiles = freeCells.map((c) => c.tile!).toList()..shuffle();

    for (int i = 0; i < freeCells.length; i++) {
      final cell = freeCells[i];
      setTile(cell.row, cell.col, tiles[i]);
    }

    notify();
    await Future.delayed(const Duration(milliseconds: 300));

    if (_checkMatches()) await _processMatches();
    _checkWinCondition();
  }

  // ===========================================================
  // COMBINATIONS
  // ===========================================================

  Future<void> _convertMostFrequentToSpecialTargeted(
      TileType specialType, int startR, int startC) async {
    final mostColor = _mostFrequentColor();
    if (mostColor == null) return;

    final targeted = <ColorTile>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final t = tileAt(r, c);
        if (t != null && t.color == mostColor && cells[r][c].isMatchable) {
          targeted.add(t);
        }
      }
    }

    targeted.sort((a, b) {
      final dA = sqrt(pow(a.row - startR, 2) + pow(a.col - startC, 2));
      final dB = sqrt(pow(b.row - startR, 2) + pow(b.col - startC, 2));
      return dA.compareTo(dB);
    });

    for (final t in targeted) {
      t.isTargeted = true;
      notify();
      await Future.delayed(const Duration(milliseconds: 30));
    }
    await Future.delayed(const Duration(milliseconds: 300));

    for (final t in targeted) {
      t.isTargeted = false;
      t.type = specialType;
    }
    notify();
    await Future.delayed(const Duration(milliseconds: 600));

    for (final t in targeted) {
      markForDestruction(t.row, t.col, DamageSource.colorBomb);
      notify();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _activateDoubleColorBombCombo(int startR, int startC) async {
    final all = <Cell>[];
    for (var row in cells) {
      for (var cell in row) {
        if (!cell.isVoid) all.add(cell);
      }
    }

    all.sort((a, b) {
      final dA = sqrt(pow(a.row - startR, 2) + pow(a.col - startC, 2));
      final dB = sqrt(pow(b.row - startR, 2) + pow(b.col - startC, 2));
      return dA.compareTo(dB);
    });

    for (int i = 0; i < all.length; i++) {
      markForDestruction(all[i].row, all[i].col, DamageSource.colorBomb);
      if (i % 3 == 0) notify();
      await Future.delayed(const Duration(milliseconds: 15));
    }

    notify();
    score += 5000;
  }

  Future<void> _activateColorBombSpecialCombo(
      TileType specialType, int startR, int startC) async {
    await _convertMostFrequentToSpecialTargeted(specialType, startR, startC);
    score += 2000;
  }

  /// Blasts the center 3x3 (the opening of the double-propeller combo).
  void _blastCenter(int startR, int startC) {
    for (int r = max(0, startR - 1); r <= min(rows - 1, startR + 1); r++) {
      for (int c = max(0, startC - 1); c <= min(cols - 1, startC + 1); c++) {
        markForDestruction(r, c, DamageSource.propeller);
      }
    }
  }

  /// Propeller + Propeller: flies to three separate targets ONE AFTER ANOTHER.
  Future<void> _activateDoublePropellerCombo(int startR, int startC) async {
    _blastCenter(startR, startC);

    final targets = propellerTargetsOrdered();
    final selected = targets.take(min(3, targets.length)).toList();
    if (selected.isEmpty) {
      score += 500;
      return;
    }

    /// All are locked on at once: so the player can see in advance where it’s going.
    for (final cell in selected) {
      cell.tile?.isTargeted = true;
    }
    notify();
    await Future.delayed(const Duration(milliseconds: 250));

    int fromR = startR, fromC = startC;
    for (final cell in selected) {
      await flyPropeller(
        fromRow: fromR,
        fromCol: fromC,
        toRow: cell.row,
        toCol: cell.col,
        duration: const Duration(milliseconds: 420),
      );

      cell.tile?.isTargeted = false;
      markForDestruction(cell.row, cell.col, DamageSource.propeller);
      score += 100;
      notify();
      await Future.delayed(const Duration(milliseconds: 90));

      /// Let the next flight pick up where it left off — as if it were flying with a single propeller.
      fromR = cell.row;
      fromC = cell.col;
    }

    score += 500;
  }

  /// Propeller + (rocket / bomb): ONE propeller, ONE target.
  /// Carries a special piece on its back, lands on a target, and destroys the cell it lands on plus its four neighbors (in a plus sign pattern). It does not drop the rocket on the board or duplicate it.
  Future<void> _activatePropellerSpecialCombo(
      int startR, int startC, TileType carriedType) async {
    final targets = propellerTargetsOrdered();
    if (targets.isEmpty) {
      score += 300;
      return;
    }
    final target = targets.first;

    target.tile?.isTargeted = true;
    notify();
    await Future.delayed(const Duration(milliseconds: 220));

    await flyPropeller(
      fromRow: startR,
      fromCol: startC,
      toRow: target.row,
      toCol: target.col,
      carriedType: carriedType, 
      duration: const Duration(milliseconds: 500),
    );

    target.tile?.isTargeted = false;

    // Plus shape: the cell it lands on + right, left, bottom, top.
    // Blast source → stone blocks and honey are also destroyed; the box is removed by adjacent damage.
    const plus = [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final (dr, dc) in plus) {
      markForDestruction(target.row + dr, target.col + dc, DamageSource.blast);
    }

    notify();
    score += 300;
  }

  Future<bool> executeSpecialCombo(ColorTile t1, ColorTile t2) async {
    if (!t1.isSpecial || !t2.isSpecial) return false;

    t1.isMatched = true;
    t2.isMatched = true;

    if (t1.type == TileType.colorBomb && t2.type == TileType.colorBomb) {
      await _activateDoubleColorBombCombo(t2.row, t2.col);
      return true;
    }

    if (t1.type == TileType.colorBomb || t2.type == TileType.colorBomb) {
      final otherType = (t1.type == TileType.colorBomb) ? t2.type : t1.type;
      await _activateColorBombSpecialCombo(otherType, t2.row, t2.col);
      return true;
    }

    if (t1.type == TileType.propeller && t2.type == TileType.propeller) {
      await _activateDoublePropellerCombo(t2.row, t2.col);
      return true;
    }

    final isT1Prop = t1.type == TileType.propeller;
    final isT2Prop = t2.type == TileType.propeller;
    if (isT1Prop || isT2Prop) {
      final otherType = isT1Prop ? t2.type : t1.type;
      if (otherType == TileType.stripedHorizontal ||
          otherType == TileType.stripedVertical ||
          otherType == TileType.wrapped) {
        await _activatePropellerSpecialCombo(t2.row, t2.col, otherType);
        return true;
      }
    }

    return false;
  }
}