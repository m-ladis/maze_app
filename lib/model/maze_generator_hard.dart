import 'dart:math';

import 'package:maze_app/model/maze_cell.dart';
import 'package:maze_app/model/stack.dart';

import 'maze_generator.dart';

// easy 10x10
// normal 15x20
// hard 20x25

class MazeGeneratorHard {
  Random rand = Random();
  var mazeCells = List<List>.generate(
      mazeRowsHard,
          (i) => List<MazeCell>.generate(
          mazeColumnsHard, (index) => MazeCell(position: Pair(i, index)),
          growable: false),
      growable: false);
  var mazeStack = Stack<MazeCell>();

  void generate() {
    for (int i = 0; i < mazeRowsHard; i++) {
      for (int j = 0; j < mazeColumnsHard; j++) {
        mazeCells[i][j] = MazeCell(position: Pair(i, j));
      }
    }

    int startX = rand.nextInt(mazeRowsHard);
    int startY = rand.nextInt(mazeColumnsHard);

    mazeCells[startX][startY].isVisited = true;
    mazeStack.push(mazeCells[startX][startY]);

    while (mazeStack.isNotEmpty) {
      MazeCell topMazeCell = mazeStack.peek;
      var nextSteps = List<MazeCell>.empty(growable: true);

      if (topMazeCell.position.a > 0) {
        MazeCell leftNeighborMazeCell =
        (mazeCells[topMazeCell.position.a - 1][topMazeCell.position.b]);

        if (!leftNeighborMazeCell.isVisited) {
          nextSteps.add(leftNeighborMazeCell);
        }
      }
      if (topMazeCell.position.a < mazeRowsHard - 1) {
        MazeCell rightNeighborMazeCell =
        (mazeCells[topMazeCell.position.a + 1][topMazeCell.position.b]);

        if (!rightNeighborMazeCell.isVisited) {
          nextSteps.add(rightNeighborMazeCell);
        }
      }
      if (topMazeCell.position.b > 0) {
        MazeCell topNeighborMazeCell =
        (mazeCells[topMazeCell.position.a][topMazeCell.position.b - 1]);

        if (!topNeighborMazeCell.isVisited) {
          nextSteps.add(topNeighborMazeCell);
        }
      }
      if (topMazeCell.position.b < mazeColumnsHard - 1) {
        MazeCell bottomNeighborMazeCell =
        (mazeCells[topMazeCell.position.a][topMazeCell.position.b + 1]);

        if (!bottomNeighborMazeCell.isVisited) {
          nextSteps.add(bottomNeighborMazeCell);
        }
      }

      if (nextSteps.isNotEmpty) {
        MazeCell randomNextStepCell = nextSteps[rand.nextInt(nextSteps.length)];

        if (randomNextStepCell.position.a != topMazeCell.position.a) {
          if (topMazeCell.position.a - randomNextStepCell.position.a > 0) {
            topMazeCell.wallLeftOpened = true;
            randomNextStepCell.wallRightOpened = true;
          } else {
            topMazeCell.wallRightOpened = true;
            randomNextStepCell.wallLeftOpened = true;
          }
        }

        if (randomNextStepCell.position.b != topMazeCell.position.b) {
          if (topMazeCell.position.b - randomNextStepCell.position.b > 0) {
            topMazeCell.wallUpOpened = true;
            randomNextStepCell.wallDownOpened = true;
          } else {
            topMazeCell.wallDownOpened = true;
            randomNextStepCell.wallUpOpened = true;
          }
        }

        randomNextStepCell.isVisited = true;
        mazeStack.push(randomNextStepCell);
      } else {
        mazeStack.pop();
      }
    }

    (mazeCells[mazeRowsHard - 1][mazeColumnsHard - 1]).wallDownOpened = true;
  }
}
