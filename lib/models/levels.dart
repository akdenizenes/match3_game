import 'dart:math';
import 'level_data.dart';

/// =========================================================================
/// LEVEL MAPS
/// =========================================================================
///
/// 1-15  → hand-drawn. Tutorial arc: each level teaches one mechanic.
///          Order matters, don't touch it.
/// 16+   → procedural. Deterministic via `Random(levelNum)`: the same level
///          yields the same board on every open, so you don't have to draw
///          500 maps by hand.
///
/// Map alphabet (8 rows × 8 chars):
///
///   .  empty cell
///   #  VOID  — permanent hole. Tiles can't enter, can't be broken.
///             NOT for difficulty, but to give the board a shape.
///   B  Box              — only an adjacent match breaks it
///   S  Stone (block)    — a blast breaks it too
///   I  Ice              — sits on top of a tile, anything breaks it, doesn't lock
///   H  Honey            — LOCKS the tile beneath it
///   J  Jelly            — sits under a tile, cleared when a match lands on top
///
/// The only place to touch when adding a new obstacle: [_configFor].

const int _size = 8;

/// Top rows where no blocker/void is placed. Put an obstacle here and that
/// column's spawn mouth closes, halting the tile flow.
const int _safeRows = 2;

/// The maximum percentage of the board that can be blocker+void. Beyond this
/// it becomes unplayable.
const double _blockerCap = 0.22;

const Set<String> _blocking = {'B', 'S', '#'};

// =========================================================================
// HAND-DRAWN LEVELS (1-15)
// =========================================================================

const Map<int, List<String>> _maps = {
  // 1-2: warm-up. No obstacles.

  // 3: first boxes. Centered, easy to reach.
  3: [
    '........',
    '........',
    '........',
    '...BB...',
    '........',
    '........',
    '........',
    '........',
  ],

  // 4: box wall. Teaches you to work from the sides.
  4: [
    '........',
    '........',
    '..BBBB..',
    '........',
    '........',
    '........',
    '........',
    '........',
  ],

  // 5: ice intro. Harmless, just one extra hit.
  5: [
    '........',
    '..IIII..',
    '..IIII..',
    '........',
    '........',
    '........',
    '........',
    '........',
  ],

  // 6: stone block. Unlike the box, it demands a blast.
  6: [
    '........',
    '........',
    '...SS...',
    '...SS...',
    '........',
    '........',
    '........',
    '........',
  ],

  // 7: jelly. Four corners — drags the player toward the edges.
  7: [
    'JJ....JJ',
    'JJ....JJ',
    '........',
    '........',
    '........',
    '........',
    'JJ....JJ',
    'JJ....JJ',
  ],

  // 8: honey. The first real pain. Locks the tile, must be broken from a neighbor.
  8: [
    '........',
    '........',
    '...HH...',
    '...HH...',
    '........',
    '........',
    '........',
    '........',
  ],

  // 9: void for the first time. Not a hole, a SHAPE: corners clipped.
  9: [
    '##....##',
    '#......#',
    '........',
    '........',
    '........',
    '........',
    '#......#',
    '##....##',
  ],

  // 10: box + stone. Two different breaking logics on the same board.
  10: [
    '........',
    '........',
    '.BB..BB.',
    '...SS...',
    '...SS...',
    '.BB..BB.',
    '........',
    '........',
  ],

  // 11: honey + jelly. Honey locks on top, jelly is the target below.
  11: [
    '........',
    '.JJJJJJ.',
    '.J.HH.J.',
    '.J.HH.J.',
    '.J....J.',
    '.JJJJJJ.',
    '........',
    '........',
  ],

  // 12: diamond board. Pure shape, no obstacles — a breather.
  12: [
    '###..###',
    '##....##',
    '#......#',
    '........',
    '........',
    '#......#',
    '##....##',
    '###..###',
  ],

  // 13: stone corridor + ice. The board splits into two regions.
  13: [
    '........',
    '........',
    'SS.SS.SS',
    '........',
    '..IIII..',
    '........',
    'SS.SS.SS',
    '........',
  ],

  // 14: honey fortress. Boxes are the shell, honey the core.
  14: [
    '........',
    '..BBBB..',
    '..BHHB..',
    '..BHHB..',
    '..BBBB..',
    '........',
    '........',
    '........',
  ],

  // 15: everything at once. Reward level (checkLevelReward → 4 power-ups).
  15: [
    '#..JJ..#',
    '.S.JJ.S.',
    '..B..B..',
    'JJ.HH.JJ',
    'JJ.HH.JJ',
    '..B..B..',
    '.S.JJ.S.',
    '#..JJ..#',
  ],
};

