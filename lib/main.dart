import 'dart:math';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maze_app/main_menu.dart';
import 'package:maze_app/model/maze_cell.dart';
import 'package:maze_app/model/maze_generator.dart';
import 'package:maze_app/model/path_finder.dart';
import 'package:confetti/confetti.dart';
import 'animations.dart';

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
  bool hintEnabled;
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

class MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late AnimationController _playerPulseController;
  late AnimationController _pawsController;
  late ui.Image playerImage;
  late ui.Image pawImage;
  late ui.Image bowlImage;
  late ui.Image yarnBallImage;
  bool imageLoaded = false;
  final AudioPlayer audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  }

  void _loadImages() async {
    bowlImage = await loadImage('assets/bowl.png');
    playerImage = await loadImage('assets/cat.png');
    pawImage = await loadImage('assets/paw.png');
    yarnBallImage = await loadImage('assets/yarn_ball.png');
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
    audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void startDrinkingMilk() async {
    audioPlayer.play(AssetSource('sounds/cat_drinking.mp3'));
  }

  @override
  Widget build(BuildContext context) {
//     final density = MediaQuery.of(context).devicePixelRatio;
//     double scale = (density / 2.5).clamp(0.6, 1.4);
    final height = MediaQuery.of(context).size.height;
    double scale = (height / 800).clamp(1.0, 1.5);

    final hintIcon = (widget.hintEnabled)
        ? const Icon(Icons.lightbulb_rounded, color: Colors.orange)
        : const Icon(Icons.lightbulb_outline, color: Colors.white);

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AppBar(
                iconTheme: const IconThemeData(
                  color: Colors.white,
                ),
                backgroundColor: const Color(0xFF3A4F75),
                elevation: 0,
                centerTitle: true,
                toolbarHeight: 70,
                // <— KLJUČNO: određuje stvarnu visinu AppBara

                title: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      // 🔥 OVO JE KLJUČ
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Row(children: [
                                  Image.asset('assets/cat.png', height: 47),
                                  const SizedBox(width: 10),
                                  Text("Cat Maze",
                                      style: GoogleFonts.rubikPuddles(
                                        fontSize: 33,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.1,
                                      ))
                                ]));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: hintIcon,
                    tooltip: "Show Hint",
                    onPressed: () {
                      var fastestWayOut = findFastestWayOut(
                        widget.mazeRows,
                        widget.mazeColumns,
                        widget.playerPositionCell,
                        widget.mazeGenerator.mazeCells,
                      );
                      setState(() {
                        if (widget.hintEnabled) {
                          widget.hintEnabled = false;
                          widget.hint =
                              calculateHint(fastestWayOut.toList()).toList();
                          _pawsController.forward(from: 0);
                        }
                      });
                    },
                  ),
                  IconButton(
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
                ],
              ),
            ),
          ),
        ),
        body: Container(
            color: const Color(0xFF3A4F75),
            child: Center(
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                autofocus: true,
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      _moveLeft();
                    } else if (event.logicalKey ==
                        LogicalKeyboardKey.arrowRight) {
                      _moveRight();
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      _moveUp();
                    } else if (event.logicalKey ==
                        LogicalKeyboardKey.arrowDown) {
                      _moveDown();
                    }
                  }
                },
                child: MazeGeasture(
                    moveLeft: _moveLeft,
                    moveUp: _moveUp,
                    moveRight: _moveRight,
                    moveDown: _moveDown,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double maxOutline =
                            30.0; // margin za pozadinu labirinta

                        // dostupna širina i visina za labirint
                        double availableWidth = constraints.maxWidth -
                            mazePadding * 2 -
                            maxOutline * 2;
                        double availableHeight = constraints.maxHeight -
                            mazePadding * 2 -
                            maxOutline * 8;

                        // izračun veličine ćelije tako da cijeli labirint stane unutar ekrana
                        double cellWidth = availableWidth / widget.mazeRows;
                        double cellHeight =
                            availableHeight / widget.mazeColumns;
                        double cellSize = min(cellWidth, cellHeight);

                        // dimenzije labirinta
                        double mazeWidth = widget.mazeRows * cellSize;
                        double mazeHeight = widget.mazeColumns * cellSize;

                        // centriranje labirinta
                        double offsetX = (constraints.maxWidth - mazeWidth) / 2;
                        double offsetY =
                            (constraints.maxHeight - mazeHeight) / 2 -
                                cellSize / 2;

                        return Stack(
                          children: [
                            const AnimatedBackground(), // Šapice + Snijeg
                            CustomPaint(
                              painter: MazePainterStyled(
                                  mazeRows: widget.mazeRows,
                                  mazeColumns: widget.mazeColumns,
                                  mazeCells: widget.mazeGenerator.mazeCells
                                      .cast<List<MazeCell>>(),
                                  cellSize: cellSize,
                                  offsetX: offsetX,
                                  offsetY: offsetY,
                                  bowlImage: bowlImage),
                              size: Size(
                                  constraints.maxWidth, constraints.maxHeight),
                            ),
                            if (imageLoaded)
                              AnimatedBuilder(
                                animation: _playerPulseController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: PlayerPainterStyled(
                                      mazeRows: widget.mazeRows,
                                      mazeColumns: widget.mazeColumns,
                                      playerPositionCell:
                                          widget.playerPositionCell,
                                      scale: _playerPulseController.value,
                                      playerImage: playerImage,
                                      cellSize: cellSize,
                                      offsetX: offsetX,
                                      offsetY: offsetY,
                                    ),
                                    size: Size(constraints.maxWidth,
                                        constraints.maxHeight),
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
                                  yarnBallImage: yarnBallImage),
                              size: Size(
                                  constraints.maxWidth, constraints.maxHeight),
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
                                    size: Size(constraints.maxWidth,
                                        constraints.maxHeight),
                                  );
                                },
                              ),

                              Align(
                                alignment: Alignment.topCenter,
                                child: ConfettiWidget(
                                  confettiController: _confettiController,
                                  blastDirectionality: BlastDirectionality.explosive,
                                  numberOfParticles: 30,
                                  emissionFrequency: 0.02,
                                  maxBlastForce: 16 * scale,
                                  minBlastForce: 6 * scale,
                                  gravity: 0.2 / scale,
                                  particleDrag: 0.03,
                                ),
                              ),

                          ],
                        );
                      },
                    )),
              ),
            )));
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
        _confettiController.play();
        startDrinkingMilk();
        Future.delayed(const Duration(seconds: 4), () {

            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => AlertDialog(
                backgroundColor: const Color(0xFFE7EEF8), // svijetla hladno-plava (usklađena s B8CAE6)
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Text(
                  "Congratulations",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A4F75), // tvoja tamno plava
                  ),
                ),
                content: const Text(
                  "You guided the cat to her milk — she’s purring with joy!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3A4F75), // isto tamno plava
                    fontWeight: FontWeight.w500,
                  ),
                ),

                actionsAlignment: MainAxisAlignment.center,

                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A4F75), // tvoja glavna tamno plava
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Play again",
                      style: GoogleFonts.dynaPuff(),
                    ),
                  ),
                ],
              ),
            );

          });
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

