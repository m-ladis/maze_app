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

Pair<int, int> getCellsForScreenSize(Difficulty difficulty, Size screenSize) {
  final mazeDimensions = getCellsForDifficulty(difficulty);
  final mazeCells = mazeDimensions.a * mazeDimensions.b;

  final screenAspectRatio = screenSize.height / screenSize.width;
  final mazeRows = (mazeDimensions.a * screenAspectRatio * 0.65).toInt();
  final mazeColumns = mazeCells / mazeRows;

  if (screenAspectRatio * 0.65 >= 1.0) {
    return Pair(mazeRows, mazeColumns.toInt());
  } else {
    return mazeDimensions;
  }
}
