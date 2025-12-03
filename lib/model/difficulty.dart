import 'dart:math';
import 'dart:ui';

import 'package:maze_app/model/maze_cell.dart';

enum Difficulty { easy, normal, hard }

Pair<int, int> getCellsForDifficulty(Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.easy:
      return Pair(10, 10);
    case Difficulty.normal:
      return Pair(11, 11);
    case Difficulty.hard:
      return Pair(12, 12);
  }
}

Pair<int, int> getCellsForScreenSize(Difficulty difficulty, Size screen) {
  final base = getCellsForDifficulty(difficulty); // npr. 11×11
  final isPortrait = screen.height > screen.width;

  // Maksimalno odstupanje od osnovnih dimenzija
  const scaleMin = 0.9; // -10%
  const scaleMax = 1.1; // +10%

  if (!isPortrait) {
    // ---------------------------
    // LANDSCAPE: uvijek 1:1 omjer
    // ---------------------------
    final minSide = min(screen.width, screen.height);

    // koliko piksela bi 1 polje trebalo imati u bazi
    final baseCellSize = minSide / base.a;

    // broj polja koji realno stane
    int cells = (minSide / baseCellSize).floor();

    // ograniči skaliranje
    final scaledMin = (base.a * scaleMin).round();
    final scaledMax = (base.a * scaleMax).round();
    cells = cells.clamp(scaledMin, scaledMax);

    return Pair(cells, cells);
  }

  // ---------------------------
  // PORTRAIT: popuni visinu, omjer može biti različit
  // ---------------------------
  final availableHeight = screen.height * 0.85;
  final cellHeight = availableHeight / base.a;

  // redovi uvijek popune visinu
  int rows = base.a;

  // koliko polja stane po širini
  int cols = (screen.width / cellHeight).floor();

  // minimalno 7 polja
  cols = max(cols, 7);

  // maksimalno koliko baza predviđa
  cols = min(cols, base.b);

  return Pair(rows, cols);
}
