import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Confetti {
  FrontConfettiWidget _confettiWidget;
  ConfettiController _controller;

  Confetti() {
    _controller =
        ConfettiController(duration: Duration(seconds: DURATION_SECONDS));
    _confettiWidget = FrontConfettiWidget(
      controller: _controller,
    );
  }

  static const DURATION_SECONDS = 3;

  Widget getWidget() {
    return _confettiWidget;
  }

  void play() {
    _controller.play();
  }
}

class FrontConfettiWidget extends StatefulWidget {
  final ConfettiController controller;

  const FrontConfettiWidget({Key key, @required this.controller})
      : super(key: key);

  @override
  _FrontConfettiWidgetState createState() => _FrontConfettiWidgetState();
}

class _FrontConfettiWidgetState extends State<FrontConfettiWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  height: 100,
                  child: ConfettiWidget(
                    confettiController: widget.controller,
                    shouldLoop: false,
                    blastDirection: (-pi * 3 / 8),
                    gravity: 0.1,
                    maxBlastForce: 100.0,
                    numberOfParticles: 15,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  height: 100,
                  child: ConfettiWidget(
                    confettiController: widget.controller,
                    shouldLoop: false,
                    blastDirection: (-5 * pi / 8),
                    gravity: 0.1,
                    maxBlastForce: 100.0,
                    numberOfParticles: 15,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
