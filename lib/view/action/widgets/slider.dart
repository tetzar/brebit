import 'package:flutter/material.dart';

class MySlider extends StatefulWidget {
  final int min;
  final int max;
  final int divisions;
  final Function(double) onChanged;
  final int initialValue;

  MySlider(
      {required this.min,
      required this.max,
      required this.divisions,
      required this.onChanged,
      required this.initialValue});

  @override
  _MySliderState createState() => _MySliderState();
}

class _MySliderState extends State<MySlider> {
  late int value;

  @override
  void initState() {
    value = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 32),
      height: 14,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          valueIndicatorColor: Colors.transparent,
          valueIndicatorTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          trackHeight: 15,
          showValueIndicator: ShowValueIndicator.never,
          activeTrackColor: Theme.of(context).colorScheme.secondary,
          thumbColor: Theme.of(context).colorScheme.secondary,
          inactiveTrackColor: Theme.of(context).disabledColor,
          thumbShape: MySliderThumbShape(val: value),
          trackShape: MySliderTrackShape(),
          activeTickMarkColor: Colors.transparent,
          inactiveTickMarkColor: Colors.transparent,
          overlayShape: MySliderOverlayShape(),
        ),
        child: Slider(
          onChanged: (double v) {
            setState(() {
              value = v.round();
            });
            widget.onChanged(v);
          },
          value: value.toDouble(),
          divisions: 10,
          min: 0,
          max: 10,
        ),
      ),
    );
  }
}

class SliderConstants {
  static double lineWidth = 4;
}

class MySliderThumbShape extends SliderComponentShape {
  MySliderThumbShape({required this.val});

  int val;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(7);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.grey //Thumb Background Color
      ..style = PaintingStyle.fill;
    context.canvas.drawCircle(center, 7, paint);

    TextPainter tp = TextPainter(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: val.toString(),
          style: sliderTheme.valueIndicatorTextStyle,
        ),
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(context.canvas, Offset(center.dx - tp.width / 2, -22));
  }
}

class MySliderTrackShape extends SliderTrackShape {
  @override
  void paint(PaintingContext context, Offset offset,
      {required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required Animation<double> enableAnimation,
      required Offset thumbCenter,
      bool isEnabled = true,
      bool isDiscrete = true,
      required TextDirection textDirection}) {
    context.canvas.drawLine(
        Offset(SliderConstants.lineWidth / 2, parentBox.size.height / 2),
        Offset(parentBox.size.width - SliderConstants.lineWidth / 2,
            parentBox.size.height / 2),
        Paint()
          ..color = sliderTheme.inactiveTrackColor ?? Colors.grey
          ..strokeCap = StrokeCap.round
          ..strokeWidth = SliderConstants.lineWidth);
    context.canvas.drawLine(
        Offset(SliderConstants.lineWidth / 2, parentBox.size.height / 2),
        thumbCenter,
        Paint()
          ..color = sliderTheme.activeTrackColor ?? Colors.grey
          ..strokeCap = StrokeCap.round
          ..strokeWidth = SliderConstants.lineWidth);
  }

  @override
  Rect getPreferredRect(
      {required RenderBox parentBox,
      Offset offset = Offset.zero,
      required SliderThemeData sliderTheme,
      bool isEnabled = true,
      bool isDiscrete = true}) {
    return parentBox.semanticBounds;
  }
}

class MySliderOverlayShape extends RoundSliderOverlayShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(10);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final paint = Paint()
      ..color = sliderTheme.overlayColor ?? Colors.grey//Thumb Background Color
      ..style = PaintingStyle.fill;
    context.canvas.drawCircle(center, 15, paint);
  }
}
