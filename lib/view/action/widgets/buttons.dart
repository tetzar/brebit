import 'package:flutter/material.dart';

typedef   OnTappedCallback = Future<void> Function();

class MyTwoChoiceButton extends StatelessWidget {
  final String firstLabel;
  final OnTappedCallback onFirstTapped;
  final String secondLabel;
  final OnTappedCallback onSecondTapped;

  MyTwoChoiceButton(
      {@required this.firstLabel,
      @required this.onFirstTapped,
      @required this.secondLabel,
      @required this.onSecondTapped});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            await onFirstTapped();
          },
          child: Container(
            width: 300,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).accentColor,
              borderRadius: BorderRadius.all(
                Radius.circular(28)
              )
            ),
            alignment: Alignment.center,
            child: Text(
              firstLabel,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 17
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            top: 20
          ),
          child: InkWell(
            onTap: () async {
              await onSecondTapped();
            },
            child: Container(
              width: 300,
              height: 56,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                      Radius.circular(28)
                  ),
                border: Border.all(
                  color: Theme.of(context).accentColor,
                  width: 2
                )
              ),
              alignment: Alignment.center,
              child: Text(
                secondLabel,
                style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 17
                ),
              ),
            ),
          )
        )
      ],
    );
  }
}
