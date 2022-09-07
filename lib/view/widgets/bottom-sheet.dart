import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class BottomSheetItem extends StatelessWidget {
  final Function() onTap;
  final Widget child;

  BottomSheetItem({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onTap,
        child: Container(
          height: 59,
          width: double.infinity,
          alignment: Alignment.center,
          child: child,
        ));
  }
}

class CancelBottomSheetItem extends BottomSheetItem {
  final BuildContext context;
  final String? text;
  final Function() onSelect;

  CancelBottomSheetItem(
      {required this.context, this.text, required this.onSelect})
      : super(
            child: Text(
              text ?? 'キャンセル',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Theme.of(context).disabledColor),
            ),
            onTap: onSelect);
}

class NormalBottomSheetItem extends BottomSheetItem {
  final BuildContext context;
  final String text;
  final Function() onSelect;

  NormalBottomSheetItem(
      {required this.context, required this.text, required this.onSelect})
      : super(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            onTap: onSelect);
}

class CautionBottomSheetItem extends BottomSheetItem {
  final BuildContext context;
  final String text;
  final Function() onSelect;

  CautionBottomSheetItem(
      {required this.context, required this.text, required this.onSelect})
      : super(
            child: Text(
              text,
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            onTap: onSelect);
}

class SuccessBottomSheetItem extends BottomSheetItem {
  final BuildContext context;
  final String text;
  final Function() onSelect;

  SuccessBottomSheetItem(
      {required this.context, required this.text, required this.onSelect})
      : super(
            child: Text(
              text,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
            onTap: onSelect);
}

void showCustomBottomSheet(
    {required List<BottomSheetItem> items,
    required Color backGroundColor,
    required BuildContext context,
    bool isDismissible = true,
    bool enableDrag = true,
    Function()? onClosed,
    String? hintText}) async {
  List<Widget> widgets = [
    hintText == null
        ? Container(
            width: double.infinity,
            height: 45,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 45),
              painter: BottomSheetBarPainter(
                  barColor: Theme.of(context).primaryColorDark),
            ),
          )
        : Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 27,
                  width: double.infinity,
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 45),
                    painter: BottomSheetBarPainter(
                        barColor: Theme.of(context).primaryColorDark),
                  ),
                ),
                Text(
                  hintText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Theme.of(context).disabledColor),
                )
              ],
            ),
          )
  ];
  widgets.addAll(items);
  await showCupertinoModalBottomSheet(
    context: context,
    builder: (context) => Wrap(
      children: [
        Container(
          color: backGroundColor,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: widgets,
          ),
        )
      ],
    ),
    // isDismissible: isDismissible,
    // enableDrag: enableDrag,
    topRadius: Radius.circular(30),
    barrierColor: Color(0x80000000),
    // animationCurve: Curves.easeOutBack,
    // duration: const Duration(milliseconds: 200)
  );
  if (onClosed != null) {
    onClosed();
  }
}

class BottomSheetBarPainter extends CustomPainter {
  final Color barColor;
  final double length = 27;
  final double top = 8;
  final double strokeWidth = 3;

  BottomSheetBarPainter({required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = barColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset((size.width - length) / 2, top + strokeWidth / 2),
        Offset((size.width + length) / 2, top + strokeWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
