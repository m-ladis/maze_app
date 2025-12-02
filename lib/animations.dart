import 'dart:math';
import 'package:flutter/material.dart';

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

class AnimatedBackground extends StatefulWidget {
  final int pawCount;
  final int? snowCount;

  const AnimatedBackground({super.key, this.pawCount = 40, this.snowCount});

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  final Random random = Random();

  // Šapice
  late AnimationController pawController;
  late List<Offset> pawPositions;

  // Snijeg
  late AnimationController snowController;
  final List<Snowflake> snowflakes = [];
  bool _snowInitialized = false;

  @override
  void initState() {
    super.initState();

    // Šapice
    pawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    pawPositions = List.generate(widget.pawCount, (index) {
      return Offset(random.nextDouble() * 0.9, random.nextDouble() * 0.9);
    });

    // Snijeg
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
      int count =
          widget.snowCount ?? (screenSize.width / 10).clamp(30, 100).toInt();

      for (int i = 0; i < count; i++) {
        snowflakes.add(Snowflake(
          Offset(random.nextDouble() * screenSize.width,
              random.nextDouble() * screenSize.height),
          4 + random.nextDouble() * 6,
          0.3 + random.nextDouble() * 0.5,
        ));
      }

      _snowInitialized = true;
    }
  }

  @override
  void dispose() {
    pawController.dispose();
    snowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double pawBaseSize = (screenSize.width / 40).clamp(34, 45);

    return Stack(
      children: [
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

        // Šapice
        AnimatedBuilder(
          animation: pawController,
          builder: (context, child) {
            return Stack(
              children: List.generate(widget.pawCount, (index) {
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
                          color: const Color.fromRGBO(238, 178, 109, 0.7),
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
      ],
    );
  }
}
