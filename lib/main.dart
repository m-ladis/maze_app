

import 'dart:math';
import 'dart:ui' as ui;
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
      title: 'Maze App',
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
  bool mouseEnabled;
  final Pair<int, int> playerPositionCell = Pair(0, 0);
  final rand = Random();
  late Pair<int, int> mousePositionCell;
  late MazeGenerator mazeGenerator;
  var hint = List<Pair<int, int>>.empty(growable: true);

  MyHomePage({
    super.key,
    required this.title,
    required this.mazeRows,
    required this.mazeColumns,
    required this.hintEnabled,
    required this.mouseEnabled,
  }) {
    mazeGenerator = MazeGenerator(mazeColumns: mazeColumns, mazeRows: mazeRows);
    mousePositionCell =
        Pair(rand.nextInt(mazeRows - 1) + 1, rand.nextInt(mazeColumns - 1) + 1);
  }

  @override
  State<StatefulWidget> createState() {
    return MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin {
  late AnimationController _playerPulseController;
  late AnimationController _pawsController;
  late ui.Image playerImage;
  late ui.Image pawImage;
  bool imageLoaded = false;

  @override
  void initState() {
    super.initState();
    widget.mazeGenerator.generate();
    if (widget.mouseEnabled) {
      widget.mazeGenerator.closeDoors();
    } else {
      widget.mazeGenerator.openDoors();
    }

    _playerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);

    _pawsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _loadImages();
  }

  void _loadImages() async {
    playerImage = await loadImage('assets/cat.png');
    pawImage = await loadImage('assets/paw.png'); // stavi ispravnu putanju
    setState(() {
      imageLoaded = true;
    });
  }

  Future<ui.Image> loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _playerPulseController.dispose();
    _pawsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AppBar(
              backgroundColor: const Color(0xFF3A4F75).withOpacity(0.85),
              elevation: 0,
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/cat.png', height: 30),
                  const SizedBox(width: 10),
                  const Text(
                    "Maze Game",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              actions: [
                if (widget.hintEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: IconButton(
                      icon: const Icon(Icons.lightbulb_rounded, color: Colors.yellowAccent),
                      tooltip: "Show Hint",
                      onPressed: () {
                        var fastestWayOut = findFastestWayOut(
                          widget.mazeRows,
                          widget.mazeColumns,
                          widget.playerPositionCell,
                          widget.mazeGenerator.mazeCells,
                        );
                        setState(() {
                          widget.hint = calculateHint(fastestWayOut.toList()).toList();
                          _pawsController.forward(from: 0); // restart animacije
                        });
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: IconButton(
                    icon: const Icon(Icons.replay, color: Colors.white),
                    tooltip: "Restart Maze",
                    onPressed: () {
                      setState(() {
                        widget.mazeGenerator.generate();
                        widget.playerPositionCell.a = 0;
                        widget.playerPositionCell.b = 0;
                        widget.mousePositionCell = Pair(
                            widget.rand.nextInt(widget.mazeRows - 1) + 1,
                            widget.rand.nextInt(widget.mazeColumns - 1) + 1);
                        widget.hint.clear();
                      });
                      if (widget.mouseEnabled) {
                        widget.mazeGenerator.closeDoors();
                      } else {
                        widget.mazeGenerator.openDoors();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF3A4F75),
        child: Center(
          child: MazeGeasture(
            moveLeft: _moveLeft,
            moveUp: _moveUp,
            moveRight: _moveRight,
            moveDown: _moveDown,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double cellWidth = (constraints.maxWidth - mazePadding * 2) / widget.mazeRows;
                double cellHeight = (constraints.maxHeight - mazePadding * 2) / widget.mazeColumns;
                double cellSize = min(cellWidth, cellHeight);

                double offsetX = (constraints.maxWidth - (cellSize * widget.mazeRows)) / 2;
                double offsetY = (constraints.maxHeight - (cellSize * widget.mazeColumns)) / 2;

                return Stack(
                  children: [
                    CustomPaint(
                      painter: MazePainterStyled(
                        mazeRows: widget.mazeRows,
                        mazeColumns: widget.mazeColumns,
                        mazeCells:
                            widget.mazeGenerator.mazeCells.cast<List<MazeCell>>(),
                        cellSize: cellSize,
                        offsetX: offsetX,
                        offsetY: offsetY,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                    if (imageLoaded)
                      AnimatedBuilder(
                        animation: _playerPulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: PlayerPainterStyled(
                              mazeRows: widget.mazeRows,
                              mazeColumns: widget.mazeColumns,
                              playerPositionCell: widget.playerPositionCell,
                              scale: _playerPulseController.value,
                              playerImage: playerImage,
                              cellSize: cellSize,
                              offsetX: offsetX,
                              offsetY: offsetY,
                            ),
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                          );
                        },
                      ),
                    CustomPaint(
                      painter: MousePainterStyled(
                        mazeRows: widget.mazeRows,
                        mazeColumns: widget.mazeColumns,
                        mousePositionCell: widget.mousePositionCell,
                        isEnabled: widget.mouseEnabled,
                        cellSize: cellSize,
                        offsetX: offsetX,
                        offsetY: offsetY,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                    if (imageLoaded)
                      AnimatedBuilder(
                        animation: _pawsController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: PawHintPainterAnimated(
                              mazeRows: widget.mazeRows,
                              mazeColumns: widget.mazeColumns,
                              pawsLocation: widget.hint.toList(),
                              pawImage: pawImage,
                              progress: _pawsController.value,
                              cellSize: cellSize,
                              offsetX: offsetX,
                              offsetY: offsetY,
                            ),
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _moveLeft() => _movePlayer(-1, 0);
  void _moveRight() => _movePlayer(1, 0);
  void _moveUp() => _movePlayer(0, -1);
  void _moveDown() => _movePlayer(0, 1);

  void _movePlayer(int dx, int dy) {
    setState(() {
      int newA = widget.playerPositionCell.a + dx;
      int newB = widget.playerPositionCell.b + dy;

      final cell = widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
          [widget.playerPositionCell.b];

      bool canMove = false;
      if (dx == -1 && cell.wallLeftOpened) canMove = true;
      if (dx == 1 && cell.wallRightOpened) canMove = true;
      if (dy == -1 && cell.wallUpOpened) canMove = true;
      if (dy == 1 && cell.wallDownOpened) canMove = true;

      if (canMove) {
        widget.playerPositionCell.a = newA;
        widget.playerPositionCell.b = newB;
        widget.hint.clear();
      }

      if (widget.playerPositionCell.a == widget.mousePositionCell.a &&
          widget.playerPositionCell.b == widget.mousePositionCell.b) {
        widget.mouseEnabled = false;
        widget.mazeGenerator.openDoors();
      }

      if (widget.playerPositionCell.b >= widget.mazeColumns) {
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: const Text("Congratulations"),
                  content: const Text("You saved the cat!"),
                  actions: [
                    ElevatedButton(
                      child: const Text("Play again"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ));
      }
    });
  }
}

/// Gesture detector
class MazeGeasture extends StatelessWidget {
  const MazeGeasture({
    super.key,
    required this.child,
    required this.moveLeft,
    required this.moveUp,
    required this.moveRight,
    required this.moveDown,
  });

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
              moveRight();
            } else {
              moveLeft();
            }
          } else {
            if (distanceY > 0) {
              moveDown();
            } else {
              moveUp();
            }
          }
        },
        child: child,
      ),
    );
  }
}

/// -----------------
/// Painters with scaling & centering
/// -----------------

// class MazePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<List<MazeCell>> mazeCells;
//   final double cellSize;
//   final double offsetX;
//   final double offsetY;
//
//   MazePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mazeCells,
//     required this.cellSize,
//     required this.offsetX,
//     required this.offsetY,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     for (var i = 0; i < mazeRows; i++) {
//       for (var j = 0; j < mazeColumns; j++) {
//         MazeCell mazeCell = mazeCells[i][j];
//         final x = mazeCell.position.a * cellSize + offsetX;
//         final y = mazeCell.position.b * cellSize + offsetY;
//
//         // Paint sa gradientom
//         final paint = Paint()
//           ..strokeWidth = 4
//           ..style = PaintingStyle.stroke
//           ..shader = ui.Gradient.linear(
//             Offset(x, y),
//             Offset(x + cellSize, y + cellSize),
//             [Colors.white, Colors.grey.shade400],
//           )
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2); // blur za "soft edge"
//
//         // Crtanje zidova
//         if (!mazeCell.wallLeftOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x, y + cellSize), paint);
//         }
//         if (!mazeCell.wallUpOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x + cellSize, y), paint);
//         }
//         if (!mazeCell.wallRightOpened) {
//           canvas.drawLine(
//               Offset(x + cellSize, y), Offset(x + cellSize, y + cellSize), paint);
//         }
//         if (!mazeCell.wallDownOpened) {
//           canvas.drawLine(
//               Offset(x, y + cellSize), Offset(x + cellSize, y + cellSize), paint);
//         }
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }


class MazePainterStyled extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final List<List<MazeCell>> mazeCells;
  final double cellSize;
  final double offsetX;
  final double offsetY;

  MazePainterStyled({
    required this.mazeRows,
    required this.mazeColumns,
    required this.mazeCells,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    for (var i = 0; i < mazeRows; i++) {
      for (var j = 0; j < mazeColumns; j++) {
        MazeCell mazeCell = mazeCells[i][j];
        final x = mazeCell.position.a * cellSize + offsetX;
        final y = mazeCell.position.b * cellSize + offsetY;

        if (!mazeCell.wallLeftOpened) {
          canvas.drawLine(Offset(x, y), Offset(x, y + cellSize), paint);
        }
        if (!mazeCell.wallUpOpened) {
          canvas.drawLine(Offset(x, y), Offset(x + cellSize, y), paint);
        }
        if (!mazeCell.wallRightOpened) {
          canvas.drawLine(
              Offset(x + cellSize, y),
              Offset(x + cellSize, y + cellSize),
              paint);
        }
        if (!mazeCell.wallDownOpened) {
          canvas.drawLine(
              Offset(x, y + cellSize), Offset(x + cellSize, y + cellSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlayerPainterStyled extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final Pair playerPositionCell;
  final double scale;
  final ui.Image playerImage;
  final double cellSize;
  final double offsetX;
  final double offsetY;

  PlayerPainterStyled({
    required this.mazeRows,
    required this.mazeColumns,
    required this.playerPositionCell,
    required this.scale,
    required this.playerImage,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double centerX = playerPositionCell.a * cellSize + cellSize / 2 + offsetX;
    double centerY = playerPositionCell.b * cellSize + cellSize / 2 + offsetY;
    double imageSize = cellSize * scale;

    Rect dstRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: imageSize,
        height: imageSize);

    canvas.drawImageRect(
        playerImage,
        Rect.fromLTWH(0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
        dstRect,
        Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MousePainterStyled extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final Pair<int, int> mousePositionCell;
  final bool isEnabled;
  final double cellSize;
  final double offsetX;
  final double offsetY;

  MousePainterStyled({
    required this.mazeRows,
    required this.mazeColumns,
    required this.mousePositionCell,
    required this.isEnabled,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isEnabled) return;

    final paint = Paint()..color = Colors.red;
    double centerX = mousePositionCell.a * cellSize + cellSize / 2 + offsetX;
    double centerY = mousePositionCell.b * cellSize + cellSize / 2 + offsetY;
    double radius = cellSize / 3;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PawHintPainterAnimated extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final List<Pair<int, int>> pawsLocation;
  final ui.Image pawImage;
  final double progress;
  final double cellSize;
  final double offsetX;
  final double offsetY;

  PawHintPainterAnimated({
    required this.mazeRows,
    required this.mazeColumns,
    required this.pawsLocation,
    required this.pawImage,
    required this.progress,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pawsLocation.isEmpty) return;

    double maxScale = 0.5;
    int n = pawsLocation.length;

    for (int index = 0; index < n; index++) {
      var paw = pawsLocation[index];

      double pawStart = index / n;
      double pawEnd = (index + 1) / n;
      double pawProgress = ((progress - pawStart) / (pawEnd - pawStart)).clamp(0.0, 1.0);

      double rotation = 0;
      if (index < n - 1) {
        var nextPaw = pawsLocation[index + 1];
        double dx = nextPaw.b - paw.b.toDouble();
        double dy = nextPaw.a - paw.a.toDouble();

        if (dx == 0 && dy != 0) {
          rotation = (dy > 0) ? pi / 2 : -pi / 2;
        } else {
          rotation = (dx > 0) ? pi : 0;
        }
      }

      List<Offset> offsets = [
        Offset(-cellSize * 0.15, -cellSize * 0.15),
        Offset(cellSize * 0.15, cellSize * 0.15),
      ];

      for (var offset in offsets) {
        double centerX = paw.a * cellSize + cellSize / 2 + offset.dx + offsetX;
        double centerY = paw.b * cellSize + cellSize / 2 + offset.dy + offsetY;

        double scale = (cellSize / pawImage.width) * maxScale * pawProgress;

        canvas.save();
        canvas.translate(centerX, centerY);
        canvas.rotate(rotation);
        canvas.drawImageRect(
            pawImage,
            Rect.fromLTWH(0, 0, pawImage.width.toDouble(), pawImage.height.toDouble()),
            Rect.fromCenter(
                center: Offset(0, 0),
                width: pawImage.width.toDouble() * scale,
                height: pawImage.height.toDouble() * scale),
            Paint());
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}






















// import 'dart:math';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:maze_app/main_menu.dart';
// import 'package:maze_app/model/maze_cell.dart';
// import 'package:maze_app/model/maze_generator.dart';
// import 'package:maze_app/model/path_finder.dart';
//
// const mazePadding = 20.0;
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Maze App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MainMenu(),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   final String title;
//   final int mazeRows;
//   final int mazeColumns;
//   final bool hintEnabled;
//   bool mouseEnabled;
//   final Pair<int, int> playerPositionCell = Pair(0, 0);
//   final rand = Random();
//   late Pair<int, int> mousePositionCell;
//   late MazeGenerator mazeGenerator;
//   var hint = List<Pair<int, int>>.empty(growable: true);
//
//   MyHomePage({
//     super.key,
//     required this.title,
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.hintEnabled,
//     required this.mouseEnabled,
//   }) {
//     mazeGenerator = MazeGenerator(mazeColumns: mazeColumns, mazeRows: mazeRows);
//     mousePositionCell =
//         Pair(rand.nextInt(mazeRows - 1) + 1, rand.nextInt(mazeColumns - 1) + 1);
//   }
//
//   @override
//   State<StatefulWidget> createState() {
//     return MyHomePageState();
//   }
// }
//
// class MyHomePageState extends State<MyHomePage>
//     with TickerProviderStateMixin {
//   late AnimationController _playerPulseController;
//   late AnimationController _pawsController;
//   late ui.Image playerImage;
//   late ui.Image pawImage;
//   bool imageLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     widget.mazeGenerator.generate();
//     if (widget.mouseEnabled) {
//       widget.mazeGenerator.closeDoors();
//     } else {
//       widget.mazeGenerator.openDoors();
//     }
//
//     _playerPulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//       lowerBound: 0.8,
//       upperBound: 1.2,
//     )..repeat(reverse: true);
//
//     // Kontroler za šapice (0.0 -> 1.0)
//     _pawsController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..forward();
//
//     _loadImages();
//   }
//
//   void _loadImages() async {
//     playerImage = await loadImage('assets/cat.png');
//     pawImage = await loadImage('assets/paw.png'); // stavi ispravnu putanju
//     setState(() {
//       imageLoaded = true;
//     });
//   }
//
//   Future<ui.Image> loadImage(String assetPath) async {
//     final data = await rootBundle.load(assetPath);
//     final bytes = data.buffer.asUint8List();
//     final codec = await ui.instantiateImageCodec(bytes);
//     final frame = await codec.getNextFrame();
//     return frame.image;
//   }
//
//   @override
//   void dispose() {
//     _playerPulseController.dispose();
//     _pawsController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     double height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//
// appBar: PreferredSize(
//   preferredSize: const Size.fromHeight(70),
//   child: ClipRRect(
//     child: BackdropFilter(
//       filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//       child: AppBar(
//         backgroundColor: const Color(0xFF3A4F75).withOpacity(0.85),
//         elevation: 0,
//         centerTitle: true,
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset('assets/cat.png', height: 30),
//             const SizedBox(width: 10),
//             const Text(
//               "Maze Game",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//                 letterSpacing: 1.1,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           if (widget.hintEnabled)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 5),
//               child: IconButton(
//                 icon: const Icon(Icons.lightbulb_rounded, color: Colors.yellowAccent),
//                 tooltip: "Show Hint",
//                 onPressed: () {
//                   var fastestWayOut = findFastestWayOut(
//                     widget.mazeRows,
//                     widget.mazeColumns,
//                     widget.playerPositionCell,
//                     widget.mazeGenerator.mazeCells,
//                   );
//                   setState(() {
//                     widget.hint = calculateHint(fastestWayOut.toList()).toList();
//                     _pawsController.forward(from: 0); // restart animacije
//                   });
//                 },
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 5),
//             child: IconButton(
//               icon: const Icon(Icons.replay, color: Colors.white),
//               tooltip: "Restart Maze",
//               onPressed: () {
//                 setState(() {
//                   widget.mazeGenerator.generate();
//                   widget.playerPositionCell.a = 0;
//                   widget.playerPositionCell.b = 0;
//                   widget.mousePositionCell = Pair(
//                       widget.rand.nextInt(widget.mazeRows - 1) + 1,
//                       widget.rand.nextInt(widget.mazeColumns - 1) + 1);
//                   widget.hint.clear();
//                 });
//                 if (widget.mouseEnabled) {
//                   widget.mazeGenerator.closeDoors();
//                 } else {
//                   widget.mazeGenerator.openDoors();
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     ),
//   ),
// ),
//
//
//       body: Container(
//         color: const Color(0xFF3A4F75),
//         child: Center(
//           child: MazeGeasture(
//             moveLeft: _moveLeft,
//             moveUp: _moveUp,
//             moveRight: _moveRight,
//             moveDown: _moveDown,
//             child: Padding(
//               padding: const EdgeInsets.all(mazePadding),
//               child: Stack(
//                 children: [
//                   CustomPaint(
//                     painter: MazePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mazeCells:
//                           widget.mazeGenerator.mazeCells.cast<List<MazeCell>>(),
//                     ),
//                     size: Size(width, height),
//                   ),
//                   if (imageLoaded)
//                     AnimatedBuilder(
//                       animation: _playerPulseController,
//                       builder: (context, child) {
//                         return CustomPaint(
//                           painter: PlayerPainterStyled(
//                             mazeRows: widget.mazeRows,
//                             mazeColumns: widget.mazeColumns,
//                             playerPositionCell: widget.playerPositionCell,
//                             scale: _playerPulseController.value,
//                             playerImage: playerImage,
//                           ),
//                           size: Size(width, height),
//                         );
//                       },
//                     ),
//                   CustomPaint(
//                     painter: MousePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mousePositionCell: widget.mousePositionCell,
//                       isEnabled: widget.mouseEnabled,
//                     ),
//                     size: Size(width, height),
//                   ),
//                   if (imageLoaded)
//                     AnimatedBuilder(
//                       animation: _pawsController,
//                       builder: (context, child) {
//                         return CustomPaint(
//                           painter: PawHintPainterAnimated(
//                             mazeRows: widget.mazeRows,
//                             mazeColumns: widget.mazeColumns,
//                             pawsLocation: widget.hint.toList(),
//                             pawImage: pawImage,
//                             progress: _pawsController.value,
//                           ),
//                           size: Size(width, height),
//                         );
//                       },
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _moveLeft() => _movePlayer(-1, 0);
//   void _moveRight() => _movePlayer(1, 0);
//   void _moveUp() => _movePlayer(0, -1);
//   void _moveDown() => _movePlayer(0, 1);
//
//   void _movePlayer(int dx, int dy) {
//     setState(() {
//       int newA = widget.playerPositionCell.a + dx;
//       int newB = widget.playerPositionCell.b + dy;
//
//       final cell = widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
//           [widget.playerPositionCell.b];
//
//       bool canMove = false;
//       if (dx == -1 && cell.wallLeftOpened) canMove = true;
//       if (dx == 1 && cell.wallRightOpened) canMove = true;
//       if (dy == -1 && cell.wallUpOpened) canMove = true;
//       if (dy == 1 && cell.wallDownOpened) canMove = true;
//
//       if (canMove) {
//         widget.playerPositionCell.a = newA;
//         widget.playerPositionCell.b = newB;
//         widget.hint.clear();
//       }
//
//       if (widget.playerPositionCell.a == widget.mousePositionCell.a &&
//           widget.playerPositionCell.b == widget.mousePositionCell.b) {
//         widget.mouseEnabled = false;
//         widget.mazeGenerator.openDoors();
//       }
//
//       if (widget.playerPositionCell.b >= widget.mazeColumns) {
//         showDialog(
//             barrierDismissible: false,
//             context: context,
//             builder: (BuildContext context) => AlertDialog(
//                   title: const Text("Congratulations"),
//                   content: const Text("You saved the cat!"),
//                   actions: [
//                     ElevatedButton(
//                       child: const Text("Play again"),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pop(context);
//                       },
//                     ),
//                   ],
//                 ));
//       }
//     });
//   }
// }
//
// /// Gesture detector
// class MazeGeasture extends StatelessWidget {
//   const MazeGeasture({
//     super.key,
//     required this.child,
//     required this.moveLeft,
//     required this.moveUp,
//     required this.moveRight,
//     required this.moveDown,
//   });
//
//   final Widget child;
//   final Function() moveLeft;
//   final Function() moveUp;
//   final Function() moveRight;
//   final Function() moveDown;
//
//   @override
//   Widget build(BuildContext context) {
//     double initialX = 0;
//     double initialY = 0;
//     double distanceX = 0;
//     double distanceY = 0;
//
//     return SizedBox.expand(
//       child: GestureDetector(
//         onPanStart: (DragStartDetails details) {
//           initialX = details.globalPosition.dx;
//           initialY = details.globalPosition.dy;
//         },
//         onPanUpdate: (DragUpdateDetails details) {
//           distanceX = details.globalPosition.dx - initialX;
//           distanceY = details.globalPosition.dy - initialY;
//         },
//         onPanEnd: (DragEndDetails details) {
//           if (distanceX.abs() > distanceY.abs()) {
//             if (distanceX > 0) {
//               moveRight();
//             } else {
//               moveLeft();
//             }
//           } else {
//             if (distanceY > 0) {
//               moveDown();
//             } else {
//               moveUp();
//             }
//           }
//         },
//         child: child,
//       ),
//     );
//   }
// }
//
// /// -----------------
// /// Painters
// /// -----------------
//
// class MazePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<List<MazeCell>> mazeCells;
//
//   MazePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mazeCells,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 3;
//
//     for (var i = 0; i < mazeRows; i++) {
//       for (var j = 0; j < mazeColumns; j++) {
//         MazeCell mazeCell = mazeCells[i][j];
//         final x = mazeCell.position.a * wallLength;
//         final y = mazeCell.position.b * wallLength;
//
//         if (!mazeCell.wallLeftOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x, y + wallLength), paint);
//         }
//         if (!mazeCell.wallUpOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x + wallLength, y), paint);
//         }
//         if (!mazeCell.wallRightOpened) {
//           canvas.drawLine(
//               Offset(x + wallLength, y),
//               Offset(x + wallLength, y + wallLength),
//               paint);
//         }
//         if (!mazeCell.wallDownOpened) {
//           canvas.drawLine(Offset(x, y + wallLength),
//               Offset(x + wallLength, y + wallLength), paint);
//         }
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
//
// class PlayerPainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair playerPositionCell;
//   final double scale;
//   final ui.Image playerImage;
//
//   PlayerPainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.playerPositionCell,
//     required this.scale,
//     required this.playerImage,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//
//     double centerX = playerPositionCell.a * wallLength + wallLength / 2;
//     double centerY = playerPositionCell.b * wallLength + wallLength / 2;
//     double imageSize = wallLength * scale;
//
//     Rect dstRect = Rect.fromCenter(
//         center: Offset(centerX, centerY),
//         width: imageSize,
//         height: imageSize);
//
//     canvas.drawImageRect(
//         playerImage,
//         Rect.fromLTWH(
//             0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
//         dstRect,
//         Paint());
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class MousePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair<int, int> mousePositionCell;
//   final bool isEnabled;
//
//   MousePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mousePositionCell,
//     required this.isEnabled,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (!isEnabled) return;
//
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()..color = Colors.red;
//
//     double centerX = mousePositionCell.a * wallLength + wallLength / 2;
//     double centerY = mousePositionCell.b * wallLength + wallLength / 2;
//     double radius = wallLength / 3;
//
//     canvas.drawCircle(Offset(centerX, centerY), radius, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// /// -----------------
// /// Paw Painter Animated
// /// -----------------
// /// -----------------
// /// Paw Painter Animated with rotation
// /// -----------------
// class PawHintPainterAnimated extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<Pair<int, int>> pawsLocation;
//   final ui.Image pawImage;
//   final double progress; // 0.0 -> 1.0
//
//   PawHintPainterAnimated({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.pawsLocation,
//     required this.pawImage,
//     required this.progress,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (pawsLocation.isEmpty) return;
//
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     double maxScale = 0.5;
//     int n = pawsLocation.length;
//
//     for (int index = 0; index < n-1; index++) {
//       var paw = pawsLocation[index];
//
//       // Animacija šapice (po progressu)
//       double pawStart = index / n;
//       double pawEnd = (index + 1) / n;
//       double pawProgress =
//           ((progress - pawStart) / (pawEnd - pawStart)).clamp(0.0, 1.0);
//
//       // Odredi kut rotacije prema sljedećoj šapici
//       double rotation = 0;
//       if (index < n - 1) {
//         var nextPaw = pawsLocation[index + 1];
//
//         double dx = nextPaw.b - paw.b.toDouble(); // horizontalno
//         double dy = nextPaw.a - paw.a.toDouble(); // vertikalno
//
//         if (dx == 0 && dy != 0) {
//           // Ako se pomiče samo gore ili dolje
//           rotation = (dy > 0) ? pi / 2 : -pi / 2; // dolje ili gore
//         } else {
//           // Horizontalno ili dijagonalno → normalno
//           rotation = (dx > 0) ? pi : 0;
//         }
//       }
//
//       // Dvije šapice po polju
//       List<Offset> offsets = [
//         Offset(-wallLength * 0.15, -wallLength * 0.15), // gornja-lijevo
//         Offset(wallLength * 0.15, wallLength * 0.15),  // donja-desno
//       ];
//
//       for (var offset in offsets) {
//         double centerX = paw.a * wallLength + wallLength / 2 + offset.dx;
//         double centerY = paw.b * wallLength + wallLength / 2 + offset.dy;
//
//         double scale = (wallLength / pawImage.width) * maxScale * pawProgress;
//
//         canvas.save();
//         canvas.translate(centerX, centerY);
//         canvas.rotate(rotation);
//         Rect dstRect = Rect.fromCenter(
//           center: Offset(0, 0),
//           width: pawImage.width * scale,
//           height: pawImage.height * scale,
//         );
//         canvas.drawImageRect(
//           pawImage,
//           Rect.fromLTWH(0, 0, pawImage.width.toDouble(),
//               pawImage.height.toDouble()),
//           dstRect,
//           Paint(),
//         );
//         canvas.restore();
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant PawHintPainterAnimated oldDelegate) => true;
// }









// import 'dart:math';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:maze_app/main_menu.dart';
// import 'package:maze_app/model/maze_cell.dart';
// import 'package:maze_app/model/maze_generator.dart';
// import 'package:maze_app/model/path_finder.dart';
//
// const mazePadding = 20.0;
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Maze App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MainMenu(),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   final String title;
//   final int mazeRows;
//   final int mazeColumns;
//   final bool hintEnabled;
//   bool mouseEnabled;
//   final Pair<int, int> playerPositionCell = Pair(0, 0);
//   final rand = Random();
//   late Pair<int, int> mousePositionCell;
//   late MazeGenerator mazeGenerator;
//   var hint = List<Pair<int, int>>.empty(growable: true);
//
//   MyHomePage({
//     super.key,
//     required this.title,
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.hintEnabled,
//     required this.mouseEnabled,
//   }) {
//     mazeGenerator = MazeGenerator(mazeColumns: mazeColumns, mazeRows: mazeRows);
//     mousePositionCell =
//         Pair(rand.nextInt(mazeRows - 1) + 1, rand.nextInt(mazeColumns - 1) + 1);
//   }
//
//   @override
//   State<StatefulWidget> createState() {
//     return MyHomePageState();
//   }
// }
//
// class MyHomePageState extends State<MyHomePage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _playerPulseController;
//   late ui.Image playerImage;
//   late ui.Image pawImage;
//   bool imageLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     widget.mazeGenerator.generate();
//     if (widget.mouseEnabled) {
//       widget.mazeGenerator.closeDoors();
//     } else {
//       widget.mazeGenerator.openDoors();
//     }
//
//     _playerPulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//       lowerBound: 0.8,
//       upperBound: 1.2,
//     )..repeat(reverse: true);
//
//     _loadImages();
//   }
//
//   void _loadImages() async {
//     // Promijenjene putanje na assets
//     playerImage = await loadImage('assets/cat.png');
//     pawImage = await loadImage('assets/paw.png');
//     setState(() {
//       imageLoaded = true;
//     });
//   }
//
//   Future<ui.Image> loadImage(String assetPath) async {
//     final data = await rootBundle.load(assetPath);
//     final bytes = data.buffer.asUint8List();
//     final codec = await ui.instantiateImageCodec(bytes);
//     final frame = await codec.getNextFrame();
//     return frame.image;
//   }
//
//   @override
//   void dispose() {
//     _playerPulseController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     double height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.deepPurple,
//         title: Text(widget.title),
//         actions: [
//           if (widget.hintEnabled)
//             IconButton(
//               icon: const Icon(Icons.lightbulb_rounded),
//               onPressed: () {
//                 var fastestWayOut = findFastestWayOut(
//                     widget.mazeRows,
//                     widget.mazeColumns,
//                     widget.playerPositionCell,
//                     widget.mazeGenerator.mazeCells);
//                 setState(() {
//                   widget.hint = calculateHint(fastestWayOut.toList()).toList();
//                 });
//               },
//             ),
//           IconButton(
//             icon: const Icon(Icons.replay),
//             onPressed: () {
//               setState(() {
//                 widget.mazeGenerator.generate();
//                 widget.playerPositionCell.a = 0;
//                 widget.playerPositionCell.b = 0;
//                 widget.mousePositionCell = Pair(
//                     widget.rand.nextInt(widget.mazeRows - 1) + 1,
//                     widget.rand.nextInt(widget.mazeColumns - 1) + 1);
//               });
//               if (widget.mouseEnabled) {
//                 widget.mazeGenerator.closeDoors();
//               } else {
//                 widget.mazeGenerator.openDoors();
//               }
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.deepPurple, Colors.blueAccent],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: MazeGeasture(
//             moveLeft: _moveLeft,
//             moveUp: _moveUp,
//             moveRight: _moveRight,
//             moveDown: _moveDown,
//             child: Padding(
//               padding: const EdgeInsets.all(mazePadding),
//               child: Stack(
//                 children: [
//                   CustomPaint(
//                     painter: MazePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mazeCells:
//                           widget.mazeGenerator.mazeCells.cast<List<MazeCell>>(),
//                     ),
//                     size: Size(width, height),
//                   ),
//                   if (imageLoaded)
//                     AnimatedBuilder(
//                       animation: _playerPulseController,
//                       builder: (context, child) {
//                         return CustomPaint(
//                           painter: PlayerPainterStyled(
//                             mazeRows: widget.mazeRows,
//                             mazeColumns: widget.mazeColumns,
//                             playerPositionCell: widget.playerPositionCell,
//                             scale: _playerPulseController.value,
//                             playerImage: playerImage,
//                           ),
//                           size: Size(width, height),
//                         );
//                       },
//                     ),
//                   CustomPaint(
//                     painter: MousePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mousePositionCell: widget.mousePositionCell,
//                       isEnabled: widget.mouseEnabled,
//                     ),
//                     size: Size(width, height),
//                   ),
//                   if (imageLoaded)
//                     CustomPaint(
//                       painter: PawHintPainterStyled(
//                         mazeRows: widget.mazeRows,
//                         mazeColumns: widget.mazeColumns,
//                         pawsLocation: widget.hint.toList(),
//                         pawImage: pawImage,
//                       ),
//                       size: Size(width, height),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _moveLeft() => _movePlayer(-1, 0);
//   void _moveRight() => _movePlayer(1, 0);
//   void _moveUp() => _movePlayer(0, -1);
//   void _moveDown() => _movePlayer(0, 1);
//
//   void _movePlayer(int dx, int dy) {
//     setState(() {
//       int newA = widget.playerPositionCell.a + dx;
//       int newB = widget.playerPositionCell.b + dy;
//
//       final cell = widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
//           [widget.playerPositionCell.b];
//
//       bool canMove = false;
//       if (dx == -1 && cell.wallLeftOpened) canMove = true;
//       if (dx == 1 && cell.wallRightOpened) canMove = true;
//       if (dy == -1 && cell.wallUpOpened) canMove = true;
//       if (dy == 1 && cell.wallDownOpened) canMove = true;
//
//       if (canMove) {
//         widget.playerPositionCell.a = newA;
//         widget.playerPositionCell.b = newB;
//         widget.hint.clear();
//       }
//
//       if (widget.playerPositionCell.a == widget.mousePositionCell.a &&
//           widget.playerPositionCell.b == widget.mousePositionCell.b) {
//         widget.mouseEnabled = false;
//         widget.mazeGenerator.openDoors();
//       }
//
//       if (widget.playerPositionCell.b >= widget.mazeColumns) {
//         showDialog(
//             barrierDismissible: false,
//             context: context,
//             builder: (BuildContext context) => AlertDialog(
//                   title: const Text("Congratulations"),
//                   content: const Text("You saved the cat!"),
//                   actions: [
//                     ElevatedButton(
//                       child: const Text("Play again"),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pop(context);
//                       },
//                     ),
//                   ],
//                 ));
//       }
//     });
//   }
// }
//
// class MazeGeasture extends StatelessWidget {
//   const MazeGeasture({
//     super.key,
//     required this.child,
//     required this.moveLeft,
//     required this.moveUp,
//     required this.moveRight,
//     required this.moveDown,
//   });
//
//   final Widget child;
//   final Function() moveLeft;
//   final Function() moveUp;
//   final Function() moveRight;
//   final Function() moveDown;
//
//   @override
//   Widget build(BuildContext context) {
//     double initialX = 0;
//     double initialY = 0;
//     double distanceX = 0;
//     double distanceY = 0;
//
//     return SizedBox.expand(
//       child: GestureDetector(
//         onPanStart: (DragStartDetails details) {
//           initialX = details.globalPosition.dx;
//           initialY = details.globalPosition.dy;
//         },
//         onPanUpdate: (DragUpdateDetails details) {
//           distanceX = details.globalPosition.dx - initialX;
//           distanceY = details.globalPosition.dy - initialY;
//         },
//         onPanEnd: (DragEndDetails details) {
//           if (distanceX.abs() > distanceY.abs()) {
//             if (distanceX > 0) {
//               moveRight();
//             } else {
//               moveLeft();
//             }
//           } else {
//             if (distanceY > 0) {
//               moveDown();
//             } else {
//               moveUp();
//             }
//           }
//         },
//         child: child,
//       ),
//     );
//   }
// }
//
// /// -----------------
// /// Styled Painters
// /// -----------------
//
// class MazePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<List<MazeCell>> mazeCells;
//
//   MazePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mazeCells,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 3;
//
//     for (var i = 0; i < mazeRows; i++) {
//       for (var j = 0; j < mazeColumns; j++) {
//         MazeCell mazeCell = mazeCells[i][j];
//         final x = mazeCell.position.a * wallLength;
//         final y = mazeCell.position.b * wallLength;
//
//         if (!mazeCell.wallLeftOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x, y + wallLength), paint);
//         }
//         if (!mazeCell.wallUpOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x + wallLength, y), paint);
//         }
//         if (!mazeCell.wallRightOpened) {
//           canvas.drawLine(
//               Offset(x + wallLength, y),
//               Offset(x + wallLength, y + wallLength),
//               paint);
//         }
//         if (!mazeCell.wallDownOpened) {
//           canvas.drawLine(Offset(x, y + wallLength),
//               Offset(x + wallLength, y + wallLength), paint);
//         }
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
//
// class PlayerPainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair playerPositionCell;
//   final double scale;
//   final ui.Image playerImage;
//
//   PlayerPainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.playerPositionCell,
//     required this.scale,
//     required this.playerImage,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//
//     double centerX = playerPositionCell.a * wallLength + wallLength / 2;
//     double centerY = playerPositionCell.b * wallLength + wallLength / 2;
//     double imageSize = wallLength * 0.8 * scale; // 80% od cell size
//
//     Rect dstRect = Rect.fromCenter(
//         center: Offset(centerX, centerY),
//         width: imageSize,
//         height: imageSize);
//
//     canvas.drawImageRect(
//         playerImage,
//         Rect.fromLTWH(
//             0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
//         dstRect,
//         Paint());
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class MousePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair<int, int> mousePositionCell;
//   final bool isEnabled;
//
//   MousePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mousePositionCell,
//     required this.isEnabled,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (!isEnabled) return;
//
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()..color = Colors.red;
//
//     double centerX = mousePositionCell.a * wallLength + wallLength / 2;
//     double centerY = mousePositionCell.b * wallLength + wallLength / 2;
//     double radius = wallLength / 3;
//
//     canvas.drawCircle(Offset(centerX, centerY), radius, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class PawHintPainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<Pair<int, int>> pawsLocation;
//   final ui.Image pawImage;
//
//   PawHintPainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.pawsLocation,
//     required this.pawImage,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//
//     for (int index = 0; index < pawsLocation.length; index++) {
//       var paw = pawsLocation[index];
//
//       double centerX = paw.a * wallLength + wallLength / 2;
//       double centerY = paw.b * wallLength + wallLength / 2;
//
//       double sizePaw = wallLength * 0.5; // 50% of cell size
//       Rect dstRect = Rect.fromCenter(
//           center: Offset(centerX, centerY),
//           width: sizePaw,
//           height: sizePaw);
//
//       canvas.drawImageRect(
//           pawImage,
//           Rect.fromLTWH(
//               0, 0, pawImage.width.toDouble(), pawImage.height.toDouble()),
//           dstRect,
//           Paint());
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }






// import 'dart:math';
// import 'dart:ui' as ui;
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:maze_app/main_menu.dart';
// import 'package:maze_app/model/maze_cell.dart';
// import 'package:maze_app/model/maze_generator.dart';
// import 'package:maze_app/model/path_finder.dart';
//
// const mazePadding = 20.0;
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Maze App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MainMenu(),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   final String title;
//   final int mazeRows;
//   final int mazeColumns;
//   final bool hintEnabled;
//   bool mouseEnabled;
//   final Pair<int, int> playerPositionCell = Pair(0, 0);
//   final rand = Random();
//   late Pair<int, int> mousePositionCell;
//   late MazeGenerator mazeGenerator;
//   var hint = <Pair<int, int>>[];
//
//   MyHomePage({
//     super.key,
//     required this.title,
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.hintEnabled,
//     required this.mouseEnabled,
//   }) {
//     mazeGenerator = MazeGenerator(mazeColumns: mazeColumns, mazeRows: mazeRows);
//     mousePositionCell =
//         Pair(rand.nextInt(mazeRows - 1) + 1, rand.nextInt(mazeColumns - 1) + 1);
//   }
//
//   @override
//   State<StatefulWidget> createState() {
//     return MyHomePageState();
//   }
// }
//
// class MyHomePageState extends State<MyHomePage>
//     with TickerProviderStateMixin {
//   late AnimationController _playerPulseController;
//   late AnimationController _pawsAnimationController;
//   late ui.Image playerImage;
//   bool imageLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     widget.mazeGenerator.generate();
//     if (widget.mouseEnabled) {
//       widget.mazeGenerator.closeDoors();
//     } else {
//       widget.mazeGenerator.openDoors();
//     }
//
//     _playerPulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//       lowerBound: 0.8,
//       upperBound: 1.2,
//     )..repeat(reverse: true);
//
//     _pawsAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     )..repeat();
//
//     _loadPlayerImage();
//   }
//
//   void _loadPlayerImage() async {
//     playerImage = await loadImage('assets/cat.png');
//     setState(() {
//       imageLoaded = true;
//     });
//   }
//
//   Future<ui.Image> loadImage(String assetPath) async {
//     final data = await rootBundle.load(assetPath);
//     final bytes = data.buffer.asUint8List();
//     final codec = await ui.instantiateImageCodec(bytes);
//     final frame = await codec.getNextFrame();
//     return frame.image;
//   }
//
//   @override
//   void dispose() {
//     _playerPulseController.dispose();
//     _pawsAnimationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     double height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.deepPurple,
//         title: Text(widget.title),
//         actions: [
//           if (widget.hintEnabled)
//             IconButton(
//               icon: const Icon(Icons.lightbulb_rounded),
//               onPressed: () {
//                 var fastestWayOut = findFastestWayOut(
//                     widget.mazeRows,
//                     widget.mazeColumns,
//                     widget.playerPositionCell,
//                     widget.mazeGenerator.mazeCells);
//                 setState(() {
//                   widget.hint = calculateHint(fastestWayOut.toList()).toList();
//                 });
//               },
//             ),
//           IconButton(
//             icon: const Icon(Icons.replay),
//             onPressed: () {
//               setState(() {
//                 widget.mazeGenerator.generate();
//                 widget.playerPositionCell.a = 0;
//                 widget.playerPositionCell.b = 0;
//                 widget.mousePositionCell = Pair(
//                     widget.rand.nextInt(widget.mazeRows - 1) + 1,
//                     widget.rand.nextInt(widget.mazeColumns - 1) + 1);
//                 widget.hint.clear();
//               });
//               if (widget.mouseEnabled) {
//                 widget.mazeGenerator.closeDoors();
//               } else {
//                 widget.mazeGenerator.openDoors();
//               }
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.deepPurple, Colors.blueAccent],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: MazeGeasture(
//             moveLeft: _moveLeft,
//             moveUp: _moveUp,
//             moveRight: _moveRight,
//             moveDown: _moveDown,
//             child: Padding(
//               padding: const EdgeInsets.all(mazePadding),
//               child: Stack(
//                 children: [
//                   CustomPaint(
//                     painter: MazePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mazeCells:
//                           widget.mazeGenerator.mazeCells.cast<List<MazeCell>>(),
//                     ),
//                     size: Size(width, height),
//                   ),
//                   if (imageLoaded)
//                     AnimatedBuilder(
//                       animation: _playerPulseController,
//                       builder: (context, child) {
//                         return CustomPaint(
//                           painter: PlayerPainterStyled(
//                             mazeRows: widget.mazeRows,
//                             mazeColumns: widget.mazeColumns,
//                             playerPositionCell: widget.playerPositionCell,
//                             scale: _playerPulseController.value,
//                             playerImage: playerImage,
//                           ),
//                           size: Size(width, height),
//                         );
//                       },
//                     ),
//                   CustomPaint(
//                     painter: MousePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mousePositionCell: widget.mousePositionCell,
//                       isEnabled: widget.mouseEnabled,
//                     ),
//                     size: Size(width, height),
//                   ),
//                   AnimatedBuilder(
//                     animation: _pawsAnimationController,
//                     builder: (context, child) {
//                       return CustomPaint(
//                         painter: PawsPainterAnimated(
//                           mazeRows: widget.mazeRows,
//                           mazeColumns: widget.mazeColumns,
//                           pawsLocation: widget.hint.toList(),
//                           progress: _pawsAnimationController.value,
//                         ),
//                         size: Size(width, height),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _moveLeft() => _movePlayer(-1, 0);
//   void _moveRight() => _movePlayer(1, 0);
//   void _moveUp() => _movePlayer(0, -1);
//   void _moveDown() => _movePlayer(0, 1);
//
//   void _movePlayer(int dx, int dy) {
//     setState(() {
//       int newA = widget.playerPositionCell.a + dx;
//       int newB = widget.playerPositionCell.b + dy;
//
//       final cell = widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
//           [widget.playerPositionCell.b];
//
//       bool canMove = false;
//       if (dx == -1 && cell.wallLeftOpened) canMove = true;
//       if (dx == 1 && cell.wallRightOpened) canMove = true;
//       if (dy == -1 && cell.wallUpOpened) canMove = true;
//       if (dy == 1 && cell.wallDownOpened) canMove = true;
//
//       if (canMove) {
//         widget.playerPositionCell.a = newA;
//         widget.playerPositionCell.b = newB;
//         widget.hint.clear();
//       }
//
//       if (widget.playerPositionCell.a == widget.mousePositionCell.a &&
//           widget.playerPositionCell.b == widget.mousePositionCell.b) {
//         widget.mouseEnabled = false;
//         widget.mazeGenerator.openDoors();
//       }
//
//       // End game
//       if (widget.playerPositionCell.b >= widget.mazeColumns) {
//         showDialog(
//             barrierDismissible: false,
//             context: context,
//             builder: (BuildContext context) => AlertDialog(
//                   title: const Text("Congratulations"),
//                   content: const Text("You saved the cat!"),
//                   actions: [
//                     ElevatedButton(
//                       child: const Text("Play again"),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pop(context);
//                       },
//                     ),
//                   ],
//                 ));
//       }
//     });
//   }
// }
//
// class MazeGeasture extends StatelessWidget {
//   const MazeGeasture({
//     super.key,
//     required this.child,
//     required this.moveLeft,
//     required this.moveUp,
//     required this.moveRight,
//     required this.moveDown,
//   });
//
//   final Widget child;
//   final Function() moveLeft;
//   final Function() moveUp;
//   final Function() moveRight;
//   final Function() moveDown;
//
//   @override
//   Widget build(BuildContext context) {
//     double initialX = 0;
//     double initialY = 0;
//     double distanceX = 0;
//     double distanceY = 0;
//
//     return SizedBox.expand(
//       child: GestureDetector(
//         onPanStart: (DragStartDetails details) {
//           initialX = details.globalPosition.dx;
//           initialY = details.globalPosition.dy;
//         },
//         onPanUpdate: (DragUpdateDetails details) {
//           distanceX = details.globalPosition.dx - initialX;
//           distanceY = details.globalPosition.dy - initialY;
//         },
//         onPanEnd: (DragEndDetails details) {
//           if (distanceX.abs() > distanceY.abs()) {
//             if (distanceX > 0) {
//               moveRight();
//             } else {
//               moveLeft();
//             }
//           } else {
//             if (distanceY > 0) {
//               moveDown();
//             } else {
//               moveUp();
//             }
//           }
//         },
//         child: child,
//       ),
//     );
//   }
// }
//
// /// -----------------
// /// Styled Painters
// /// -----------------
//
// class MazePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<List<MazeCell>> mazeCells;
//
//   MazePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mazeCells,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 3;
//
//     for (var i = 0; i < mazeRows; i++) {
//       for (var j = 0; j < mazeColumns; j++) {
//         MazeCell mazeCell = mazeCells[i][j];
//         final x = mazeCell.position.a * wallLength;
//         final y = mazeCell.position.b * wallLength;
//
//         if (!mazeCell.wallLeftOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x, y + wallLength), paint);
//         }
//         if (!mazeCell.wallUpOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x + wallLength, y), paint);
//         }
//         if (!mazeCell.wallRightOpened) {
//           canvas.drawLine(
//               Offset(x + wallLength, y),
//               Offset(x + wallLength, y + wallLength),
//               paint);
//         }
//         if (!mazeCell.wallDownOpened) {
//           canvas.drawLine(Offset(x, y + wallLength),
//               Offset(x + wallLength, y + wallLength), paint);
//         }
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
//
// class PlayerPainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair playerPositionCell;
//   final double scale;
//   final ui.Image playerImage;
//
//   PlayerPainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.playerPositionCell,
//     required this.scale,
//     required this.playerImage,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//
//     double centerX = playerPositionCell.a * wallLength + wallLength / 2;
//     double centerY = playerPositionCell.b * wallLength + wallLength / 2;
//     double imageSize = wallLength * scale;
//
//     Rect dstRect = Rect.fromCenter(
//         center: Offset(centerX, centerY),
//         width: imageSize,
//         height: imageSize);
//
//     canvas.drawImageRect(
//         playerImage,
//         Rect.fromLTWH(
//             0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
//         dstRect,
//         Paint());
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class MousePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair<int, int> mousePositionCell;
//   final bool isEnabled;
//
//   MousePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mousePositionCell,
//     required this.isEnabled,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (!isEnabled) return;
//
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()..color = Colors.red;
//
//     double centerX = mousePositionCell.a * wallLength + wallLength / 2;
//     double centerY = mousePositionCell.b * wallLength + wallLength / 2;
//     double radius = wallLength / 3;
//
//     canvas.drawCircle(Offset(centerX, centerY), radius, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class PawsPainterAnimated extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<Pair<int, int>> pawsLocation;
//   final double progress;
//
//   PawsPainterAnimated({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.pawsLocation,
//     required this.progress,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (pawsLocation.isEmpty) return;
//
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()..color = Colors.black;
//
//     int totalToShow = (pawsLocation.length * progress).floor();
//
//     for (int i = 0; i < totalToShow; i++) {
//       var paw = pawsLocation[i];
//       double centerX = paw.a * wallLength + wallLength / 2;
//       double centerY = paw.b * wallLength + wallLength / 2;
//
//       double pawSize = wallLength * 0.15;
//       double finger = pawSize * 0.5;
//
//       // dlan
//       canvas.drawCircle(Offset(centerX, centerY), pawSize, paint);
//       // prsti
//       canvas.drawCircle(Offset(centerX - finger, centerY - finger), finger, paint);
//       canvas.drawCircle(Offset(centerX, centerY - finger * 1.5), finger, paint);
//       canvas.drawCircle(Offset(centerX + finger, centerY - finger), finger, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant PawsPainterAnimated oldDelegate) =>
//       oldDelegate.progress != progress || oldDelegate.pawsLocation != pawsLocation;
// }




// import 'dart:math';
// import 'dart:ui' as ui;
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:maze_app/main_menu.dart';
// import 'package:maze_app/model/maze_cell.dart';
// import 'package:maze_app/model/maze_generator.dart';
// import 'package:maze_app/model/path_finder.dart';
//
// const mazePadding = 20.0;
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Maze App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MainMenu(),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   final String title;
//   final int mazeRows;
//   final int mazeColumns;
//   final bool hintEnabled;
//   bool mouseEnabled;
//   final Pair<int, int> playerPositionCell = Pair(0, 0);
//   final rand = Random();
//   late Pair<int, int> mousePositionCell;
//   late MazeGenerator mazeGenerator;
//   var hint = <Pair<int, int>>[];
//
//   MyHomePage({
//     super.key,
//     required this.title,
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.hintEnabled,
//     required this.mouseEnabled,
//   }) {
//     mazeGenerator = MazeGenerator(mazeColumns: mazeColumns, mazeRows: mazeRows);
//     mousePositionCell =
//         Pair(rand.nextInt(mazeRows - 1) + 1, rand.nextInt(mazeColumns - 1) + 1);
//   }
//
//   @override
//   State<StatefulWidget> createState() {
//     return MyHomePageState();
//   }
// }
//
// class MyHomePageState extends State<MyHomePage>
//     with TickerProviderStateMixin {
//   late AnimationController _playerPulseController;
//   late AnimationController _pawsAnimationController;
//   late ui.Image playerImage;
//   bool imageLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     widget.mazeGenerator.generate();
//     if (widget.mouseEnabled) {
//       widget.mazeGenerator.closeDoors();
//     } else {
//       widget.mazeGenerator.openDoors();
//     }
//
//     _playerPulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//       lowerBound: 0.8,
//       upperBound: 1.2,
//     )..repeat(reverse: true);
//
//     _pawsAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     )..repeat();
//
//     _loadPlayerImage();
//   }
//
//   void _loadPlayerImage() async {
//     playerImage = await loadImage('assets/cat.png');
//     setState(() {
//       imageLoaded = true;
//     });
//   }
//
//   Future<ui.Image> loadImage(String assetPath) async {
//     final data = await rootBundle.load(assetPath);
//     final bytes = data.buffer.asUint8List();
//     final codec = await ui.instantiateImageCodec(bytes);
//     final frame = await codec.getNextFrame();
//     return frame.image;
//   }
//
//   @override
//   void dispose() {
//     _playerPulseController.dispose();
//     _pawsAnimationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     double height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.deepPurple,
//         title: Text(widget.title),
//         actions: [
//           if (widget.hintEnabled)
//             IconButton(
//               icon: const Icon(Icons.lightbulb_rounded),
//               onPressed: () {
//                 var fastestWayOut = findFastestWayOut(
//                     widget.mazeRows,
//                     widget.mazeColumns,
//                     widget.playerPositionCell,
//                     widget.mazeGenerator.mazeCells);
//                 setState(() {
//                   widget.hint = calculateHint(fastestWayOut.toList()).toList();
//                 });
//               },
//             ),
//           IconButton(
//             icon: const Icon(Icons.replay),
//             onPressed: () {
//               setState(() {
//                 widget.mazeGenerator.generate();
//                 widget.playerPositionCell.a = 0;
//                 widget.playerPositionCell.b = 0;
//                 widget.mousePositionCell = Pair(
//                     widget.rand.nextInt(widget.mazeRows - 1) + 1,
//                     widget.rand.nextInt(widget.mazeColumns - 1) + 1);
//                 widget.hint.clear();
//               });
//               if (widget.mouseEnabled) {
//                 widget.mazeGenerator.closeDoors();
//               } else {
//                 widget.mazeGenerator.openDoors();
//               }
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.deepPurple, Colors.blueAccent],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: MazeGeasture(
//             moveLeft: _moveLeft,
//             moveUp: _moveUp,
//             moveRight: _moveRight,
//             moveDown: _moveDown,
//             child: Padding(
//               padding: const EdgeInsets.all(mazePadding),
//               child: Stack(
//                 children: [
//                   CustomPaint(
//                     painter: MazePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mazeCells:
//                           widget.mazeGenerator.mazeCells.cast<List<MazeCell>>(),
//                     ),
//                     size: Size(width, height),
//                   ),
//                   if (imageLoaded)
//                     AnimatedBuilder(
//                       animation: _playerPulseController,
//                       builder: (context, child) {
//                         return CustomPaint(
//                           painter: PlayerPainterStyled(
//                             mazeRows: widget.mazeRows,
//                             mazeColumns: widget.mazeColumns,
//                             playerPositionCell: widget.playerPositionCell,
//                             scale: _playerPulseController.value,
//                             playerImage: playerImage,
//                           ),
//                           size: Size(width, height),
//                         );
//                       },
//                     ),
//                   CustomPaint(
//                     painter: MousePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mousePositionCell: widget.mousePositionCell,
//                       isEnabled: widget.mouseEnabled,
//                     ),
//                     size: Size(width, height),
//                   ),
//                   AnimatedBuilder(
//                     animation: _pawsAnimationController,
//                     builder: (context, child) {
//                       return CustomPaint(
//                         painter: PawsPainterAnimated(
//                           mazeRows: widget.mazeRows,
//                           mazeColumns: widget.mazeColumns,
//                           pawsLocation: widget.hint.toList(),
//                           progress: _pawsAnimationController.value,
//                         ),
//                         size: Size(width, height),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _moveLeft() => _movePlayer(-1, 0);
//   void _moveRight() => _movePlayer(1, 0);
//   void _moveUp() => _movePlayer(0, -1);
//   void _moveDown() => _movePlayer(0, 1);
//
//   void _movePlayer(int dx, int dy) {
//     setState(() {
//       int newA = widget.playerPositionCell.a + dx;
//       int newB = widget.playerPositionCell.b + dy;
//
//       final cell = widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
//           [widget.playerPositionCell.b];
//
//       bool canMove = false;
//       if (dx == -1 && cell.wallLeftOpened) canMove = true;
//       if (dx == 1 && cell.wallRightOpened) canMove = true;
//       if (dy == -1 && cell.wallUpOpened) canMove = true;
//       if (dy == 1 && cell.wallDownOpened) canMove = true;
//
//       if (canMove) {
//         widget.playerPositionCell.a = newA;
//         widget.playerPositionCell.b = newB;
//         widget.hint.clear();
//       }
//
//       if (widget.playerPositionCell.a == widget.mousePositionCell.a &&
//           widget.playerPositionCell.b == widget.mousePositionCell.b) {
//         widget.mouseEnabled = false;
//         widget.mazeGenerator.openDoors();
//       }
//
//       // End game
//       if (widget.playerPositionCell.b >= widget.mazeColumns) {
//         showDialog(
//             barrierDismissible: false,
//             context: context,
//             builder: (BuildContext context) => AlertDialog(
//                   title: const Text("Congratulations"),
//                   content: const Text("You saved the cat!"),
//                   actions: [
//                     ElevatedButton(
//                       child: const Text("Play again"),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pop(context);
//                       },
//                     ),
//                   ],
//                 ));
//       }
//     });
//   }
// }
//
// class MazeGeasture extends StatelessWidget {
//   const MazeGeasture({
//     super.key,
//     required this.child,
//     required this.moveLeft,
//     required this.moveUp,
//     required this.moveRight,
//     required this.moveDown,
//   });
//
//   final Widget child;
//   final Function() moveLeft;
//   final Function() moveUp;
//   final Function() moveRight;
//   final Function() moveDown;
//
//   @override
//   Widget build(BuildContext context) {
//     double initialX = 0;
//     double initialY = 0;
//     double distanceX = 0;
//     double distanceY = 0;
//
//     return SizedBox.expand(
//       child: GestureDetector(
//         onPanStart: (DragStartDetails details) {
//           initialX = details.globalPosition.dx;
//           initialY = details.globalPosition.dy;
//         },
//         onPanUpdate: (DragUpdateDetails details) {
//           distanceX = details.globalPosition.dx - initialX;
//           distanceY = details.globalPosition.dy - initialY;
//         },
//         onPanEnd: (DragEndDetails details) {
//           if (distanceX.abs() > distanceY.abs()) {
//             if (distanceX > 0) {
//               moveRight();
//             } else {
//               moveLeft();
//             }
//           } else {
//             if (distanceY > 0) {
//               moveDown();
//             } else {
//               moveUp();
//             }
//           }
//         },
//         child: child,
//       ),
//     );
//   }
// }
//
// /// -----------------
// /// Styled Painters
// /// -----------------
//
// class MazePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<List<MazeCell>> mazeCells;
//
//   MazePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mazeCells,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 3;
//
//     for (var i = 0; i < mazeRows; i++) {
//       for (var j = 0; j < mazeColumns; j++) {
//         MazeCell mazeCell = mazeCells[i][j];
//         final x = mazeCell.position.a * wallLength;
//         final y = mazeCell.position.b * wallLength;
//
//         if (!mazeCell.wallLeftOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x, y + wallLength), paint);
//         }
//         if (!mazeCell.wallUpOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x + wallLength, y), paint);
//         }
//         if (!mazeCell.wallRightOpened) {
//           canvas.drawLine(
//               Offset(x + wallLength, y),
//               Offset(x + wallLength, y + wallLength),
//               paint);
//         }
//         if (!mazeCell.wallDownOpened) {
//           canvas.drawLine(Offset(x, y + wallLength),
//               Offset(x + wallLength, y + wallLength), paint);
//         }
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
//
// class PlayerPainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair playerPositionCell;
//   final double scale;
//   final ui.Image playerImage;
//
//   PlayerPainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.playerPositionCell,
//     required this.scale,
//     required this.playerImage,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//
//     double centerX = playerPositionCell.a * wallLength + wallLength / 2;
//     double centerY = playerPositionCell.b * wallLength + wallLength / 2;
//     double imageSize = wallLength * scale;
//
//     Rect dstRect = Rect.fromCenter(
//         center: Offset(centerX, centerY),
//         width: imageSize,
//         height: imageSize);
//
//     canvas.drawImageRect(
//         playerImage,
//         Rect.fromLTWH(
//             0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
//         dstRect,
//         Paint());
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class MousePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair<int, int> mousePositionCell;
//   final bool isEnabled;
//
//   MousePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mousePositionCell,
//     required this.isEnabled,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (!isEnabled) return;
//
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()..color = Colors.red;
//
//     double centerX = mousePositionCell.a * wallLength + wallLength / 2;
//     double centerY = mousePositionCell.b * wallLength + wallLength / 2;
//     double radius = wallLength / 3;
//
//     canvas.drawCircle(Offset(centerX, centerY), radius, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class PawsPainterAnimated extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<Pair<int, int>> pawsLocation;
//   final double progress;
//
//   PawsPainterAnimated({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.pawsLocation,
//     required this.progress,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (pawsLocation.isEmpty) return;
//
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()..color = Colors.black;
//
//     int totalToShow = (pawsLocation.length * progress).floor();
//
//     for (int i = 0; i < totalToShow; i++) {
//       var paw = pawsLocation[i];
//       double centerX = paw.a * wallLength + wallLength / 2;
//       double centerY = paw.b * wallLength + wallLength / 2;
//
//       double pawSize = wallLength * 0.15;
//       double finger = pawSize * 0.5;
//
//       // dlan
//       canvas.drawCircle(Offset(centerX, centerY), pawSize, paint);
//       // prsti
//       canvas.drawCircle(Offset(centerX - finger, centerY - finger), finger, paint);
//       canvas.drawCircle(Offset(centerX, centerY - finger * 1.5), finger, paint);
//       canvas.drawCircle(Offset(centerX + finger, centerY - finger), finger, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant PawsPainterAnimated oldDelegate) =>
//       oldDelegate.progress != progress || oldDelegate.pawsLocation != pawsLocation;
// }




// import 'dart:math';
// import 'dart:ui' as ui;
// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:maze_app/main_menu.dart';
// import 'package:maze_app/model/maze_cell.dart';
// import 'package:maze_app/model/maze_generator.dart';
// import 'package:maze_app/model/path_finder.dart';
//
// const mazePadding = 20.0;
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Maze App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MainMenu(),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   final String title;
//   final int mazeRows;
//   final int mazeColumns;
//   final bool hintEnabled;
//   bool mouseEnabled;
//   final Pair<int, int> playerPositionCell = Pair(0, 0);
//   final rand = Random();
//   late Pair<int, int> mousePositionCell;
//   late MazeGenerator mazeGenerator;
//   var hint = List<Pair<int, int>>.empty(growable: true);
//
//   MyHomePage({
//     super.key,
//     required this.title,
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.hintEnabled,
//     required this.mouseEnabled,
//   }) {
//     mazeGenerator = MazeGenerator(mazeColumns: mazeColumns, mazeRows: mazeRows);
//     mousePositionCell =
//         Pair(rand.nextInt(mazeRows - 1) + 1, rand.nextInt(mazeColumns - 1) + 1);
//   }
//
//   @override
//   State<StatefulWidget> createState() {
//     return MyHomePageState();
//   }
// }
//
// class MyHomePageState extends State<MyHomePage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _playerPulseController;
//   late ui.Image playerImage;
//   bool imageLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     widget.mazeGenerator.generate();
//     if (widget.mouseEnabled) {
//       widget.mazeGenerator.closeDoors();
//     } else {
//       widget.mazeGenerator.openDoors();
//     }
//
//     _playerPulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//       lowerBound: 0.8,
//       upperBound: 1.2,
//     )..repeat(reverse: true);
//
//     _loadPlayerImage();
//   }
//
//   void _loadPlayerImage() async {
//     playerImage = await loadImage('assets/cat.png');
//     setState(() {
//       imageLoaded = true;
//     });
//   }
//
//   Future<ui.Image> loadImage(String assetPath) async {
//     final data = await rootBundle.load(assetPath);
//     final bytes = data.buffer.asUint8List();
//     final codec = await ui.instantiateImageCodec(bytes);
//     final frame = await codec.getNextFrame();
//     return frame.image;
//   }
//
//   @override
//   void dispose() {
//     _playerPulseController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;
//     double height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.deepPurple,
//         title: Text(widget.title),
//         actions: [
//           if (widget.hintEnabled)
//             IconButton(
//               icon: const Icon(Icons.lightbulb_rounded),
//               onPressed: () {
//                 var fastestWayOut = findFastestWayOut(
//                     widget.mazeRows,
//                     widget.mazeColumns,
//                     widget.playerPositionCell,
//                     widget.mazeGenerator.mazeCells);
//                 setState(() {
//                   widget.hint = calculateHint(fastestWayOut.toList()).toList();
//                 });
//               },
//             ),
//           IconButton(
//             icon: const Icon(Icons.replay),
//             onPressed: () {
//               setState(() {
//                 widget.mazeGenerator.generate();
//                 widget.playerPositionCell.a = 0;
//                 widget.playerPositionCell.b = 0;
//                 widget.mousePositionCell = Pair(
//                     widget.rand.nextInt(widget.mazeRows - 1) + 1,
//                     widget.rand.nextInt(widget.mazeColumns - 1) + 1);
//               });
//               if (widget.mouseEnabled) {
//                 widget.mazeGenerator.closeDoors();
//               } else {
//                 widget.mazeGenerator.openDoors();
//               }
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.deepPurple, Colors.blueAccent],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: MazeGeasture(
//             moveLeft: _moveLeft,
//             moveUp: _moveUp,
//             moveRight: _moveRight,
//             moveDown: _moveDown,
//             child: Padding(
//               padding: const EdgeInsets.all(mazePadding),
//               child: Stack(
//                 children: [
//                   CustomPaint(
//                     painter: MazePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mazeCells:
//                           widget.mazeGenerator.mazeCells.cast<List<MazeCell>>(),
//                     ),
//                     size: Size(width, height),
//                   ),
//                   if (imageLoaded)
//                     AnimatedBuilder(
//                       animation: _playerPulseController,
//                       builder: (context, child) {
//                         return CustomPaint(
//                           painter: PlayerPainterStyled(
//                             mazeRows: widget.mazeRows,
//                             mazeColumns: widget.mazeColumns,
//                             playerPositionCell: widget.playerPositionCell,
//                             scale: _playerPulseController.value,
//                             playerImage: playerImage,
//                           ),
//                           size: Size(width, height),
//                         );
//                       },
//                     ),
//                   CustomPaint(
//                     painter: MousePainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       mousePositionCell: widget.mousePositionCell,
//                       isEnabled: widget.mouseEnabled,
//                     ),
//                     size: Size(width, height),
//                   ),
//                   CustomPaint(
//                     painter: PawsPainterStyled(
//                       mazeRows: widget.mazeRows,
//                       mazeColumns: widget.mazeColumns,
//                       pawsLocation: widget.hint.toList(),
//                     ),
//                     size: Size(width, height),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _moveLeft() => _movePlayer(-1, 0);
//   void _moveRight() => _movePlayer(1, 0);
//   void _moveUp() => _movePlayer(0, -1);
//   void _moveDown() => _movePlayer(0, 1);
//
//   void _movePlayer(int dx, int dy) {
//     setState(() {
//       int newA = widget.playerPositionCell.a + dx;
//       int newB = widget.playerPositionCell.b + dy;
//
//       final cell = widget.mazeGenerator.mazeCells[widget.playerPositionCell.a]
//           [widget.playerPositionCell.b];
//
//       bool canMove = false;
//       if (dx == -1 && cell.wallLeftOpened) canMove = true;
//       if (dx == 1 && cell.wallRightOpened) canMove = true;
//       if (dy == -1 && cell.wallUpOpened) canMove = true;
//       if (dy == 1 && cell.wallDownOpened) canMove = true;
//
//       if (canMove) {
//         widget.playerPositionCell.a = newA;
//         widget.playerPositionCell.b = newB;
//         widget.hint.clear();
//       }
//
//       if (widget.playerPositionCell.a == widget.mousePositionCell.a &&
//           widget.playerPositionCell.b == widget.mousePositionCell.b) {
//         widget.mouseEnabled = false;
//         widget.mazeGenerator.openDoors();
//       }
//
//       // End game
//       if (widget.playerPositionCell.b >= widget.mazeColumns) {
//         showDialog(
//             barrierDismissible: false,
//             context: context,
//             builder: (BuildContext context) => AlertDialog(
//                   title: const Text("Congratulations"),
//                   content: const Text("You saved the cat!"),
//                   actions: [
//                     ElevatedButton(
//                       child: const Text("Play again"),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pop(context);
//                       },
//                     ),
//                   ],
//                 ));
//       }
//     });
//   }
// }
//
// class MazeGeasture extends StatelessWidget {
//   const MazeGeasture({
//     super.key,
//     required this.child,
//     required this.moveLeft,
//     required this.moveUp,
//     required this.moveRight,
//     required this.moveDown,
//   });
//
//   final Widget child;
//   final Function() moveLeft;
//   final Function() moveUp;
//   final Function() moveRight;
//   final Function() moveDown;
//
//   @override
//   Widget build(BuildContext context) {
//     double initialX = 0;
//     double initialY = 0;
//     double distanceX = 0;
//     double distanceY = 0;
//
//     return SizedBox.expand(
//       child: GestureDetector(
//         onPanStart: (DragStartDetails details) {
//           initialX = details.globalPosition.dx;
//           initialY = details.globalPosition.dy;
//         },
//         onPanUpdate: (DragUpdateDetails details) {
//           distanceX = details.globalPosition.dx - initialX;
//           distanceY = details.globalPosition.dy - initialY;
//         },
//         onPanEnd: (DragEndDetails details) {
//           if (distanceX.abs() > distanceY.abs()) {
//             if (distanceX > 0) {
//               moveRight();
//             } else {
//               moveLeft();
//             }
//           } else {
//             if (distanceY > 0) {
//               moveDown();
//             } else {
//               moveUp();
//             }
//           }
//         },
//         child: child,
//       ),
//     );
//   }
// }
//
// /// -----------------
// /// Styled Painters
// /// -----------------
//
// class MazePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<List<MazeCell>> mazeCells;
//
//   MazePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mazeCells,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 3;
//
//     for (var i = 0; i < mazeRows; i++) {
//       for (var j = 0; j < mazeColumns; j++) {
//         MazeCell mazeCell = mazeCells[i][j];
//         final x = mazeCell.position.a * wallLength;
//         final y = mazeCell.position.b * wallLength;
//
//         if (!mazeCell.wallLeftOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x, y + wallLength), paint);
//         }
//         if (!mazeCell.wallUpOpened) {
//           canvas.drawLine(Offset(x, y), Offset(x + wallLength, y), paint);
//         }
//         if (!mazeCell.wallRightOpened) {
//           canvas.drawLine(
//               Offset(x + wallLength, y),
//               Offset(x + wallLength, y + wallLength),
//               paint);
//         }
//         if (!mazeCell.wallDownOpened) {
//           canvas.drawLine(Offset(x, y + wallLength),
//               Offset(x + wallLength, y + wallLength), paint);
//         }
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
//
// class PlayerPainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair playerPositionCell;
//   final double scale;
//   final ui.Image playerImage;
//
//   PlayerPainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.playerPositionCell,
//     required this.scale,
//     required this.playerImage,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//
//     double centerX = playerPositionCell.a * wallLength + wallLength / 2;
//     double centerY = playerPositionCell.b * wallLength + wallLength / 2;
//     double imageSize = wallLength * scale;
//
//     Rect dstRect = Rect.fromCenter(
//         center: Offset(centerX, centerY),
//         width: imageSize,
//         height: imageSize);
//
//     canvas.drawImageRect(
//         playerImage,
//         Rect.fromLTWH(
//             0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
//         dstRect,
//         Paint());
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class MousePainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final Pair<int, int> mousePositionCell;
//   final bool isEnabled;
//
//   MousePainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.mousePositionCell,
//     required this.isEnabled,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (!isEnabled) return;
//
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()..color = Colors.red;
//
//     double centerX = mousePositionCell.a * wallLength + wallLength / 2;
//     double centerY = mousePositionCell.b * wallLength + wallLength / 2;
//     double radius = wallLength / 3;
//
//     canvas.drawCircle(Offset(centerX, centerY), radius, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
// class PawsPainterStyled extends CustomPainter {
//   final int mazeRows;
//   final int mazeColumns;
//   final List<Pair<int, int>> pawsLocation;
//
//   PawsPainterStyled({
//     required this.mazeRows,
//     required this.mazeColumns,
//     required this.pawsLocation,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double wallLength = (size.width - mazePadding * 2) / mazeRows;
//     final paint = Paint()..color = Colors.orangeAccent;
//
//     for (var paw in pawsLocation) {
//       canvas.drawCircle(
//           Offset(paw.a * wallLength + wallLength / 2,
//               paw.b * wallLength + wallLength / 2),
//           wallLength / 6,
//           paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

