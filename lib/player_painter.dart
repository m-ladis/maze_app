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

class PlayerPainterNormal extends CustomPainter {
  final double width;
  final double height;
  final Pair playerPositionCell;
  final ui.Image playerIcon;

  PlayerPainterNormal(
      this.width, this.height, this.playerPositionCell, this.playerIcon);

  @override
  void paint(Canvas canvas, Size size) {
    double wallLength = (width - mazePadding * 2) / mazeRowsNormal;

    canvas.drawImage(
        playerIcon,
        Offset(playerPositionCell.a * wallLength,
            playerPositionCell.b * wallLength),
        Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PlayerPainterHard extends CustomPainter {
  final double width;
  final double height;
  final Pair playerPositionCell;
  final ui.Image playerIcon;

  PlayerPainterHard(
      this.width, this.height, this.playerPositionCell, this.playerIcon);

  @override
  void paint(Canvas canvas, Size size) {
    double wallLength = (width - mazePadding * 2) / mazeRowsHard;

    canvas.drawImage(
        playerIcon,
        Offset(playerPositionCell.a * wallLength,
            playerPositionCell.b * wallLength),
        Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}