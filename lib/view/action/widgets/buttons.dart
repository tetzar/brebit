import 'package:flutter/material.dart';

typedef OnTappedCallback = Future<void> Function();

class MyTwoChoiceButton extends StatelessWidget {
  final String firstLabel;
  final OnTappedCallback onFirstTapped;
  final String secondLabel;
  final OnTappedCallback onSecondTapped;

  MyTwoChoiceButton(
      {required this.firstLabel,
      required this.onFirstTapped,
      required this.secondLabel,
      required this.onSecondTapped});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RoundedFlatButton(onTap: onFirstTapped, label: firstLabel),
        Container(
            margin: EdgeInsets.only(top: 20),
            child: RoundedFlatButton(
              onTap: onSecondTapped,
              label: secondLabel,
              type: RoundedFlatButtonType.outlined,
            ))
      ],
    );
  }
}

enum RoundedFlatButtonType { filled, outlined }

class RoundedFlatButton extends StatelessWidget {
  const RoundedFlatButton(
      {Key? key,
      required this.onTap,
      required this.label,
      this.type = RoundedFlatButtonType.filled})
      : super(key: key);
  final OnTappedCallback onTap;
  final String label;
  final RoundedFlatButtonType type;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    BoxDecoration decoration;
    switch (this.type) {
      case RoundedFlatButtonType.filled:
        textColor = Theme.of(context).primaryColor;
        decoration = BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.all(Radius.circular(28)));
        break;
      default:
        decoration = BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            border: Border.all(
                color: Theme.of(context).colorScheme.secondary, width: 2));
        textColor = Theme.of(context).colorScheme.secondary;
        break;
    }
    return InkWell(
      onTap: () async {
        await onTap();
      },
      child: Container(
        width: 300,
        height: 56,
        decoration: decoration,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
    );
  }
}
