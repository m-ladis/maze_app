
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:maze_app/model/difficulty.dart';
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
            flake.position = Offset(flake.position.dx, flake.position.dy + flake.speed);
            if (flake.position.dy > MediaQuery.of(context).size.height) {
              flake.position = Offset(random.nextDouble() * MediaQuery.of(context).size.width, 0);
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
    await catJumpController.forward(from: 0.0);
    await catJumpController.reverse();
    // audioPlayer.play(AssetSource('sounds/meow.wav')); // dodaj svoj zvuk
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          final now = DateTime.now();
          if (now.difference(lastPawTime).inMilliseconds > pawCooldownMs) {
            setState(() {
              mousePaws.add(MousePaw(event.localPosition));
              if (mousePaws.length > 10) mousePaws.removeAt(0);
            });
            lastPawTime = now;
          }
        },
        child: Stack(
          children: [
            // Pozadina
            Container(color: const Color(0xFF3A4F75)),

            // Snijeg
            ...snowflakes.map((flake) {
              return Positioned(
                left: flake.position.dx,
                top: flake.position.dy,
                child: Container(
                  width: flake.size,
                  height: flake.size,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),

            // Animirane šapice
            AnimatedBuilder(
              animation: pawController,
              builder: (context, child) {
                // Broj šapica raste s ekranom, ali umjereno
                int dynamicPawCount = (screenSize.width / 30).clamp(40, 60).toInt();
                // Veličina šapica također umjereno raste
                double pawBaseSize = (screenSize.width / 40).clamp(34, 45);

                // Dodaj nove šapice ako ih nema dovoljno
                while (pawPositions.length < dynamicPawCount) {
                  pawPositions.add(
                    Offset(random.nextDouble() * 0.9, random.nextDouble() * 0.9),
                  );
                }

                return Stack(
                  children: List.generate(dynamicPawCount, (index) {
                    final anim = pawController.value;
                    final fade = (sin(anim * 2 * pi + index) + 1) / 2;

                    return Positioned(
                      top: pawPositions[index].dy * screenSize.height,
                      left: pawPositions[index].dx * screenSize.width,
                      child: Opacity(
                        opacity: fade * 0.7,
                        child: Transform.scale(
                          scale: 0.6 + fade * 0.4,
                          child: Transform.rotate(
                            angle: (index * 0.3) + anim * 0.3,
                            child: Image.asset(
                              "assets/paw.png",
                              width: pawBaseSize,
                              height: pawBaseSize,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),



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
                                                mazeColumns: getCellsForDifficulty(Difficulty.easy).a,
                                                mazeRows: getCellsForDifficulty(Difficulty.easy).b,
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
                                                mazeColumns: getCellsForDifficulty(Difficulty.normal).a,
                                                mazeRows: getCellsForDifficulty(Difficulty.normal).b,
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
                                                mazeColumns: getCellsForDifficulty(Difficulty.hard).a,
                                                mazeRows: getCellsForDifficulty(Difficulty.hard).b,
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
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}












//
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:maze_app/model/difficulty.dart';
// import 'main.dart';
//
// class MousePaw {
//   Offset position;
//   double opacity;
//   MousePaw(this.position) : opacity = 1.0;
// }
//
// class MainMenu extends StatefulWidget {
//   const MainMenu({super.key});
//
//   @override
//   _MainMenuState createState() => _MainMenuState();
// }
//
// class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
//   Difficulty setDifficulty = Difficulty.normal;
//
//   late AnimationController pawController;
//   late AnimationController catJumpController;
//   late CurvedAnimation catJumpAnimation;
//   late AnimationController mousePawController;
//
//   final Random random = Random();
//   final AudioPlayer audioPlayer = AudioPlayer();
//
//   static const int pawCount = 40;
//   late List<Offset> pawPositions;
//
//   final List<MousePaw> mousePaws = [];
//
//   DateTime lastPawTime = DateTime.now();
//   final int pawCooldownMs = 350; // max 1 šapica svaka 350 ms
//
//   bool isCatHovered = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     pawController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 5),
//     )..repeat(reverse: true);
//
//     catJumpController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     catJumpAnimation = CurvedAnimation(
//       parent: catJumpController,
//       curve: Curves.easeOut,
//       reverseCurve: Curves.easeIn,
//     );
//
//     pawPositions = List.generate(pawCount, (index) {
//       return Offset(
//         random.nextDouble() * 0.9,
//         random.nextDouble() * 0.9,
//       );
//     });
//
//     mousePawController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1000),
//     )..addListener(() {
//         setState(() {
//           for (int i = mousePaws.length - 1; i >= 0; i--) {
//             mousePaws[i].opacity -= 0.0001; // jako spor fade-out
//             if (mousePaws[i].opacity <= 0) mousePaws.removeAt(i);
//           }
//         });
//       });
//     mousePawController.repeat();
//   }
//
//   @override
//   void dispose() {
//     pawController.dispose();
//     catJumpController.dispose();
//     mousePawController.dispose();
//     audioPlayer.dispose();
//     super.dispose();
//   }
//
//   void _jumpCat() async {
//     await catJumpController.forward(from: 0.0);
//     await catJumpController.reverse();
//     audioPlayer.play(AssetSource('sounds/meow.wav'));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//
//     return Scaffold(
//       body: MouseRegion(
//         onHover: (event) {
//           final now = DateTime.now();
//           if (now.difference(lastPawTime).inMilliseconds > pawCooldownMs) {
//             setState(() {
//               mousePaws.add(MousePaw(event.localPosition));
//               if (mousePaws.length > 10) mousePaws.removeAt(0);
//             });
//             lastPawTime = now;
//           }
//         },
//         child: Stack(
//           children: [
//             // ★ Gradient pozadina
//             Container(
//               decoration: const BoxDecoration(
//               color: Color(0xFF3A4F75)
//
// //                 gradient: LinearGradient(
// //                   colors: [
// //                     Color(0xFFFFE2B8), // tamnija warm yellow
// //                     Color(0xFFFFB98A), // tamniji peach/orange
// //                   ],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                 ),
//               ),
//             ),
//
//             // ★ Animirane šapice u pozadini
//             AnimatedBuilder(
//               animation: pawController,
//               builder: (context, child) {
//                 return Stack(
//                   children: List.generate(pawPositions.length, (index) {
//                     final anim = pawController.value;
//                     final fade = (sin(anim * 2 * pi + index) + 1) / 2;
//
//                     return Positioned(
//                       top: pawPositions[index].dy * screenSize.height,
//                       left: pawPositions[index].dx * screenSize.width,
//                       child: Opacity(
//                         opacity: fade * 0.7,
//                         child: Transform.scale(
//                           scale: 0.6 + fade * 0.4,
//                           child: Transform.rotate(
//                             angle: (index * 0.3) + anim * 0.3,
//                             child: Image.asset(
//                               "assets/paw.png",
//                               width: 34,
//                               height: 34,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                 );
//               },
//             ),
//
//             // ★ Šapice po mišu sa fade-out
//             ...mousePaws.map((paw) {
//               return Positioned(
//                 top: paw.position.dy - 10,
//                 left: paw.position.dx - 10,
//                 child: Image.asset(
//                   "assets/paw.png",
//                   width: 20,
//                   height: 20,
//                   color: Colors.black.withOpacity(paw.opacity),
//
//                 ),
//               );
//             }).toList(),
//
//             // ★ Centralni UI
//             Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Mačka sa hover efektom i diskretnim glow po obliku slike
//                   MouseRegion(
//                     onEnter: (_) => setState(() => isCatHovered = true),
//                     onExit: (_) => setState(() => isCatHovered = false),
//                     child: GestureDetector(
//                       onTap: _jumpCat,
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           // Glow po obliku slike
//                           if (isCatHovered)
//                             Image.asset(
//                               'assets/cat.png',
//                               height: 180,
//                               color: Colors.yellow.withOpacity(0.08),
//                               colorBlendMode: BlendMode.modulate,
//                             ),
//                           // Originalna mačka
//                           AnimatedBuilder(
//                             animation: catJumpAnimation,
//                             builder: (context, child) {
//                               final offsetY =
//                                   -catJumpAnimation.value * 50;
//                               final scale = 1.0 + (isCatHovered ? 0.05 : 0.0);
//                               return Transform.translate(
//                                 offset: Offset(0, offsetY),
//                                 child: Transform.scale(
//                                   scale: scale,
//                                   child: child,
//                                 ),
//                               );
//                             },
//                             child: Image.asset(
//                               "assets/cat.png",
//                               height: 180,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 30),
//
//                   // Dugmad sa hover efektom
//                   HoverButton(
//                     text: 'Easy',
// //                     color: Colors.greenAccent,
//                     color: Color(0xFF7EE47A),
//                     width: 180,
//                     height: 50,
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => MyHomePage(
//                             title: 'Maze App',
//                             mazeColumns: getCellsForDifficulty(Difficulty.easy).a,
//                             mazeRows: getCellsForDifficulty(Difficulty.easy).b,
//                             hintEnabled: true,
//                             mouseEnabled: false,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//
//                   const SizedBox(height: 15),
//
//                   HoverButton(
//                     text: 'Normal',
// //                     color: Colors.orangeAccent,
//                     color: Color(0xFFFF9F4E),
//                     width: 180,
//                     height: 50,
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => MyHomePage(
//                             title: 'Maze App',
//                             mazeColumns: getCellsForDifficulty(Difficulty.normal).a,
//                             mazeRows: getCellsForDifficulty(Difficulty.normal).b,
//                             hintEnabled: true,
//                             mouseEnabled: false,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//
//                   const SizedBox(height: 15),
//
//                   HoverButton(
//                     text: 'Hard',
// //                     color: Colors.redAccent,
//                     color: Color(0xFFE55050),
//                     width: 180,
//                     height: 50,
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => MyHomePage(
//                             title: 'Maze App',
//                             mazeColumns: getCellsForDifficulty(Difficulty.hard).a,
//                             mazeRows: getCellsForDifficulty(Difficulty.hard).b,
//                             hintEnabled: false,
//                             mouseEnabled: true,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ★ Hover dugme widget
// class HoverButton extends StatefulWidget {
//   final String text;
//   final Color color;
//   final VoidCallback onPressed;
//   final double width;
//   final double height;
//
//   const HoverButton({
//     super.key,
//     required this.text,
//     required this.color,
//     required this.onPressed,
//     this.width = 180,
//     this.height = 50,
//   });
//
//   @override
//   _HoverButtonState createState() => _HoverButtonState();
// }
//
// class _HoverButtonState extends State<HoverButton> {
//   bool isHovered = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => isHovered = true),
//       onExit: (_) => setState(() => isHovered = false),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeOut,
//         width: isHovered ? widget.width + 20 : widget.width,
//         height: isHovered ? widget.height + 10 : widget.height,
//         decoration: BoxDecoration(
//           color: widget.color,
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black26,
//               blurRadius: isHovered ? 12 : 5,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: InkWell(
//           onTap: widget.onPressed,
//           borderRadius: BorderRadius.circular(30),
//           child: Center(
//             child: Text(
//               widget.text,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



















//
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:maze_app/model/difficulty.dart';
// import 'main.dart';
//
// class MainMenu extends StatefulWidget {
//   const MainMenu({super.key});
//
//   @override
//   _MainMenuState createState() => _MainMenuState();
// }
//
// class _MainMenuState extends State<MainMenu>
//     with SingleTickerProviderStateMixin {
//   Difficulty setDifficulty = Difficulty.normal;
//
//   late AnimationController pawController;
//   final Random random = Random();
//
//   // povećano broj šapica
//   static const int pawCount = 40;
//
//   late List<Offset> pawPositions;
//
//   @override
//   void initState() {
//     super.initState();
//
//     pawController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 5), // mrvicu brže od prije
//     )..repeat(reverse: true);
//
//     pawPositions = List.generate(pawCount, (index) {
//       return Offset(
//         random.nextDouble() * 0.9,
//         random.nextDouble() * 0.9,
//       );
//     });
//   }
//
//   @override
//   void dispose() {
//     pawController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//
//     final buttonStyle = ElevatedButton.styleFrom(
//       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//       textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//       elevation: 5,
//     );
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           // ★ GRADIENT POZADINA
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.purple, Colors.blueAccent],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//
//           // ★ ANIMIRANE ŠAPICE (40 komada)
//           AnimatedBuilder(
//             animation: pawController,
//             builder: (context, child) {
//               return Stack(
//                 children: List.generate(pawPositions.length, (index) {
//                   final anim = pawController.value;
//                   final fade = (sin(anim * 2 * pi + index) + 1) / 2;
//
//                   return Positioned(
//                     top: pawPositions[index].dy * screenSize.height,
//                     left: pawPositions[index].dx * screenSize.width,
//                     child: Opacity(
//                       opacity: fade * 0.7,
//                       child: Transform.scale(
//                         scale: 0.6 + fade * 0.4,
//                         child: Transform.rotate(
//                           angle: (index * 0.3) + anim * 0.3,
//                           child: Image.asset(
//                             "assets/paw.png",
//                             width: 34,
//                             height: 34,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }),
//               );
//             },
//           ),
//
//           // ★ CENTRALNI UI (mačka + level gumbi)
//           Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // MACKA
//                 Image.asset(
//                   "assets/cat.png",
//                   height: 180,
//                 ),
//
//                 const SizedBox(height: 40),
//
//                 // EASY
//                 ElevatedButton(
//                   style: buttonStyle.copyWith(
//                     backgroundColor:
//                         MaterialStateProperty.all(Colors.greenAccent),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => MyHomePage(
//                           title: 'Maze App',
//                           mazeColumns:
//                               getCellsForDifficulty(Difficulty.easy).a,
//                           mazeRows:
//                               getCellsForDifficulty(Difficulty.easy).b,
//                           hintEnabled: true,
//                           mouseEnabled: false,
//                         ),
//                       ),
//                     );
//                   },
//                   child: const Text('Easy'),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // NORMAL
//                 ElevatedButton(
//                   style: buttonStyle.copyWith(
//                     backgroundColor:
//                         MaterialStateProperty.all(Colors.orangeAccent),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => MyHomePage(
//                           title: 'Maze App',
//                           mazeColumns:
//                               getCellsForDifficulty(Difficulty.normal).a,
//                           mazeRows:
//                               getCellsForDifficulty(Difficulty.normal).b,
//                           hintEnabled: true,
//                           mouseEnabled: false,
//                         ),
//                       ),
//                     );
//                   },
//                   child: const Text('Normal'),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // HARD
//                 ElevatedButton(
//                   style: buttonStyle.copyWith(
//                     backgroundColor:
//                         MaterialStateProperty.all(Colors.redAccent),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => MyHomePage(
//                           title: 'Maze App',
//                           mazeColumns:
//                               getCellsForDifficulty(Difficulty.hard).a,
//                           mazeRows:
//                               getCellsForDifficulty(Difficulty.hard).b,
//                           hintEnabled: false,
//                           mouseEnabled: true,
//                         ),
//                       ),
//                     );
//                   },
//                   child: const Text('Hard'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







//
// import 'package:flutter/material.dart';
// import 'package:maze_app/model/difficulty.dart';
// import 'main.dart';
//
// class MainMenu extends StatefulWidget {
//   const MainMenu({super.key});
//
//   @override
//   _MainMenuState createState() => _MainMenuState();
// }
//
// class _MainMenuState extends State<MainMenu> {
//   Difficulty setDifficulty = Difficulty.normal;
//
//   void switchState() {
//     setState(() {
//       setDifficulty = Difficulty
//           .values[(setDifficulty.index + 1) % Difficulty.values.length];
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final buttonStyle = ElevatedButton.styleFrom(
//       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//       textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//       elevation: 5,
//     );
//
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.purple, Colors.blueAccent],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Maze App',
//               style: TextStyle(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                   shadows: [
//                     Shadow(
//                         offset: Offset(2, 2),
//                         blurRadius: 4,
//                         color: Colors.black26)
//                   ]),
//             ),
//             const SizedBox(height: 60),
//             ElevatedButton(
//               style: buttonStyle.copyWith(
//                   backgroundColor:
//                       MaterialStateProperty.all(Colors.greenAccent)),
//               onPressed: () {
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => MyHomePage(
//                               title: 'Maze App',
//                               mazeColumns:
//                                   getCellsForDifficulty(Difficulty.easy).a,
//                               mazeRows:
//                                   getCellsForDifficulty(Difficulty.easy).b,
//                               hintEnabled: true,
//                               mouseEnabled: false,
//                             )));
//               },
//               child: const Text('Easy'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               style: buttonStyle.copyWith(
//                   backgroundColor:
//                       MaterialStateProperty.all(Colors.orangeAccent)),
//               onPressed: () {
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => MyHomePage(
//                               title: 'Maze App',
//                               mazeColumns:
//                                   getCellsForDifficulty(Difficulty.normal).a,
//                               mazeRows:
//                                   getCellsForDifficulty(Difficulty.normal).b,
//                               hintEnabled: true,
//                               mouseEnabled: false,
//                             )));
//               },
//               child: const Text('Normal'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               style: buttonStyle.copyWith(
//                   backgroundColor:
//                       MaterialStateProperty.all(Colors.redAccent)),
//               onPressed: () {
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => MyHomePage(
//                               title: 'Maze App',
//                               mazeColumns:
//                                   getCellsForDifficulty(Difficulty.hard).a,
//                               mazeRows:
//                                   getCellsForDifficulty(Difficulty.hard).b,
//                               hintEnabled: false,
//                               mouseEnabled: true,
//                             )));
//               },
//               child: const Text('Hard'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

