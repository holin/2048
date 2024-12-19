import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:hardik_2048/model/snapshots.dart';
import 'package:hardik_2048/model/snapshot.dart';

import '../model/boardcell.dart';
import '../storage/data_manager.dart';

class GameController extends GetxController {
  final int row = 4;
  final int column = 4;
  var score = 0.obs;
  var highScore = 0.obs;
  var numberOfMoves = 0.obs;
  var isGameOver = false.obs;
  var isGameWon = false.obs;

  late DataManager dataManager;
  late Snapshots snapshots;
  final reactiveBoardCells = <RxList<Rx<BoardCell>>>[].obs;
  final list = <Rx<BoardCell>>[].obs;

  static const String _defaultInitialTimerValue = '0';
  late Timer _timerObj;
  RxString timer = _defaultInitialTimerValue.obs;
  bool _hasTimerStarted = false;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  void init() async {
    isGameWon.value = isGameOver.value = false;
    score.value = 0;
    numberOfMoves.value = 0;
    timer.value = '0';

    snapshots = Snapshots();
    _initialiseBoard();
    _resetMergeStatus();
    await _initialiseDataManager();
  }

  void refresh() async {
    isGameWon.value = isGameOver.value = false;
    score.value = 0;
    numberOfMoves.value = 0;
    timer.value = '0';

    snapshots = Snapshots();
    _initialiseBoard();
    _resetMergeStatus();
    _randomEmptyCell(2);
    _saveSnapShot();
  }

  void _saveSnapShot() {
    snapshots.saveGameState(
      score.value,
      highScore.value,
      numberOfMoves.value,
      reactiveBoardCells,
    );

    print("snapshots.toString() ${snapshots.toString()}");

    dataManager.setValue(StorageKeys.snapshots, snapshots.toString());
  }

  void _incrementNumberOfMoves() {
    numberOfMoves.value++;
  }

  void moveLeft() {
    if (!canMoveLeft()) {
      return;
    }
    _incrementNumberOfMoves();
    for (int r = 0; r < row; ++r) {
      for (int c = 0; c < column; ++c) {
        mergeLeft(r, c);
      }
    }
    _resetMergeStatus();
    _randomEmptyCell(1);
    _saveSnapShot();
  }

  void moveRight() {
    if (!canMoveRight()) {
      return;
    }
    _incrementNumberOfMoves();
    for (int r = 0; r < row; ++r) {
      for (int c = column - 2; c >= 0; --c) {
        mergeRight(r, c);
      }
    }
    _resetMergeStatus();
    _randomEmptyCell(1);
    _saveSnapShot();
  }

  void moveUp() {
    if (!canMoveUp()) {
      return;
    }
    _incrementNumberOfMoves();
    for (int r = 0; r < row; ++r) {
      for (int c = 0; c < column; ++c) {
        mergeUp(r, c);
      }
    }
    _resetMergeStatus();
    _randomEmptyCell(1);
    _saveSnapShot();
  }

  void moveDown() {
    if (!canMoveDown()) {
      return;
    }
    _incrementNumberOfMoves();
    for (int r = row - 2; r >= 0; --r) {
      for (int c = 0; c < column; ++c) {
        mergeDown(r, c);
      }
    }
    _resetMergeStatus();
    _randomEmptyCell(1);
    _saveSnapShot();
  }

  bool canMoveLeft() {
    for (int r = 0; r < row; ++r) {
      for (int c = 1; c < column; ++c) {
        if (canMerge(reactiveBoardCells[r][c], reactiveBoardCells[r][c - 1])) {
          return true;
        }
      }
    }
    return false;
  }

  bool canMoveRight() {
    for (int r = 0; r < row; ++r) {
      for (int c = column - 2; c >= 0; --c) {
        if (canMerge(reactiveBoardCells[r][c], reactiveBoardCells[r][c + 1])) {
          return true;
        }
      }
    }
    return false;
  }

  bool canMoveUp() {
    for (int r = 1; r < row; ++r) {
      for (int c = 0; c < column; ++c) {
        if (canMerge(reactiveBoardCells[r][c], reactiveBoardCells[r - 1][c])) {
          return true;
        }
      }
    }
    return false;
  }

