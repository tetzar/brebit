import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class Confetti {
  late FrontConfettiWidget _confettiWidget;
  late ConfettiController _controller;

  Confetti() {
    _controller =
        ConfettiController(duration: Duration(seconds: DURATION_SECONDS));
    _confettiWidget = FrontConfettiWidget(
      controller: _controller,
    );
  }

  static const DURATION_SECONDS = 1;

  Widget getWidget() {
    return _confettiWidget;
  }

  void play() {
    _controller.play();
  }
}

class FrontConfettiWidget extends StatefulWidget {
  final ConfettiController controller;

  const FrontConfettiWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  _FrontConfettiWidgetState createState() => _FrontConfettiWidgetState();
}

class _FrontConfettiWidgetState extends State<FrontConfettiWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: widget.controller,
        emissionFrequency: 0.2,
        shouldLoop: false,
        blastDirectionality: BlastDirectionality.explosive,
        gravity: 0.2,
        maxBlastForce: 50.0,
        numberOfParticles: 10,
      ),
    );
  }
}
