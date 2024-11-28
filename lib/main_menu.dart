import 'package:flutter/material.dart';
import 'main.dart';
import 'model/difficulty.dart';

class MainMenu extends StatefulWidget {
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
                            mazeColumns: getCellsForDifficulty(setDifficulty).a,
                            mazeRows: getCellsForDifficulty(setDifficulty).b)));
              },
              child: Text('Start game'),
            ),
            SizedBox(height: 20), // Adds spacing between the buttons
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Action for Button 2
                    switchState();
                  },
                  child: Text('Difficulty'),
                ),
                Text(setDifficulty.name),
              ],
            )
          ],
        ),
      ),
    );
  }
}