  bool canMoveDown() {
    for (int r = row - 2; r >= 0; --r) {
      for (int c = 0; c < column; ++c) {
        if (canMerge(reactiveBoardCells[r][c], reactiveBoardCells[r + 1][c])) {
          return true;
        }
      }
    }
    return false;
  }

  void mergeLeft(int r, int c) {
    while (c > 0) {
      merge(reactiveBoardCells[r][c], reactiveBoardCells[r][c - 1]);
      reactiveBoardCells.refresh();
      c--;
    }
  }

  void mergeRight(int r, int c) {
    while (c < column - 1) {
      merge(reactiveBoardCells[r][c], reactiveBoardCells[r][c + 1]);
      reactiveBoardCells.refresh();
      c++;
    }
  }

  void mergeUp(int r, int c) {
    while (r > 0) {
      merge(reactiveBoardCells[r][c], reactiveBoardCells[r - 1][c]);
      reactiveBoardCells.refresh();
      r--;
    }
  }

  void mergeDown(int r, int c) {
    while (r < row - 1) {
      //merge(boardCells[r][c], boardCells[r + 1][c]);
      merge(reactiveBoardCells[r][c], reactiveBoardCells[r + 1][c]);
      reactiveBoardCells.refresh();
      r++;
    }
  }

  bool canMerge(Rx<BoardCell> itemA, Rx<BoardCell> itemB) {
    var a = itemA.value;
    var b = itemB.value;
    return !b.isMerged &&
        ((b.isEmpty() && !a.isEmpty()) || (!a.isEmpty() && a == b));
  }

  void merge(Rx<BoardCell> itemA, Rx<BoardCell> itemB) {
    var a = itemA.value;
    var b = itemB.value;

    if (!canMerge(itemA, itemB)) {
      if (!a.isEmpty() && !b.isMerged) {
        b.isMerged = true;
      }
      return;
    }
    if (b.isEmpty()) {
      b.number = a.number;
      a.number = 0;
    } else if (a == b) {
      b.number = b.number * 2;
      b.isMerged = true;
      a.number = 0;
      score.value += b.number;
      score.refresh();
      b.isMerged = true;
    } else {
      b.isMerged = true;
    }
    setHighScore();
    _checkIfGameWon(b.number);
  }

  void checkIfIsGameOver() {
    var left = canMoveLeft();
    var right = canMoveRight();
    var top = canMoveUp();
    var down = canMoveDown();
    isGameOver.value = (left || right || top || down) == false;
    isGameOver.refresh();
    print("is game over? ${isGameOver.value}");
  }

  void _randomEmptyCell(int cnt) {
    List<BoardCell> emptyCells = <BoardCell>[];

    for (var element in reactiveBoardCells) {
      var ans = element.value.where((element) => element.value.isEmpty());
      emptyCells.addAll(ans.map((e) => e.value));
    }
    if (emptyCells.isEmpty) {
      checkIfIsGameOver();
      return;
    }

    Random r = Random();
    for (int i = 0; i < cnt && emptyCells.isNotEmpty; i++) {
      int index = r.nextInt(emptyCells.length);
      emptyCells[index].number = randomCellNum();
      emptyCells[index].isNew = true;
      emptyCells[index].isMerged = false;
    }
    for (var element in emptyCells) {
      reactiveBoardCells[element.row][element.column].update((val) {
        val?.row = element.row;
        val?.column = element.column;
        val?.number = element.number;
        val?.isNew = element.isNew;
      });
    }
    checkIfIsGameOver();
  }

  int randomCellNum() {
    final Random r = Random();
    return r.nextInt(15) == 0 ? 4 : 2;
  }

  void _resetMergeStatus() {
    for (var cells in reactiveBoardCells) {
      for (var cell in cells) {
        cell.update((val) {
          val?.isMerged = false;
        });
      }
    }
  }

  void reset() {
    reactiveBoardCells.clear();
    _resetMergeStatus();
    score.value = 0;
    resetTimer();
    refresh();
  }