// =========================================================================
// PROCEDURAL GENERATION (16+)
// =========================================================================

/// Which obstacle enters the pool at which level.
/// Introduced in a hand-drawn level, then set free in the procedural range.
List<String> _unlockedFor(int lvl) {
  final pool = <String>['B'];
  if (lvl >= 25) pool.add('I');
  if (lvl >= 40) pool.add('S');
  if (lvl >= 60) pool.add('J');
  if (lvl >= 85) pool.add('H');
  return pool;
}

/// Overlay sprinkle density. A breather every 10 levels.
double _overlayDensity(int lvl) {
  if (lvl % 10 == 0) return 0.05;
  return min(0.10 + (lvl - 16) * 0.0009, 0.24);
}

/// The main pattern for blockers. Random sprinkling looks ugly —
/// always build a recognizable shape first, then jitter on top of it.
void _applyArchetype(List<List<String>> g, String ch, int kind) {
  switch (kind) {
    case 0: // center cluster
      for (int r = 3; r < 5; r++) {
        for (int c = 3; c < 5; c++) g[r][c] = ch;
      }
    case 1: // bottom corners
      for (int r = 6; r < 8; r++) {
        for (final c in [0, 1, 6, 7]) g[r][c] = ch;
      }
    case 2: // cross
      for (int c = 2; c < 6; c++) g[4][c] = ch;
      for (int r = 3; r < 6; r++) {
        g[r][3] = ch;
        g[r][4] = ch;
      }
    case 3: // hollow ring
      for (int c = 2; c < 6; c++) {
        g[2][c] = ch;
        g[5][c] = ch;
      }
      for (int r = 2; r < 6; r++) {
        g[r][2] = ch;
        g[r][5] = ch;
      }
      for (int r = 3; r < 5; r++) {
        for (int c = 3; c < 5; c++) g[r][c] = '.';
      }
    case 4: // vertical bars
      for (int r = 3; r < 7; r++) {
        g[r][1] = ch;
        g[r][6] = ch;
      }
      for (int r = 4; r < 6; r++) {
        g[r][3] = ch;
        g[r][4] = ch;
      }
    case 5: // diagonal X
      for (int i = 2; i < 6; i++) {
        g[i][i] = ch;
        g[i][7 - i] = ch;
      }
    case 6: // base fortress
      for (int c = 2; c < 6; c++) g[6][c] = ch;
      for (int c = 3; c < 5; c++) g[5][c] = ch;
  }
}

/// Void only carves the EDGE of the board. Punching a hole in the middle
/// gives the player a "broken" feeling and makes the area unfeedable.
void _applyVoids(List<List<String>> g, int kind) {
  final pts = switch (kind) {
    0 => [(7, 0), (7, 7), (6, 0), (6, 7)],
    1 => [(6, 0), (7, 0), (6, 7), (7, 7), (5, 0), (5, 7)],
    _ => [(7, 0), (7, 1), (7, 6), (7, 7)],
  };
  for (final (r, c) in pts) g[r][c] = '#';
}

int _blockerCount(List<List<String>> g) {
  int n = 0;
  for (final row in g) {
    for (final ch in row) {
      if (_blocking.contains(ch)) n++;
    }
  }
  return n;
}

