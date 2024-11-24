import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import 'boardcell.dart';
import 'snapshot.dart';

class Stack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);
  void clear() => _list.clear();

  E pop() => _list.removeLast();

  E get peek => _list.last;

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  String toString() => _list.toString();
}

class Snapshots {
  final _snapshots = Stack<Snapshot>();

  void push(Snapshot snapshot) {
    _snapshots.push(snapshot);
  }

  void clear() {
    _snapshots.clear();
  } 

  Snapshot pop() { 
    return _snapshots.pop();
  }

  void saveGameState(
      int score, int highScore, int numberOfMoves, RxList<RxList<Rx<BoardCell>>> boardCells) {
    if (!isAnyCellEmpty(boardCells)) {
      return;
    }

    Snapshot snapshot = Snapshot();
    snapshot.saveGameState(score, highScore, numberOfMoves, boardCells); 
    push(snapshot);
  }

  Map<String, Object> revertState() {
    if (_snapshots.isEmpty) {
      return Snapshot().revertState();
    }
    var snapshot = pop(); 
    return snapshot.revertState();
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
}
 