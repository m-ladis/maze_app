import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maze_app/difficulty.dart';
import 'package:maze_app/main_menu.dart';
import 'package:maze_app/model/maze_cell.dart';
import 'package:maze_app/model/maze_generator.dart';
import 'package:maze_app/model/maze_generator_normal.dart';
import 'package:maze_app/model/path_finder.dart';

import '../main.dart';
import '../maze_painter.dart';
import '../player_painter.dart';
import 'maze_generator_hard.dart';


class MyHomePageNormal extends StatefulWidget {
  final String title;
  final Difficulty difficulty;
  final Pair<int, int> playerPositionCell = Pair(0, 0);
  final MazeGeneratorNormal mazeGenerator = MazeGeneratorNormal();
  var hint = List<Pair<int, int>>.empty(growable: true);

  MyHomePageNormal({super.key, required this.title, required this.difficulty});

  @override
  State<StatefulWidget> createState() {
    return MyHomePageNormalState();
  }
}

class MyHomePageNormalState extends State<MyHomePageNormal> {
  @override
  initState() {
    super.initState();
    widget.mazeGenerator.generate();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: ElevatedButton(
                    onPressed: () {
                      var fastestWayOut = findFastestWayOut(
                          widget.playerPositionCell,
                          widget.mazeGenerator.mazeCells);
                      setState(() {
                        widget.hint =
                            calculateHint(fastestWayOut.toList()).toList();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0)),
                    child: const Row(
                      children: [Icon(Icons.lightbulb_rounded)],
                    ))),
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        widget.mazeGenerator.generate();
                        widget.playerPositionCell.a = 0;
                        widget.playerPositionCell.b = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0)),
                    child: const Row(
                      children: [Icon(Icons.replay)],
                    )))
          ],
        ),
        body: MazeGeasture(
            moveLeft: () {
              setState(() {
                if ((widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
                [widget.playerPositionCell.b])
                    .wallLeftOpened) {
                  widget.playerPositionCell.a = widget.playerPositionCell.a - 1;
                  widget.hint.clear();
                }
              });
            },
            moveUp: () {
              setState(() {
                if ((widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
                [widget.playerPositionCell.b])
                    .wallUpOpened) {
                  widget.playerPositionCell.b = widget.playerPositionCell.b - 1;
                  widget.hint.clear();
                }
              });
            },
            moveRight: () {
              setState(() {
                if ((widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
                [widget.playerPositionCell.b])
                    .wallRightOpened) {
                  widget.playerPositionCell.a = widget.playerPositionCell.a + 1;
                  widget.hint.clear();
                }
              });
            },
            moveDown: () {
              setState(() {
                if (widget.playerPositionCell.b < mazeColumnsNormal) {
                  if ((widget.mazeGenerator
                      .mazeCells[widget.playerPositionCell.a]
                  [widget.playerPositionCell.b])
                      .wallDownOpened) {
                    widget.playerPositionCell.b =
                        widget.playerPositionCell.b + 1;
                    widget.hint.clear();
                  }
                }
                //kraj igre
                if (widget.playerPositionCell.b >= mazeColumnsNormal) {
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text("Congratulations"),
                        content: const Text("You saved the cat"),
                        actions: [
                          ElevatedButton(
                            child: const Text("Play again"),
                            onPressed: () {
                              setState(() {
                                widget.mazeGenerator.generate();
                                widget.playerPositionCell.a = 0;
                                widget.playerPositionCell.b = 0;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                        elevation: 24,
                      ));
                }
              });
            },
            child: Padding(
                padding: const EdgeInsets.fromLTRB(mazePadding,150,mazePadding,0),
                child: CustomPaint(
                    painter: MazePainterNormal(
                        width, height, widget.mazeGenerator.mazeCells),
                    child: FutureBuilder<ui.Image>(
                        future: getUiImage("assets/lost_cat.png", 20, 20),
                        builder: (context, snapshot) {
                          return CustomPaint(
                              painter: PlayerPainterNormal(
                                  width,
                                  height,
                                  widget.playerPositionCell,
                                  snapshot.requireData),
                              child: FutureBuilder<ui.Image>(
                                future:
                                getUiImage("assets/cat_paws.png", 20, 20),
                                builder: (context, snapshot) {
                                  return CustomPaint(
                                    painter: PawsPainter(
                                        width,
                                        height,
                                        widget.hint.toList(),
                                        snapshot.requireData),
                                  );
                                },
                              ));
                        })))));
  }
}


