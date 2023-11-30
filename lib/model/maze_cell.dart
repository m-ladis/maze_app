import 'dart:ui';

import 'package:equatable/equatable.dart';

class MazeCell {
  bool isVisited;
  final Pair<int, int> position;
  bool wallLeftOpened = false;
  bool wallUpOpened = false;
  bool wallRightOpened = false;
  bool wallDownOpened = false;

  MazeCell({this.isVisited = false, required this.position});
}

class Pair<T1, T2> extends Equatable{
  T1 a;
  T2 b;

  Pair(this.a, this.b);

  @override
  List<Object?> get props => ["$a-$b"];
}