List<String> _proceduralMap(int lvl) {
  final rng = Random(lvl * 7919); // prime multiplier → neighboring levels don't look alike
  final g = List.generate(_size, (_) => List.filled(_size, '.'));

  final pool = _unlockedFor(lvl);
  final blockers = pool.where((c) => c == 'B' || c == 'S').toList();
  final overlays = pool.where((c) => c == 'I' || c == 'J' || c == 'H').toList();

  _applyArchetype(g, blockers[rng.nextInt(blockers.length)], rng.nextInt(7));

  if (lvl >= 110 && lvl % 10 != 0 && rng.nextDouble() < 0.35) {
    _applyVoids(g, rng.nextInt(3));
  }

  // Jitter: punch a few holes in the pattern so every level is unique. Symmetric.
  final holes = rng.nextInt(4);
  for (int i = 0; i < holes; i++) {
    final r = _safeRows + rng.nextInt(_size - _safeRows);
    final c = rng.nextInt(_size ~/ 2);
    if (g[r][c] == 'B' || g[r][c] == 'S') {
      g[r][c] = '.';
      g[r][_size - 1 - c] = '.';
    }
  }

  // Overlay sprinkle — cast onto the left half, mirror to the right.
  if (overlays.isNotEmpty) {
    final d = _overlayDensity(lvl);
    for (int r = _safeRows; r < _size; r++) {
      for (int c = 0; c < _size ~/ 2; c++) {
        if (g[r][c] != '.') continue;
        if (rng.nextDouble() >= d) continue;
        final o = overlays[rng.nextInt(overlays.length)];
        g[r][c] = o;
        g[r][_size - 1 - c] = o;
      }
    }
  }

  // --- SAFETY 1: keep top rows clean (so the spawn mouth stays open) ---
  for (int r = 0; r < _safeRows; r++) {
    for (int c = 0; c < _size; c++) {
      if (_blocking.contains(g[r][c])) g[r][c] = '.';
    }
  }

  // --- SAFETY 2: hard density cap, thin out from bottom to top ---
  // Single count + decrement. We used to recount the whole board at every cell (O(n⁴)).
  int count = _blockerCount(g);
  final maxBlockers = _blockerCap * _size * _size;
  thin:
  for (int r = _size - 1; r >= _safeRows; r--) {
    for (int c = 0; c < _size; c++) {
      if (count <= maxBlockers) break thin;
      if (g[r][c] == 'B' || g[r][c] == 'S') {
        g[r][c] = '.';
        count--;
      }
    }
  }

  // --- SAFETY 3: no column should be blocked from top to bottom ---
  for (int c = 0; c < _size; c++) {
    bool allBlocked = true;
    for (int r = 0; r < _size; r++) {
      if (!_blocking.contains(g[r][c])) allBlocked = false;
    }
    if (allBlocked) g[_size - 1][c] = '.';
  }

  return [for (final row in g) row.join()];
}

// =========================================================================
// CHAR → CELL
// =========================================================================

/// In later levels, obstacles get tougher. Same map, more moves required.
CellConfig _configFor(String ch, int lvl) {
  final boxHp = lvl >= 300 ? 3 : 2;
  final stoneHp = lvl >= 200 ? 3 : 2;
  final honeyHp = lvl >= 150 ? 3 : 2;

  return switch (ch) {
    '.' => const CellConfig(),
    '#' => const CellConfig(isVoid: true),
    'B' => CellConfig(blockerKind: 'box', hp: boxHp),
    'S' => CellConfig(blockerKind: 'stone', hp: stoneHp),
    'I' => const CellConfig(overlayKind: 'ice', hp: 1),
    'H' => CellConfig(overlayKind: 'honey', hp: honeyHp),
    'J' => const CellConfig(overlayKind: 'jelly', hp: 1),
    _ => throw ArgumentError('Unknown map character: "$ch"'),
  };
}

/// Returns the level's cell skeleton. null for 1-2 → plain empty board.
List<List<CellConfig>>? layoutForLevel(int levelNum, int rows, int cols) {
  assert(
    rows == _size && cols == _size,
    'levels.dart produces $_size×$_size maps, board is ${rows}x$cols.',
  );

  final map = _maps[levelNum] ??
      (levelNum >= 16 ? _proceduralMap(levelNum) : null);
  if (map == null) return null;

  assert(map.length == rows, 'Level $levelNum: ${map.length} rows, should be $rows.');

  return List.generate(rows, (r) {
    final line = map[r];
    assert(line.length == cols,
        'Level $levelNum row $r: ${line.length} chars, should be $cols.');
    return List.generate(cols, (c) => _configFor(line[c], levelNum));
  });
}

/// Does this level have obstacles? (for debug / level picker)
bool hasLayout(int levelNum) => _maps.containsKey(levelNum) || levelNum >= 16;

/// Print a level's map to the console. Handy while designing.
/// `debugPrint(previewLevel(137));`
String previewLevel(int levelNum) {
  final map = _maps[levelNum] ??
      (levelNum >= 16 ? _proceduralMap(levelNum) : null);
  if (map == null) return 'Level $levelNum: plain board';
  return 'Level $levelNum:\n${map.join('\n')}';
}