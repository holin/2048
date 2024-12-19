import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardik_2048/widgets/tiles_widget.dart';

import '../model/boardcell.dart';
import '../utils/colorUtils.dart';

class GameBoardWidget extends StatelessWidget {
  RxList<RxList<Rx<BoardCell>>> tiles;

  GameBoardWidget({Key? key, required this.tiles}) : super(key: key);

  late MediaQueryData queryData;
  final double sideMargin = 16 * 2;

  @override
  Widget build(BuildContext context) {
    queryData = MediaQuery.of(context);
    double size = _getBoardSize(context) - sideMargin;
    final sizePerTile = (size / 5).floorToDouble();
    double marginBetweenTiles = sizePerTile / 5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0), color: boardBackground),
      child: SizedBox(
        child: Stack(
            children: [GridWidget(sizePerTile, marginBetweenTiles, tiles)]),
      ),
    );
  }

  double _getBoardSize(BuildContext context) {
    var minimumSide = min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    final size = max(300.0, min(minimumSide, 400.0));
    return size;
  }
}