class MazePainterStyled extends CustomPainter {
  final int mazeRows;
  final int mazeColumns;
  final List<List<MazeCell>> mazeCells;
  final double cellSize;
  final double offsetX;
  final double offsetY;
  final ui.Image bowlImage;

  MazePainterStyled({
    required this.mazeRows,
    required this.mazeColumns,
    required this.mazeCells,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.bowlImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double mazeWidth = mazeRows * cellSize;
    final double mazeHeight = mazeColumns * cellSize;
    final double scaledCornerRadius = min(cellSize, 22);

    final Paint backgroundPaint = Paint()..color = const Color(0xffB8CAE6);
    final Paint outerRoundedCornerPaint = Paint()
      ..color = const Color(0xFFFFFEF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final Paint wallPaint = Paint()
      ..color = const Color(0xFFFFFEF2)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // POZADINSKA PLOČA
    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        offsetX - cellSize,
        offsetY - cellSize,
        mazeWidth + 2 * cellSize,
        mazeHeight + 3 * cellSize,
      ),
      Radius.circular(scaledCornerRadius),
    );
    canvas.drawRRect(backgroundRect, backgroundPaint);

    // ----------------------
// 2) VANJSKI OKVIR SA ZAOBLJENIM KUTOVIMA
// ----------------------
    final double left = offsetX;
    final double top = offsetY;
    final double right = offsetX + mazeWidth;
    final double bottom = offsetY + mazeHeight;

// GORNJI LIJEVI KUT
    canvas.drawArc(
      Rect.fromLTWH(left, top, scaledCornerRadius * 2, scaledCornerRadius * 2),
      pi, // startAngle
      pi / 2, // sweepAngle 90°
      false,
      outerRoundedCornerPaint,
    );

// GORNJA HORIZONTALNA STRANA
    canvas.drawLine(
      Offset(left + scaledCornerRadius, top),
      Offset(right - scaledCornerRadius, top),
      outerRoundedCornerPaint,
    );

// GORNJI DESNI KUT
    canvas.drawArc(
      Rect.fromLTWH(right - 2 * scaledCornerRadius, top, scaledCornerRadius * 2,
          scaledCornerRadius * 2),
      -pi / 2,
      pi / 2,
      false,
      outerRoundedCornerPaint,
    );

// DESNA VERTIKALNA STRANA
    canvas.drawLine(
      Offset(right, top + scaledCornerRadius),
      Offset(right, bottom - scaledCornerRadius),
      outerRoundedCornerPaint,
    );

// DONJI DESNI KUT
    canvas.drawArc(
      Rect.fromLTWH(
          right - 2 * scaledCornerRadius,
          bottom - 2 * scaledCornerRadius,
          scaledCornerRadius * 2,
          scaledCornerRadius * 2),
      0,
      pi / 2,
      false,
      Paint()..color = Colors.transparent,
    );

// DONJA HORIZONTALNA STRANA
    canvas.drawLine(
      Offset(right - 2 * scaledCornerRadius, bottom),
      Offset(left + scaledCornerRadius, bottom),
      outerRoundedCornerPaint,
    );

// DONJI LIJEVI KUT
    canvas.drawArc(
      Rect.fromLTWH(left, bottom - 2 * scaledCornerRadius,
          scaledCornerRadius * 2, scaledCornerRadius * 2),
      pi / 2,
      pi / 2,
      false,
      outerRoundedCornerPaint,
    );

// LIJEVA VERTIKALNA STRANA
    canvas.drawLine(
      Offset(left, bottom - scaledCornerRadius),
      Offset(left, top + scaledCornerRadius),
      outerRoundedCornerPaint,
    );

    // ZIDOVI LABIRINTA
    for (var i = 0; i < mazeRows; i++) {
      for (var j = 0; j < mazeColumns; j++) {
        MazeCell cell = mazeCells[i][j];
        final x = cell.position.a * cellSize + offsetX;
        final y = cell.position.b * cellSize + offsetY;

        if (i == 0 && j == 0 ||
            i == mazeRows - 1 && j == 0 ||
            i == 0 && j == mazeColumns - 1) continue;

        if (!cell.wallLeftOpened)
          canvas.drawLine(Offset(x, y), Offset(x, y + cellSize), wallPaint);
        if (!cell.wallUpOpened)
          canvas.drawLine(Offset(x, y), Offset(x + cellSize, y), wallPaint);
        if (!cell.wallRightOpened)
          canvas.drawLine(Offset(x + cellSize, y),
              Offset(x + cellSize, y + cellSize), wallPaint);
        if (!cell.wallDownOpened)
          canvas.drawLine(Offset(x, y + cellSize),
              Offset(x + cellSize, y + cellSize), wallPaint);
        if (i == mazeRows - 1 && j == mazeColumns - 1) {
          canvas.drawImageRect(
              bowlImage,
              Rect.fromLTWH(0, 0, bowlImage.width.toDouble(),
                  bowlImage.height.toDouble()),
              Rect.fromCenter(
                  center: Offset(x + cellSize / 2, y + 4 * cellSize / 2),
                  width: 3 * cellSize * 1,
                  height: 2 * cellSize * 1),
              Paint());
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
        center: Offset(centerX, centerY), width: imageSize, height: imageSize);

    canvas.drawImageRect(
        playerImage,
        Rect.fromLTWH(
            0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
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
  final ui.Image yarnBallImage;

  MousePainterStyled({
    required this.mazeRows,
    required this.mazeColumns,
    required this.mousePositionCell,
    required this.isEnabled,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.yarnBallImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isEnabled) return;

    double centerX = mousePositionCell.a * cellSize + cellSize / 2 + offsetX;
    double centerY = mousePositionCell.b * cellSize + cellSize / 2 + offsetY;

    canvas.drawImageRect(
        yarnBallImage,
        Rect.fromLTWH(0, 0, yarnBallImage.width.toDouble(),
            yarnBallImage.height.toDouble()),
        Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: cellSize * 0.75,
            height: cellSize * 0.65),
        Paint());
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
      double pawProgress =
          ((progress - pawStart) / (pawEnd - pawStart)).clamp(0.0, 1.0);

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
          Rect.fromLTWH(
              0, 0, pawImage.width.toDouble(), pawImage.height.toDouble()),
          Rect.fromCenter(
              center: const Offset(0, 0),
              width: pawImage.width.toDouble() * scale,
              height: pawImage.height.toDouble() * scale),
          Paint()
            ..colorFilter = const ColorFilter.mode(
              Color(0xFFFFFEF2),
              BlendMode.srcIn,
            ),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