  void renderWithState(Map<String, Object> state) {
    score.value = state[SnapshotKeys.SCORE] as int;
    highScore.value = state[SnapshotKeys.HIGH_SCORE] as int;
    numberOfMoves.value = state[SnapshotKeys.NUMBER_OF_MOVES] as int;
    isGameOver.value = false;
    isGameWon.value = false;
    var cells = state[SnapshotKeys.BOARD];
    if (cells != null && cells is List<List<BoardCell>> && cells.isNotEmpty) {
      reactiveBoardCells.clear();
      for (int r = 0; r < row; r++) {
        reactiveBoardCells.add(<Rx<BoardCell>>[].obs);
        for (int c = 0; c < column; c++) {
          var cell = BoardCell(
            row: r,
            column: c,
            number: cells[r][c].number,
            isNew: cells[r][c].isNew,
          );
          reactiveBoardCells[r].add(cell.obs);
          reactiveBoardCells.refresh();
        }
      }
    }
  }

  void undo() {
    print("undo step!!");
    var previousState = snapshots.revertState();
    var cells = previousState[SnapshotKeys.BOARD];
    debugger();
    if (snapshots.length > 0 &&
        cells != null &&
        cells is List<List<BoardCell>> &&
        cells.isNotEmpty) {
      renderWithState(previousState);
      _saveSnapShot();
    } else {
      print("No more undo steps!");
    }
  }

  Future<void> _initialiseDataManager() async {
    dataManager = DataManager();
    var result = await dataManager.getValue(StorageKeys.highScore); // as int;
    if (result != null) {
      highScore.value = int.parse(result);
    }

    var savedSnapshotsJson = await dataManager.getValue(StorageKeys.snapshots);
    var savedSnapshots = jsonDecode(savedSnapshotsJson);
    if (savedSnapshots != null && (savedSnapshots is List)) {
      for (var i = savedSnapshots.length - 1; i >= 0; i--) {
        var _snapshot = savedSnapshots[i];

        snapshots.saveGameState(
          _snapshot['score'],
          _snapshot['high_score'],
          _snapshot['number_of_moves'],
          boardCellsFromJson(_snapshot['board']),
        );
      }

      renderWithState(snapshots.first.revertState());
    } else {
      _randomEmptyCell(2);
      _saveSnapShot();
    }
  }

  RxList<RxList<Rx<BoardCell>>> boardCellsFromJson(String json) {
    print("boardCells json $json");
    var boardCells = jsonDecode(json);
    var cells = <RxList<Rx<BoardCell>>>[];
    for (int r = 0; r < row; r++) {
      cells.add(<Rx<BoardCell>>[].obs);
      for (int c = 0; c < column; c++) {
        var cell = BoardCell(
          row: r,
          column: c,
          number: boardCells[r][c]['number'],
          isNew: boardCells[r][c]['isNew'],
        );
        cells[r].add(cell.obs);
      }
    }

    return cells.obs;
  }

  void setHighScore() {
    if (score.value > highScore.value) {
      highScore.value = score.value;
      highScore.refresh();
      dataManager.setValue(StorageKeys.highScore, highScore.toString());
    }
  }

  void _initialiseBoard() {
    for (int r = 0; r < row; r++) {
      reactiveBoardCells.add(<Rx<BoardCell>>[].obs);
      for (int c = 0; c < column; c++) {
        var cell = BoardCell(
          row: r,
          column: c,
          number: 0,
          isNew: false,
        );
        reactiveBoardCells[r].add(cell.obs);
        reactiveBoardCells.refresh();
      }
    }
  }

  void _checkIfGameWon(int number) {
    isGameWon.value = number == 16;
  }

  String getScore() {
    return score.toString();
  }

  void startTimer() {
    if (timer.value == _defaultInitialTimerValue && !_hasTimerStarted) {
      _hasTimerStarted = true;
      print(
          ' startTimer() startTimer()startTimer() startTimer()  startTimer()');
      _timerObj = Timer.periodic(const Duration(seconds: 1), (_) {
        timer.value = (int.parse(timer.value) + 1).toString();
      });
    }
  }

  void stopTimer() {
    _timerObj.cancel();
  }

  void resetTimer() {
    if (_hasTimerStarted) {
      stopTimer();
      timer.value = _defaultInitialTimerValue;
      _hasTimerStarted = false;
    }
  }
}
