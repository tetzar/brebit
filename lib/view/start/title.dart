import 'dart:math';

import 'package:flutter/material.dart';

class Title extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TitleAnimate(),
    );
  }
}

class TitleAnimate extends StatefulWidget {
  @override
  _TitleAnimateState createState() => _TitleAnimateState();
}

class _TitleAnimateState extends State<TitleAnimate>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _curve;

  double _painterMaxDeg = 0.23176;

  bool _showText = false;

  void startAnimation() {
    _animationController.reset();
    _animationController.forward();
    _curve.addListener(() {
      if (_curve.isCompleted) {
        setState(() {
          _showText = true;
        });
      }
    });
  }

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));
    _curve = CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutQuint);
    startAnimation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          Positioned(
            bottom: 60,
            width: MediaQuery.of(context).size.width,
            child: Container(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                    onTap: () async {
                      await Navigator.pushNamed(context, '/register');
                      startAnimation();
                    },
                    child: Container(
                        width: 300,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '新規登録',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        )),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: InkWell(
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                      onTap: () async {
                        await Navigator.pushNamed(context, '/login');
                        startAnimation();
                      },
                      child: Container(
                          width: 300,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(28)),
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ログイン',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                            ),
                          )),
                    ),
                  )
                ],
              ),
            ),
          ),
          AnimatedBuilder(
              animation: _curve,
              builder: (BuildContext context, child) {
                double _painterHeight = MediaQuery.of(context).size.height *
                        (1 - _curve.value / 2) +
                    MediaQuery.of(context).size.width *
                        atan(_curve.value * _painterMaxDeg) /
                        2;
                return Container(
                  height: _painterHeight,
                  width: MediaQuery.of(context).size.width,
                  child: CustomPaint(
                    size: Size(double.infinity, _painterHeight),
                    painter: TitlePainter(
                        position: _curve.value,
                        backGroundColor:
                            Theme.of(context).colorScheme.secondary,
                        maxDeg: _painterMaxDeg,
                        shadowColor: Theme.of(context).shadowColor),
                  ),
                );
              }),
          AnimatedBuilder(
              animation: _curve,
              builder: (BuildContext context, child) {
                double _height = MediaQuery.of(context).size.height *
                        (1 - _curve.value / 2) -
                    MediaQuery.of(context).size.width *
                        atan(_curve.value * _painterMaxDeg) /
                        2;
                double _boxHeight = 180 + _curve.value * 36;
                return Container(
                    height: _height,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        height: _boxHeight,
                        width: MediaQuery.of(context).size.width,
                        child: Stack(
                          children: [
                            Positioned(
                              child: Image.asset(
                                'assets/splash/logo.png',
                                width: 375,
                                height: 120,
                              ),
                              top: 30,
                              left:
                                  MediaQuery.of(context).size.width / 2 - 187.5,
                            ),
                            Positioned(
                                top: _boxHeight / 2 + 30,
                                child: AnimatedOpacity(
                                  opacity: _showText ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 500),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '習慣を改善しよう',
                                      style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ))
                          ],
                        ),
                      ),
                    ));
              }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class TitlePainter extends CustomPainter {
  double position;
  Color backGroundColor;
  Color shadowColor;
  final double maxDeg;
  late Paint _paint;

  TitlePainter(
      {required this.position,
      required this.backGroundColor,
      required this.maxDeg,
      required this.shadowColor}) {
    _paint = new Paint()
      ..color = backGroundColor
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double y2 = size.height - size.width * atan(position * maxDeg);
    Path path = new Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, y2)
      ..lineTo(size.width, 0);
    canvas.drawShadow(path, Color(0x80000000), 8, true);
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
