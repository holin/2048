import 'dart:convert';

import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import 'boardcell.dart';

class Snapshot {
  int _score = 0;
  int _highScore = 0;
  int _numberOfMoves = 0;
  var cells = <List<BoardCell>>[];

  @override
  String toString() {
    return jsonEncode({
      SnapshotKeys.SCORE: _score,
      SnapshotKeys.HIGH_SCORE: _highScore,
      SnapshotKeys.BOARD:
          "[${cells.map((cell) => jsonEncode(cell)).join(",")}]",
      SnapshotKeys.NUMBER_OF_MOVES: _numberOfMoves
    });
  }

  void saveGameState(int score, int highScore, int numberOfMoves,
      RxList<RxList<Rx<BoardCell>>> boardCells) {
    if (!isAnyCellEmpty(boardCells)) {
      return;
    }
    _score = score;
    _highScore = highScore;
    _numberOfMoves = numberOfMoves;
    storeList(boardCells);
  }

  Map<String, Object> revertState() {
    var result = {
      SnapshotKeys.SCORE: _score,
      SnapshotKeys.HIGH_SCORE: _highScore,
      SnapshotKeys.BOARD: cells,
      SnapshotKeys.NUMBER_OF_MOVES: _numberOfMoves
    };
    _printMe();
    return result;
  }

  void storeList(RxList<RxList<Rx<BoardCell>>> boardCells) {
    clearList();

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        cells[r][c].number = boardCells[r][c].value.number;
      }
    }
    _printMe();
  }

  bool isAnyCellEmpty(RxList<RxList<Rx<BoardCell>>> boardCells) {
    List<BoardCell> emptyCells = <BoardCell>[];

    for (var element in boardCells) {
      for (var element in element) {
        if (element.value.isEmpty()) {
          emptyCells.add(element.value);
          return true;
        }
      }
    }

    return false;
  }

  void clearList() {
    cells = List.generate(
        4,
        (row) => List.generate(
            4,
            (column) =>
                BoardCell(row: row, column: column, number: 0, isNew: false)));
  }

  void _printMe() {
    _printBoard(cells);
  }

  void _printBoard(List<List<BoardCell>> boardCells) {
    try {
      print("### _printBoard snapshot ------------");
      print(
          "${cells[0][0].number} ${cells[0][1].number} ${cells[0][2].number} ${cells[0][3].number}");
      print(
          "${cells[1][0].number} ${cells[1][1].number} ${cells[1][2].number} ${cells[1][3].number}");
      print(
          "${cells[2][0].number} ${cells[2][1].number} ${cells[2][2].number} ${cells[2][3].number}");
      print(
          "${cells[3][0].number} ${cells[3][1].number} ${cells[3][2].number} ${cells[3][3].number}");
      print("### end snapshot ------------");
      print("");
    } catch (e) {
      print(e);
    }
  }
}

class SnapshotKeys {
  static String SCORE = "score";
  static String HIGH_SCORE = "high_score";
  static String BOARD = "board";
  static String NUMBER_OF_MOVES = "number_of_moves";
}
