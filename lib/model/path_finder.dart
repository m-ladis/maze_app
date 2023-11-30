import 'dart:collection';
import 'dart:core';

import 'maze_cell.dart';
import 'maze_generator.dart';

Iterable<Pair<int, int>> findFastestWayOut(
    Pair<int, int> playerLocation, List<List<dynamic>> mazeCells) {
  Pair<int, int> currentLocation = Pair(playerLocation.a, playerLocation.b);
  Pair<int, int> helperPair = Pair(0, 0);
  Queue<Pair<int, int>> coordinates = Queue<Pair<int, int>>();
  Map<Pair<int, int>, Pair<int, int>> parentCells = {};
  var visitedCells = List<List>.generate(mazeRows,
      (i) => List<int>.generate(mazeColumns, (index) => 0, growable: false),
      growable: false);

  coordinates.add(playerLocation);
  visitedCells[playerLocation.a][playerLocation.b] = 1;

  while (coordinates.isNotEmpty) {
    currentLocation = coordinates.first;
    coordinates.removeFirst();

    if (currentLocation.a == mazeRows - 1 &&
        currentLocation.b == mazeColumns - 1) {
      break;
    }
    if (currentLocation.b >= 0 &&
        currentLocation.b < mazeColumns &&
        currentLocation.a + 1 >= 0 &&
        currentLocation.a + 1 < mazeRows &&
        mazeCells[currentLocation.a][currentLocation.b].wallRightOpened &&
        visitedCells[currentLocation.a + 1][currentLocation.b] == 0) {
      helperPair = Pair(currentLocation.a + 1, currentLocation.b);
      coordinates.addLast(helperPair);
      visitedCells[helperPair.a][helperPair.b] = 1;
      parentCells[helperPair] = currentLocation;
    }
    if (currentLocation.b + 1 >= 0 &&
        currentLocation.b + 1 < mazeColumns &&
        currentLocation.a >= 0 &&
        currentLocation.a < mazeRows &&
        mazeCells[currentLocation.a][currentLocation.b].wallDownOpened &&
        visitedCells[currentLocation.a][currentLocation.b + 1] == 0) {
      helperPair = Pair(currentLocation.a, currentLocation.b + 1);
      coordinates.addLast(helperPair);
      visitedCells[helperPair.a][helperPair.b] = 1;
      parentCells[helperPair] = currentLocation;
    }
    if (currentLocation.b >= 0 &&
        currentLocation.b < mazeColumns &&
        currentLocation.a - 1 >= 0 &&
        currentLocation.a - 1 < mazeRows &&
        mazeCells[currentLocation.a][currentLocation.b].wallLeftOpened &&
        visitedCells[currentLocation.a - 1][currentLocation.b] == 0) {
      helperPair = Pair(currentLocation.a - 1, currentLocation.b);
      coordinates.addLast(helperPair);
      visitedCells[helperPair.a][helperPair.b] = 1;
      parentCells[helperPair] = currentLocation;
    }
    if (currentLocation.b - 1 >= 0 &&
        currentLocation.b - 1 < mazeColumns &&
        currentLocation.a >= 0 &&
        currentLocation.a < mazeRows &&
        mazeCells[currentLocation.a][currentLocation.b].wallUpOpened &&
        visitedCells[currentLocation.a][currentLocation.b - 1] == 0) {
      helperPair = Pair(currentLocation.a, currentLocation.b - 1);
      coordinates.addLast(helperPair);
      visitedCells[helperPair.a][helperPair.b] = 1;
      parentCells[helperPair] = currentLocation;
    }
  }

  List<Pair<int, int>> fastestWay = List<Pair<int, int>>.empty(growable: true);

  helperPair = Pair(mazeRows - 1, mazeColumns - 1);
  fastestWay.add(helperPair);

  while (helperPair.a != playerLocation.a || helperPair.b != playerLocation.b) {
    fastestWay.add(parentCells[helperPair]!);
    helperPair = parentCells[helperPair]!;
  }

  return fastestWay.reversed;
}

Iterable<Pair<int, int>> calculateHint(List<Pair<int, int>> fastestWayOut) {
  fastestWayOut.removeAt(0);
  if (fastestWayOut.length > 5) {
    return fastestWayOut.take(5);
  } else {
    return fastestWayOut.take(fastestWayOut.length);
  }
}
