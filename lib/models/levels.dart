import 'dart:math';
import 'level_data.dart';

/// =========================================================================
/// SEVİYE HARİTALARI
/// =========================================================================
///
/// 1-15  → elle çizilmiş. Tutorial yayı: her bölüm bir mekanik öğretir.
///          Sırası önemli, dokunma.
/// 16+   → prosedürel. `Random(levelNum)` ile deterministik: aynı bölüm
///          her açılışta aynı tahtayı verir, 500 harita çizmene gerek yok.
///
/// Harita alfabesi (8 satır × 8 karakter):
///
///   .  boş hücre
///   #  VOID  — kalıcı delik. Taş giremez, kırılamaz.
///             Zorluk için DEĞİL, tahtaya şekil vermek için.
///   B  Box (kutu)       — sadece komşu eşleşme kırar
///   S  Stone (taş blok) — patlama da kırar
///   I  Ice (buz)        — taşın üstünde, her şey kırar, kilitlemez
///   H  Honey (bal)      — altındaki taşı KİLİTLER
///   J  Jelly (jöle)     — taşın altında, üstünde eşleşme olunca silinir
///
/// Yeni engel eklerken tek dokunulacak yer: [_configFor].

const int _size = 8;

/// Blocker/void koyulmayan üst satırlar. Buraya engel koyarsan o sütunun
/// spawn ağzı kapanır ve taş akışı durur.
const int _safeRows = 2;

/// Tahtanın en fazla yüzde kaçı blocker+void olabilir. Aşarsa oynanamaz.
const double _blockerCap = 0.22;

const Set<String> _blocking = {'B', 'S', '#'};

// =========================================================================
// ELLE ÇİZİLEN BÖLÜMLER (1-15)
// =========================================================================

