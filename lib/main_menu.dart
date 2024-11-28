import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maze_app/difficulty.dart';
import 'package:maze_app/model/homepages.dart';
import 'package:maze_app/model/maze_cell.dart';
import 'package:maze_app/model/maze_generator.dart';
import 'package:maze_app/model/path_finder.dart';

import 'main.dart';

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Difficulty setDifficulty = Difficulty.normal;

  void switchState() {
    setState(() {
      setDifficulty = Difficulty.values[
        (setDifficulty.index + 1) % Difficulty.values.length
      ];
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
                  MaterialPageRoute(builder: (context) => MyHomePage(title: 'Maze App', difficulty: Difficulty.easy,))
                );
              },
              child: Text('Easy'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Action for Button 1
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePageNormal(title: 'Maze App', difficulty: Difficulty.easy,))
                );
              },
              child: Text('Normal'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Action for Button 1
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePageHard(title: 'Maze App', difficulty: Difficulty.easy,))
                );
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