class MyHomePageHard extends StatefulWidget {
  final String title;
  final Difficulty difficulty;
  final Pair<int, int> playerPositionCell = Pair(0, 0);
  final MazeGeneratorHard mazeGenerator = MazeGeneratorHard();
  var hint = List<Pair<int, int>>.empty(growable: true);

  MyHomePageHard({super.key, required this.title, required this.difficulty});

  @override
  State<StatefulWidget> createState() {
    return MyHomePageHardState();
  }
}

class MyHomePageHardState extends State<MyHomePageHard> {
  @override
  initState() {
    super.initState();
    widget.mazeGenerator.generate();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: ElevatedButton(
                    onPressed: () {
                      var fastestWayOut = findFastestWayOut(
                          widget.playerPositionCell,
                          widget.mazeGenerator.mazeCells);
                      setState(() {
                        widget.hint =
                            calculateHint(fastestWayOut.toList()).toList();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0)),
                    child: const Row(
                      children: [Icon(Icons.lightbulb_rounded)],
                    ))),
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        widget.mazeGenerator.generate();
                        widget.playerPositionCell.a = 0;
                        widget.playerPositionCell.b = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0)),
                    child: const Row(
                      children: [Icon(Icons.replay)],
                    )))
          ],
        ),
        body: MazeGeasture(
            moveLeft: () {
              setState(() {
                if ((widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
                [widget.playerPositionCell.b])
                    .wallLeftOpened) {
                  widget.playerPositionCell.a = widget.playerPositionCell.a - 1;
                  widget.hint.clear();
                }
              });
            },
            moveUp: () {
              setState(() {
                if ((widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
                [widget.playerPositionCell.b])
                    .wallUpOpened) {
                  widget.playerPositionCell.b = widget.playerPositionCell.b - 1;
                  widget.hint.clear();
                }
              });
            },
            moveRight: () {
              setState(() {
                if ((widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
                [widget.playerPositionCell.b])
                    .wallRightOpened) {
                  widget.playerPositionCell.a = widget.playerPositionCell.a + 1;
                  widget.hint.clear();
                }
              });
            },
            moveDown: () {
              setState(() {
                if (widget.playerPositionCell.b < mazeColumnsHard) {
                  if ((widget.mazeGenerator
                      .mazeCells[widget.playerPositionCell.a]
                  [widget.playerPositionCell.b])
                      .wallDownOpened) {
                    widget.playerPositionCell.b =
                        widget.playerPositionCell.b + 1;
                    widget.hint.clear();
                  }
                }
                //kraj igre
                if (widget.playerPositionCell.b >= mazeColumnsHard) {
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text("Congratulations"),
                        content: const Text("You saved the cat"),
                        actions: [
                          ElevatedButton(
                            child: const Text("Play again"),
                            onPressed: () {
                              setState(() {
                                widget.mazeGenerator.generate();
                                widget.playerPositionCell.a = 0;
                                widget.playerPositionCell.b = 0;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                        elevation: 24,
                      ));
                }
              });
            },
            child: Padding(
                padding: const EdgeInsets.fromLTRB(mazePadding,150,mazePadding,0),
                child: CustomPaint(
                    painter: MazePainterHard(
                        width, height, widget.mazeGenerator.mazeCells),
                    child: FutureBuilder<ui.Image>(
                        future: getUiImage("assets/lost_cat.png", 20, 20),
                        builder: (context, snapshot) {
                          return CustomPaint(
                              painter: PlayerPainterHard(
                                  width,
                                  height,
                                  widget.playerPositionCell,
                                  snapshot.requireData),
                              child: FutureBuilder<ui.Image>(
                                future:
                                getUiImage("assets/cat_paws.png", 20, 20),
                                builder: (context, snapshot) {
                                  return CustomPaint(
                                    painter: PawsPainter(
                                        width,
                                        height,
                                        widget.hint.toList(),
                                        snapshot.requireData),
                                  );
                                },
                              ));
                        })))));
  }
}