import 'package:flutter/material.dart';
import 'package:maze_app/model/difficulty.dart';
import 'main.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Difficulty setDifficulty = Difficulty.normal;

  void switchState() {
    setState(() {
      setDifficulty = Difficulty
          .values[(setDifficulty.index + 1) % Difficulty.values.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Menu'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Action for Button 1
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyHomePage(
                              title: 'Maze App',
                              mazeColumns:
                                  getCellsForDifficulty(Difficulty.easy).a,
                              mazeRows:
                                  getCellsForDifficulty(Difficulty.easy).b,
                              hintEnabled: true,
                            )));
              },
              child: Text('Easy'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Action for Button 1
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyHomePage(
                              title: 'Maze App',
                              mazeColumns:
                                  getCellsForDifficulty(Difficulty.normal).a,
                              mazeRows:
                                  getCellsForDifficulty(Difficulty.normal).b,
                              hintEnabled: true,
                            )));
              },
              child: Text('Normal'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Action for Button 1
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyHomePage(
                              title: 'Maze App',
                              mazeColumns:
                                  getCellsForDifficulty(Difficulty.hard).a,
                              mazeRows:
                                  getCellsForDifficulty(Difficulty.hard).b,
                              hintEnabled: false,
                            )));
              },
              child: Text('Hard'),
            ),
            SizedBox(height: 20), // Adds spacing between the buttons
          ],
        ),
      ),
    );
  }
}
