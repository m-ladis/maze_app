import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maze_app/main_menu.dart';
import 'package:maze_app/model/maze_cell.dart';
import 'package:maze_app/model/maze_generator.dart';
import 'package:maze_app/model/path_finder.dart';

const mazePadding = 20.0;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainMenu(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final int mazeRows;
  final int mazeColumns;
  final bool hintEnabled;
  final Pair<int, int> playerPositionCell = Pair(0, 0);
  late MazeGenerator mazeGenerator;

  var hint = List<Pair<int, int>>.empty(growable: true);

  MyHomePage(
      {super.key,
      required this.title,
      required this.mazeRows,
      required this.mazeColumns,
      required this.hintEnabled}) {
    mazeGenerator = MazeGenerator(mazeColumns: mazeColumns, mazeRows: mazeRows);
  }

  @override
  State<StatefulWidget> createState() {
    return MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage> {
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
            if (widget.hintEnabled)
              Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                  child: ElevatedButton(
                      onPressed: () {
                        if (widget.hintEnabled) {
                          var fastestWayOut = findFastestWayOut(
                              widget.mazeRows,
                              widget.mazeColumns,
                              widget.playerPositionCell,
                              widget.mazeGenerator.mazeCells);
                          setState(() {
                            widget.hint =
                                calculateHint(fastestWayOut.toList()).toList();
                          });
                        }
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
                if (widget.playerPositionCell.b < widget.mazeColumns) {
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
                if (widget.playerPositionCell.b >= widget.mazeColumns) {
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
                padding:
                    const EdgeInsets.fromLTRB(mazePadding, 150, mazePadding, 0),
                child: CustomPaint(
                    painter: MazePainter(widget.mazeRows, widget.mazeColumns,
                        width, height, widget.mazeGenerator.mazeCells),
                    child: FutureBuilder<ui.Image>(
                        future: getUiImage("assets/lost_cat.png", 20, 20),
                        builder: (context, snapshot) {
                          return CustomPaint(
                              painter: PlayerPainter(
                                  widget.mazeRows,
                                  widget.mazeColumns,
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
                                        widget.mazeRows,
                                        widget.mazeColumns,
                                        width,
                                        height,
                                        widget.hint.toList(),
                                        snapshot.requireData),
                                    child: FutureBuilder<ui.Image>(
                                      future: getUiImage(
                                          "assets/mouse.jpeg", 20, 20),
                                      builder: (context, snapshot) {
                                        return CustomPaint(
                                            painter: MousePainter(
                                                widget.mazeRows,
                                                widget.mazeColumns,
                                                width,
                                                height,
                                                snapshot.requireData));
                                      },
                                    ),
                                  );
                                },
                              ));
                        })))));
  }
}

class MazeGeasture extends StatelessWidget {
  const MazeGeasture(
      {super.key,
      required this.child,
      required this.moveLeft,
      required this.moveUp,
      required this.moveRight,
      required this.moveDown});

  final Widget child;
  final Function() moveLeft;
  final Function() moveUp;
  final Function() moveRight;
  final Function() moveDown;

  @override
  Widget build(BuildContext context) {
    double initialX = 0;
    double initialY = 0;
    double distanceX = 0;
    double distanceY = 0;

    return SizedBox.expand(
      child: GestureDetector(
          onPanStart: (DragStartDetails details) {
            initialX = details.globalPosition.dx;
            initialY = details.globalPosition.dy;
          },
          onPanUpdate: (DragUpdateDetails details) {
            distanceX = details.globalPosition.dx - initialX;
            distanceY = details.globalPosition.dy - initialY;
          },
          onPanEnd: (DragEndDetails details) {
            if (distanceX.abs() > distanceY.abs()) {
              if (distanceX > 0) {
                debugPrint("swipe right");
                moveRight();
              } else if (distanceX < 0) {
                debugPrint("swipe left");
                moveLeft();
              }
            } else {
              if (distanceY > 0) {
                debugPrint("swipe down");
                moveDown();
              } else if (distanceY < 0) {
                debugPrint("swipe up");
                moveUp();
              }
            }
          },
          child: child),
    );
  }
}

