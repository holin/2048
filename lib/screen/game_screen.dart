import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../controller/game_controller.dart';
import '../widgets/board_widget.dart';
import '../widgets/celebration_widget.dart';
import '../widgets/game_actionable_widget.dart';
import '../widgets/game_over_widget.dart';
import '../widgets/score_board_widget.dart';

class GameScreen extends GetView<GameController> {
  late ConfettiController _animationController;
  int lastKeyStrokeTime = 0;
  bool superUser = false;

  late Pazzle pazzle;

  GameScreen({Key? key}) : super(key: key) {
    _animationController =
        ConfettiController(duration: const Duration(seconds: 10));
    lastKeyStrokeTime = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    var commentWidgets = <Widget>[];
    if (controller.isGameWon.value == true) {
      print("is Game over? ${controller.isGameWon.value}");
      commentWidgets
          .add(CelebrationWidget(animationController: _animationController));
      _animationController.play();
    } else {
      commentWidgets.clear();
    }

    return KeyboardListener(
        autofocus: true,
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          handleKeyEvent(event);
        },
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const SizedBox(
                        height: 40,
                      ),
                      ScoreBoardWidget(),
                      const SizedBox(
                        height: 5,
                      ),
                      SwipeDetector(
                          onSwipe: (direction, offset) {
                            onSwipedDetected(direction);
                          },
                          child: GameBoardWidget(
                            tiles: controller.reactiveBoardCells,
                          )),
                      const SizedBox(height: 20),
                      Obx(() => (GameActionableWidget(
                            onUndoPressed: () {
                              if (superUser) {
                                controller.undo();
                                return;
                              }
                              _animationController.stop();
                              showAlertDialog(context);
                            },
                            onNewGamePressed: () {
                              _animationController.stop();
                              superUser = false;
                              controller.reset();
                            },
                            score: controller.score.value,
                            isGameOver: controller.isGameOver.value,
                          ))),
                    ],
                  ),
                  Obx(() => GameOverWidget(
                      shouldShow: controller.isGameOver.value,
                      callback: () {
                        controller.reset();
                      })),
                  ...commentWidgets
                ],
              ),
            )
          ],
        ));
  }

  checkAnswer(String value) {
    if (superUser) {
      controller.undo();
      Get.back();
      return;
    }

    if (int.parse(value) == 999) {
      superUser = true;
      Fluttertoast.showToast(
        msg: "进入超级模式！！",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(255, 29, 176, 51),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Get.back();
      return;
    }

    if (pazzle.check(int.parse(value))) {
      controller.undo();
      Get.back();
    } else {
      Fluttertoast.showToast(
        msg: "答案错误！",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(255, 255, 103, 92),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  showAlertDialog(BuildContext context) {
    var textFieldController = TextEditingController();
    Random random = new Random();
    pazzle = new Pazzle(random.nextInt(20) + 1, random.nextInt(20) + 2, 0);

    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("取消"),
      onPressed: () {
        Get.back();
      },
    );
    Widget continueButton = TextButton(
      child: const Text("确定"),
      onPressed: () {
        checkAnswer(textFieldController.text);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text(
        "请先回答对问题才能反悔一步 ^_^",
        style: TextStyle(
          fontSize: 14,
        ),
      ),
      content: Row(
        children: [
          Text(
            pazzle.x.toString(),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "+",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            pazzle.y.toString(),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "=",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: TextField(
              textAlign: TextAlign.center,
              controller: textFieldController,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true, signed: false),
              autofocus: true,
              decoration: InputDecoration(
                hintText: "答案是？",
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              onSubmitted: (value) {
                checkAnswer(value);
              },
            ),
          ),
        ],
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void onSwipedDetected(SwipeDirection direction) {
    controller.startTimer();
    switch (direction) {
      case SwipeDirection.up:
        controller.moveUp();
        break;
      case SwipeDirection.down:
        controller.moveDown();
        break;
      case SwipeDirection.left:
        controller.moveLeft();
        break;
      case SwipeDirection.right:
        controller.moveRight();
        break;
    }
  }

  void handleKeyEvent(KeyEvent _) {
    var currentKeyStrokeTime = DateTime.now().millisecondsSinceEpoch;
    if (currentKeyStrokeTime - lastKeyStrokeTime < 5) {
      lastKeyStrokeTime = currentKeyStrokeTime;
      return;
    }
    lastKeyStrokeTime = currentKeyStrokeTime;
    SwipeDirection? direction;
    if (HardwareKeyboard.instance
        .isPhysicalKeyPressed(PhysicalKeyboardKey.arrowUp)) {
      direction = SwipeDirection.up;
    } else if (HardwareKeyboard.instance
        .isPhysicalKeyPressed(PhysicalKeyboardKey.arrowDown)) {
      direction = SwipeDirection.down;
    } else if (HardwareKeyboard.instance
        .isPhysicalKeyPressed(PhysicalKeyboardKey.arrowLeft)) {
      direction = SwipeDirection.left;
    } else if (HardwareKeyboard.instance
        .isPhysicalKeyPressed(PhysicalKeyboardKey.arrowRight)) {
      direction = SwipeDirection.right;
    }
    if (direction != null) {
      onSwipedDetected(direction);
    }
  }
}

class Pazzle {
  int x = 0;
  int y = 0;
  int value = 0;

  Pazzle(this.x, this.y, this.value);

  bool check(int value) {
    return this.x + this.y == value;
  }
}