const Map<int, List<String>> _maps = {
  // 1-2: ısınma. Engel yok.

  // 3: ilk kutular. Ortada, ulaşması kolay.
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

  // 4: kutu duvarı. Yanlardan çalışmayı öğretir.
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

  // 5: buz tanıtımı. Zararsız, sadece fazladan bir vuruş.
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

  // 6: taş blok. Kutunun aksine patlama ister.
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

  // 7: jöle. Dört köşe — oyuncuyu kenarlara sürükler.
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

  // 8: bal. İlk gerçek acı. Taşı kilitler, komşudan kırmak gerekir.
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

  // 9: void ilk kez. Delik değil, ŞEKİL: köşeler kesik.
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

  // 10: kutu + taş. İki farklı kırma mantığı aynı tahtada.
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

  // 11: bal + jöle. Bal üstte kilitler, jöle altta hedef.
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

  // 12: elmas tahta. Saf şekil, engel yok — nefes molası.
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

  // 13: taş koridor + buz. Tahta iki bölgeye ayrılır.
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

  // 14: bal kalesi. Kutular kabuk, bal çekirdek.
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

  // 15: her şey bir arada. Ödül bölümü (checkLevelReward → 4 power-up).
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
// PROSEDÜREL ÜRETİM (16+)
// =========================================================================

/// Hangi engel hangi bölümde havuza girer.
/// Elle çizilen bölümde tanıtılır, sonra prosedürelde serbest kalır.
List<String> _unlockedFor(int lvl) {
  final pool = <String>['B'];
  if (lvl >= 25) pool.add('I');
  if (lvl >= 40) pool.add('S');
  if (lvl >= 60) pool.add('J');
  if (lvl >= 85) pool.add('H');
  return pool;
}

/// Overlay serpiştirme yoğunluğu. Her 10 bölümde bir nefes molası.
double _overlayDensity(int lvl) {
  if (lvl % 10 == 0) return 0.05;
  return min(0.10 + (lvl - 16) * 0.0009, 0.24);
}

/// Blocker'ların ana deseni. Rastgele serpiştirme çirkin durur —
/// hep tanınabilir bir şekil kur, sonra üstüne jitter at.
void _applyArchetype(List<List<String>> g, String ch, int kind) {
  switch (kind) {
    case 0: // merkez küme
      for (int r = 3; r < 5; r++) {
        for (int c = 3; c < 5; c++) g[r][c] = ch;
      }
    case 1: // alt köşeler
      for (int r = 6; r < 8; r++) {
        for (final c in [0, 1, 6, 7]) g[r][c] = ch;
      }
    case 2: // haç
      for (int c = 2; c < 6; c++) g[4][c] = ch;
      for (int r = 3; r < 6; r++) {
        g[r][3] = ch;
        g[r][4] = ch;
      }
    case 3: // içi boş halka
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
    case 4: // dikey barlar
      for (int r = 3; r < 7; r++) {
        g[r][1] = ch;
        g[r][6] = ch;
      }
      for (int r = 4; r < 6; r++) {
        g[r][3] = ch;
        g[r][4] = ch;
      }
    case 5: // çapraz X
      for (int i = 2; i < 6; i++) {
        g[i][i] = ch;
        g[i][7 - i] = ch;
      }
    case 6: // taban kalesi
      for (int c = 2; c < 6; c++) g[6][c] = ch;
      for (int c = 3; c < 5; c++) g[5][c] = ch;
  }
}

/// Void sadece tahtanın KENARINI yontar. Ortaya delik açmak
/// oyuncuya "bozuk" hissi verir ve alanı beslenemez hale getirir.
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
  final rng = Random(lvl * 7919); // asal çarpan → komşu bölümler benzemesin
  final g = List.generate(_size, (_) => List.filled(_size, '.'));

  final pool = _unlockedFor(lvl);
  final blockers = pool.where((c) => c == 'B' || c == 'S').toList();
  final overlays = pool.where((c) => c == 'I' || c == 'J' || c == 'H').toList();

  _applyArchetype(g, blockers[rng.nextInt(blockers.length)], rng.nextInt(7));

  if (lvl >= 110 && lvl % 10 != 0 && rng.nextDouble() < 0.35) {
    _applyVoids(g, rng.nextInt(3));
  }

  // Jitter: deseni birkaç hücre delerek her bölümü tekilleştir. Simetrik.
  final holes = rng.nextInt(4);
  for (int i = 0; i < holes; i++) {
    final r = _safeRows + rng.nextInt(_size - _safeRows);
    final c = rng.nextInt(_size ~/ 2);
    if (g[r][c] == 'B' || g[r][c] == 'S') {
      g[r][c] = '.';
      g[r][_size - 1 - c] = '.';
    }
  }

  // Overlay serpiştirme — sol yarıya at, sağa aynala.
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

  // --- GÜVENLİK 1: üst satırlar temiz (spawn ağzı kapanmasın) ---
  for (int r = 0; r < _safeRows; r++) {
    for (int c = 0; c < _size; c++) {
      if (_blocking.contains(g[r][c])) g[r][c] = '.';
    }
  }

  // --- GÜVENLİK 2: sert yoğunluk tavanı, alttan yukarı seyrelt ---
  for (int r = _size - 1; r >= _safeRows; r--) {
    for (int c = 0; c < _size; c++) {
      if (_blockerCount(g) / (_size * _size) <= _blockerCap) break;
      if (g[r][c] == 'B' || g[r][c] == 'S') g[r][c] = '.';
    }
  }

  // --- GÜVENLİK 3: hiçbir sütun baştan sona kapalı olmasın ---
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
// KARAKTER → HÜCRE
// =========================================================================

/// Geç bölümlerde engeller sertleşir. Aynı harita, daha çok hamle.
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
    _ => throw ArgumentError('Bilinmeyen harita karakteri: "$ch"'),
  };
}

/// Seviyenin hücre iskeletini döner. 1-2 için null → düz boş tahta.
List<List<CellConfig>>? layoutForLevel(int levelNum, int rows, int cols) {
  assert(
    rows == _size && cols == _size,
    'levels.dart $_size×$_size harita üretir, tahta ${rows}x$cols.',
  );

  final map = _maps[levelNum] ??
      (levelNum >= 16 ? _proceduralMap(levelNum) : null);
  if (map == null) return null;

  assert(map.length == rows, 'Seviye $levelNum: ${map.length} satır, $rows olmalı.');

  return List.generate(rows, (r) {
    final line = map[r];
    assert(line.length == cols,
        'Seviye $levelNum satır $r: ${line.length} karakter, $cols olmalı.');
    return List.generate(cols, (c) => _configFor(line[c], levelNum));
  });
}

/// Bu bölümün engeli var mı? (debug / bölüm seçici için)
bool hasLayout(int levelNum) => _maps.containsKey(levelNum) || levelNum >= 16;

/// Bir bölümün haritasını konsola bas. Tasarım yaparken işe yarar.
/// `debugPrint(previewLevel(137));`
String previewLevel(int levelNum) {
  final map = _maps[levelNum] ??
      (levelNum >= 16 ? _proceduralMap(levelNum) : null);
  if (map == null) return 'Bölüm $levelNum: düz tahta';
  return 'Bölüm $levelNum:\n${map.join('\n')}';
}