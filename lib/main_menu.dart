import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maze_app/model/difficulty.dart';
import 'animations.dart';
import 'main.dart'; // uključi svoj MyHomePage i Difficulty klase

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainMenu(),
  ));
}

class MousePaw {
  Offset position;
  double opacity;

  MousePaw(this.position) : opacity = 1.0;
}

class Snowflake {
  Offset position;
  double size;
  double speed;

  Snowflake(this.position, this.size, this.speed);
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  // Animacije
  late AnimationController pawController;
  late AnimationController catJumpController;
  late CurvedAnimation catJumpAnimation;
  late AnimationController mousePawController;
  late AnimationController snowController;

  final Random random = Random();
  final AudioPlayer audioPlayer = AudioPlayer();

  static const int pawCount = 40;
  late List<Offset> pawPositions;
  final List<MousePaw> mousePaws = [];
  final List<Snowflake> snowflakes = [];

  DateTime lastPawTime = DateTime.now();
  final int pawCooldownMs = 350;

  bool isCatHovered = false;
  bool _snowInitialized = false;

  @override
  void initState() {
    super.initState();

    pawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    catJumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    catJumpAnimation = CurvedAnimation(
      parent: catJumpController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    pawPositions = List.generate(pawCount, (index) {
      return Offset(
        random.nextDouble() * 0.9,
        random.nextDouble() * 0.9,
      );
    });

    mousePawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000),
    )..addListener(() {
        setState(() {
          for (int i = mousePaws.length - 1; i >= 0; i--) {
            mousePaws[i].opacity -= 0.0001;
            if (mousePaws[i].opacity <= 0) mousePaws.removeAt(i);
          }
        });
      });
    mousePawController.repeat();

    snowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000),
    )..addListener(() {
        setState(() {
          for (var flake in snowflakes) {
            flake.position =
                Offset(flake.position.dx, flake.position.dy + flake.speed);
            if (flake.position.dy > MediaQuery.of(context).size.height) {
              flake.position = Offset(
                  random.nextDouble() * MediaQuery.of(context).size.width, 0);
            }
          }
        });
      });
    snowController.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_snowInitialized) {
      final screenSize = MediaQuery.of(context).size;

      // Dinamički broj pahulja prema širini ekrana
      int snowCount = (screenSize.width / 10).clamp(30, 100).toInt();

      // Brzina snijega – sporija i fiksna
      double snowMinSpeed = 0.3;
      double snowMaxSpeed = 0.8;

      for (int i = 0; i < snowCount; i++) {
        snowflakes.add(
          Snowflake(
            Offset(random.nextDouble() * screenSize.width,
                random.nextDouble() * screenSize.height),
            4 + random.nextDouble() * 6,
            snowMinSpeed + random.nextDouble() * (snowMaxSpeed - snowMinSpeed),
          ),
        );
      }
      _snowInitialized = true;
    }
  }

  @override
  void dispose() {
    pawController.dispose();
    catJumpController.dispose();
    mousePawController.dispose();
    snowController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  void _jumpCat() async {
    audioPlayer.play(AssetSource('sounds/meow.wav')); // dodaj svoj zvuk
    await catJumpController.forward(from: 0.0);
    await catJumpController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Pozadina
          Container(color: const Color(0xFF3A4F75)),

          const AnimatedBackground(), // Šapice + Snijeg

          // Šapice po mišu
          ...mousePaws.map((paw) {
            return Positioned(
              top: paw.position.dy - 10,
              left: paw.position.dx - 10,
              child: Image.asset(
                "assets/paw.png",
                width: 20,
                height: 20,
                color: Colors.black.withOpacity(paw.opacity),
              ),
            );
          }).toList(),

          // Centralni UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => isCatHovered = true),
                  onExit: (_) => setState(() => isCatHovered = false),
                  child: GestureDetector(
                    onTap: _jumpCat,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow
                        if (isCatHovered)
                          Image.asset(
                            'assets/cat.png',
                            height: 180,
                            color: Colors.yellow.withOpacity(0.08),
                            colorBlendMode: BlendMode.modulate,
                          ),

                        // Mačka
                        AnimatedBuilder(
                          animation: catJumpAnimation,
                          builder: (context, child) {
                            final offsetY = -catJumpAnimation.value * 50;
                            final scale = 1.0 + (isCatHovered ? 0.05 : 0.0);
                            return Transform.translate(
                              offset: Offset(0, offsetY),
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            "assets/cat.png",
                            height: 180,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                HoverButton(
                  text: 'Easy',
                  color: Color(0xFF7EE47A),
                  width: 180,
                  height: 50,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(
                          title: 'Maze App',
                          mazeColumns:
                              getCellsForScreenSize(Difficulty.easy, screenSize)
                                  .a,
                          mazeRows:
                              getCellsForScreenSize(Difficulty.easy, screenSize)
                                  .b,
                          hintEnabled: true,
                          mouseEnabled: false,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                HoverButton(
                  text: 'Normal',
                  color: Color(0xFFFF9F4E),
                  width: 180,
                  height: 50,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(
                          title: 'Maze App',
                          mazeColumns: getCellsForScreenSize(
                                  Difficulty.normal, screenSize)
                              .a,
                          mazeRows: getCellsForScreenSize(
                                  Difficulty.normal, screenSize)
                              .b,
                          hintEnabled: true,
                          mouseEnabled: false,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                HoverButton(
                  text: 'Hard',
                  color: Color(0xFFE55050),
                  width: 180,
                  height: 50,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(
                          title: 'Maze App',
                          mazeColumns:
                              getCellsForScreenSize(Difficulty.hard, screenSize)
                                  .a,
                          mazeRows:
                              getCellsForScreenSize(Difficulty.hard, screenSize)
                                  .b,
                          hintEnabled: false,
                          mouseEnabled: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Hover dugme
class HoverButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const HoverButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
    this.width = 180,
    this.height = 50,
  });

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: isHovered ? widget.width + 20 : widget.width,
        height: isHovered ? widget.height + 10 : widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: isHovered ? 12 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Text(widget.text,
                style: GoogleFonts.dynaPuff(
                    fontSize: 20,
                    color: Color(0xFF3A4F75),
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
