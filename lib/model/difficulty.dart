import 'package:maze_app/model/maze_cell.dart';

enum Difficulty { easy, normal, hard }

Pair<int, int> getCellsForDifficulty(Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.easy:
      return Pair(10, 10);
    case Difficulty.normal:
      return Pair(20, 15);
    case Difficulty.hard:
      return Pair(20, 15);
  }
}
