
import '../../../../../model/strategy.dart';
import 'rule-card.dart';
import 'package:flutter/material.dart';

class IfThenCard extends StatelessWidget {

  final Strategy strategy;
  IfThenCard({required this.strategy});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> strategyBody = strategy.getBody();
    String ifBody = strategyBody['if'];
    String thenBody = strategyBody['then'];

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.all(Radius.circular(6)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 0),
            )
          ]
      ),
      margin: EdgeInsets.only(
        top: RuleCard.cardVerticalPadding,
        bottom: RuleCard.cardVerticalPadding,
        right: RuleCard.cardHorizontalPadding,
        left: RuleCard.cardHorizontalPadding,
      ),
      padding: EdgeInsets.only(
        top: RuleCard.cardInnerVerticalPadding,
        bottom: RuleCard.cardInnerVerticalPadding,
        left: RuleCard.cardInnerHorizontalPadding,
        right: RuleCard.cardInnerHorizontalPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: RuleCard.subjectPadding),
                  child: Container(
                    width: RuleCard.subjectWidth,
                    child: Text(
                        'If',
                      style: RuleCard.subjectTextStyle.copyWith(
                        color: Theme.of(context).colorScheme.secondary
                      )
                    ),
                  ),
                ),
                Expanded(child: Text(ifBody, style: RuleCard.objectTextStyle.copyWith(
                  color: Theme.of(context).textTheme.bodyText1?.color
                ),))
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(top: 6, bottom: 6),
            child: CustomPaint(
              size: Size(7, 18),
              painter: LinePaint(context: context),
            ),
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: RuleCard.subjectPadding),
                  child: Container(
                    width: RuleCard.subjectWidth,
                    child: Text(
                        'Then',
                        style: RuleCard.subjectTextStyle.copyWith(
                            color: Theme.of(context).colorScheme.secondary
                        )
                    ),
                  ),
                ),
                Expanded(child: Text(thenBody, style: RuleCard.objectTextStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyText1?.color
                ),))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LinePaint extends CustomPainter {
  BuildContext context;
  LinePaint({required this.context});
  @override
  void paint(Canvas canvas, Size size) {
    Paint line = new Paint()
      ..color = Theme.of(context).primaryColorDark
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;
    canvas.drawLine(Offset(5, 1), Offset(5, 17), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}



