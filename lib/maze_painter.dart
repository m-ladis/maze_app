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

import 'main.dart';

class MazePainterNormal extends CustomPainter {
  final double width;
  final double height;
  final List<List<dynamic>> mazeCells;

  MazePainterNormal(this.width, this.height, this.mazeCells);

  @override
  void paint(Canvas canvas, Size size) {
    double wallLength = (width - mazePadding * 2) / mazeRowsNormal;

    for (var i = 0; i < mazeRowsNormal; i++) {
      for (var j = 0; j < mazeColumnsNormal; j++) {
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

class MazePainterHard extends CustomPainter {
  final double width;
  final double height;
  final List<List<dynamic>> mazeCells;

  MazePainterHard(this.width, this.height, this.mazeCells);

  @override
  void paint(Canvas canvas, Size size) {
    double wallLength = (width - mazePadding * 2) / mazeRowsNormal;

    for (var i = 0; i < mazeRowsHard; i++) {
      for (var j = 0; j < mazeColumnsHard; j++) {
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