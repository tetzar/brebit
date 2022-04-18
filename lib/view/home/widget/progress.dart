import 'dart:async';
import 'dart:math' as Math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../provider/home.dart';
import 'achievd-dialog.dart';

class ProgressCircle extends StatefulWidget {
  @override
  _ProgressCircleState createState() => _ProgressCircleState();
}

class _ProgressCircleState extends State<ProgressCircle> {
  int toNowMin;
  int toAimMin;
  double percentage;
  Timer timer;

  @override
  void initState() {
    super.initState();
    toNowMin = context.read(homeProvider.state).habit.getStartToNow().inMinutes;
    toAimMin =
        context.read(homeProvider.state).habit.getStartToAimDate().inMinutes;

    if (!(toNowMin < toAimMin)) {
      percentage = 1;
    } else {
      percentage = toNowMin / toAimMin;
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!(toNowMin < toAimMin)) {
        achieved(context);
      }
    });
    timer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      if (this.mounted) {
        setState(() {
          toNowMin =
              context.read(homeProvider.state).habit.getStartToNow().inMinutes;
          if (!(toNowMin < toAimMin)) {
            percentage = 1;
            t.cancel();
            achieved(context);
          }
          percentage = toNowMin / toAimMin;
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProgressCircle oldWidget) {
    toNowMin = context.read(homeProvider.state).habit.getStartToNow().inMinutes;
    toAimMin =
        context.read(homeProvider.state).habit.getStartToAimDate().inMinutes;

    if (!(toNowMin < toAimMin)) {
      percentage = 1;
    } else {
      percentage = toNowMin / toAimMin;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 197,
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).primaryColor,
      child: Center(
        child: Container(
          height: 220,
          width: 220,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  spreadRadius: -3,
                  blurRadius: 10,
                  offset: Offset(0, 0),
                )
              ]),
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                child: CircleProgressBar(
                  foregroundColor: Theme.of(context).accentColor,
                  backgroundColor: Colors.black12,
                  toAimMin: this.toAimMin,
                  toNowMin: this.toNowMin,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void achieved(BuildContext context) {
    AchievedDialog.show(context);
  }
}

class CircleProgressBar extends StatelessWidget {
  final Color backgroundColor;
  final Color foregroundColor;
  final int toNowMin;
  final int toAimMin;

  int toNowDays() {
    return (this.toNowMin / 1440).floor();
  }

  int toAimDays() {
    return (this.toAimMin / 1440).round();
  }

  CircleProgressBar({
    Key key,
    this.backgroundColor,
    @required this.foregroundColor,
    @required this.toAimMin,
    @required this.toNowMin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double percentage;
    if (!(toNowMin < toAimMin)) {
      percentage = 1;
    } else {
      percentage = toNowMin / toAimMin;
    }
    final backgroundColor = this.backgroundColor;
    final foregroundColor = this.foregroundColor;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        child: Container(
          child: Center(
              child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: '${toNowDays()}',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: Theme.of(context).textTheme.bodyText1.color),
              children: <TextSpan>[
                TextSpan(
                    text: '\n/ ${toAimDays()}',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyText1.color)),
                TextSpan(
                    text: '\n日継続中',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyText1.color)),
              ],
            ),
          )),
        ),
        foregroundPainter: CircleProgressBarPainter(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          percentage: percentage,
          strokeWidth: 20,
        ),
      ),
    );
  }
}

class CircleProgressBarPainter extends CustomPainter {
  double percentage;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  CircleProgressBarPainter({
    this.backgroundColor,
    @required this.foregroundColor,
    @required this.percentage,
    double strokeWidth,
  }) : this.strokeWidth = strokeWidth ?? 6;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final Size constrainedSize =
        size - Offset(this.strokeWidth, this.strokeWidth);
    final shortestSide =
        Math.min(constrainedSize.width, constrainedSize.height);
    final radius = (shortestSide / 2);

    double theta =
        2 * Math.asin(this.strokeWidth / (4 * (radius + this.strokeWidth / 2)));

    final double startAngle = -(2 * Math.pi * 0.7) + 2 * Math.pi;
    final double sweepAngle = (2 * Math.pi * 0.9 * (this.percentage ?? 0));

    Rect rect = new Rect.fromCircle(center: center, radius: radius);
    SweepGradient grad = new SweepGradient(
        startAngle: 2 * Math.pi / 4,
        endAngle: Math.pi * 10 / 4,
        tileMode: TileMode.repeated,
        colors: <Color>[
          foregroundColor.withOpacity(0),
          foregroundColor.withOpacity(0),
          foregroundColor,
          foregroundColor,
        ],
        stops: [
          0,
          (0.1 * Math.pi - theta) / (2 * Math.pi),
          ((0.1 + 1.8 * percentage) * Math.pi + theta) / (2 * Math.pi),
          1.0
        ]);
    final Paint paint = new Paint()
      ..shader = grad.createShader(rect)
      ..strokeWidth = this.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final oldPainter = (oldDelegate as CircleProgressBarPainter);
    return oldPainter.percentage != this.percentage ||
        oldPainter.backgroundColor != this.backgroundColor ||
        oldPainter.foregroundColor != this.foregroundColor ||
        oldPainter.strokeWidth != this.strokeWidth;
  }
}