class MazePainter extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final double width;
  final double height;
  final List<List<dynamic>> mazeCells;

  MazePainter(
      this.mazeRows, this.mazeColumns, this.width, this.height, this.mazeCells);

  @override
  void paint(Canvas canvas, Size size) {
    double wallLength = (width - mazePadding * 2) / mazeRows;

    for (var i = 0; i < mazeRows; i++) {
      for (var j = 0; j < mazeColumns; j++) {
        MazeCell mazeCell = mazeCells[i][j];
        if (!mazeCell.wallLeftOpened) {
          canvas.drawLine(
              Offset(mazeCell.position.a * wallLength,
                  mazeCell.position.b * wallLength),
              Offset(mazeCell.position.a * wallLength,
                  mazeCell.position.b * wallLength + wallLength),
              Paint());
        }
        if (!mazeCell.wallUpOpened) {
          canvas.drawLine(
              Offset(mazeCell.position.a * wallLength,
                  mazeCell.position.b * wallLength),
              Offset(mazeCell.position.a * wallLength + wallLength,
                  mazeCell.position.b * wallLength),
              Paint());
        }
        if (!mazeCell.wallRightOpened) {
          canvas.drawLine(
              Offset(mazeCell.position.a * wallLength + wallLength,
                  mazeCell.position.b * wallLength),
              Offset(mazeCell.position.a * wallLength + wallLength,
                  mazeCell.position.b * wallLength + wallLength),
              Paint());
        }
        if (!mazeCell.wallDownOpened) {
          canvas.drawLine(
              Offset(mazeCell.position.a * wallLength + wallLength,
                  mazeCell.position.b * wallLength + wallLength),
              Offset(mazeCell.position.a * wallLength,
                  mazeCell.position.b * wallLength + wallLength),
              Paint());
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class PlayerPainter extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final double width;
  final double height;
  final Pair playerPositionCell;
  final ui.Image playerIcon;

  PlayerPainter(this.mazeRows, this.mazeColumns, this.width, this.height,
      this.playerPositionCell, this.playerIcon);

  @override
  void paint(Canvas canvas, Size size) {
    double wallLength = (width - mazePadding * 2) / mazeRows;

    canvas.drawImage(
        playerIcon,
        Offset(playerPositionCell.a * wallLength + wallLength / 6,
            playerPositionCell.b * wallLength + wallLength / 6),
        Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PawsPainter extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final double width;
  final double height;
  final List<Pair<int, int>> pawsLocation;
  final ui.Image pawsIcon;

  PawsPainter(this.mazeRows, this.mazeColumns, this.width, this.height,
      this.pawsLocation, this.pawsIcon);

  @override
  void paint(Canvas canvas, Size size) {
    double wallLength = (width - mazePadding * 2) / mazeRows;

    for (var element in pawsLocation) {
      canvas.drawImage(pawsIcon,
          Offset(element.a * wallLength, element.b * wallLength), Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

Future<ui.Image> getUiImage(
    String imageAssetPath, int height, int width) async {
  final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
  final codec = await ui.instantiateImageCodec(
    assetImageByteData.buffer.asUint8List(),
    targetHeight: height,
    targetWidth: width,
  );
  final image = (await codec.getNextFrame()).image;
  return image;
}

class MousePainter extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final double width;
  final double height;
  final ui.Image mouseIcon;

  MousePainter(
      this.mazeRows, this.mazeColumns, this.width, this.height, this.mouseIcon);

  @override
  void paint(Canvas canvas, Size size) {
    Random rand = Random();
    int mouseX = rand.nextInt(mazeRows);
    int mouseY = rand.nextInt(mazeColumns);

    double wallLength = (width - mazePadding * 2) / mazeRows;

    canvas.drawImage(
        mouseIcon,
        Offset(mouseX * wallLength + wallLength / 6,
            mouseY * wallLength + wallLength / 6),
        Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
