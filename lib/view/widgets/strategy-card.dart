import '../../../model/strategy.dart';
import 'package:flutter/material.dart';

typedef StrategyCardCallback = bool Function();

class StrategyCard extends StatefulWidget {
  final Strategy strategy;
  final bool initialSelected;
  final StrategyCardCallback onSelect;
  final bool showFollower;

  StrategyCard(
      {@required this.strategy,
      this.initialSelected = false,
      this.onSelect,
      this.showFollower = false});

  static double cardHorizontalPadding = 0;
  static double cardVerticalPadding = 8;
  static double cardInnerHorizontalPadding = 16;
  static double cardInnerVerticalPadding = 16;
  static double subjectWidth = 33;
  static double subjectPadding = 16;
  static double objectWidth = 262;
  static double borderRadius = 8;
  static TextStyle subjectTextStyle =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
  static TextStyle objectTextStyle =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w400);

  @override
  _StrategyCardState createState() => _StrategyCardState();
}

class _StrategyCardState extends State<StrategyCard> {
  Map<String, dynamic> strategyBody;
  bool selected;

  @override
  void initState() {
    selected = widget.initialSelected;
    strategyBody = widget.strategy.getBody();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget strategyContent;
    switch (widget.strategy.getBody()['type']) {
      case 'if-then':
        strategyContent = IfThenCard(
          strategyBody: strategyBody,
        );
        break;
      case 'twenty_sec':
        strategyContent = TwentySecondCard(
          strategyBody: strategyBody,
        );
        break;
      default:
        strategyContent = Container();
        break;
    }
    return InkWell(
      onTap: () {
        if (widget.onSelect != null) {
          setState(() {
            selected = widget.onSelect();
          });
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius:
                BorderRadius.all(Radius.circular(StrategyCard.borderRadius)),
            border: Border.all(
                width: 2,
                color: selected
                    ? Theme.of(context).accentColor
                    : Theme.of(context).accentColor.withOpacity(0)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor,
                spreadRadius: -3,
                blurRadius: 10,
                offset: Offset(0, 0),
              )
            ]),
        margin: EdgeInsets.only(
          top: StrategyCard.cardVerticalPadding,
          bottom: StrategyCard.cardVerticalPadding,
          right: StrategyCard.cardHorizontalPadding,
          left: StrategyCard.cardHorizontalPadding,
        ),
        padding: EdgeInsets.only(
          top: StrategyCard.cardInnerVerticalPadding,
          bottom: StrategyCard.cardInnerVerticalPadding,
          left: StrategyCard.cardInnerHorizontalPadding,
          right: StrategyCard.cardInnerHorizontalPadding,
        ),
        child: widget.showFollower ? Column(
          children: [
            Container(
              margin: EdgeInsets.only(
                bottom: 8
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                widget.strategy.getFollowers().toString() + '人が使用中',
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 13
                ),
              ),
            ),
            strategyContent
          ],
        ) : strategyContent,
      ),
    );
  }
}

class TwentySecondCard extends StatelessWidget {
  final Map<String, dynamic> strategyBody;

  TwentySecondCard({@required this.strategyBody});

  @override
  Widget build(BuildContext context) {
    String content = strategyBody['rule'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: StrategyCard.subjectPadding),
          child: Container(
            width: StrategyCard.subjectWidth,
            child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    text: '20秒',
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    children: <TextSpan>[
                      TextSpan(text: '\nルール', style: TextStyle(fontSize: 10))
                    ])),
          ),
        ),
        Expanded(
            child: Text(
          content,
          style: StrategyCard.objectTextStyle
              .copyWith(color: Theme.of(context).textTheme.bodyText1.color),
        ))
      ],
    );
  }
}

class IfThenCard extends StatelessWidget {
  final Map<String, dynamic> strategyBody;

  IfThenCard({@required this.strategyBody});

  @override
  Widget build(BuildContext context) {
    String ifBody = strategyBody['if'] ?? '';
    String thenBody = strategyBody['then'] ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(right: StrategyCard.subjectPadding),
                child: Container(
                  width: StrategyCard.subjectWidth,
                  child: Text('If',
                      style: StrategyCard.subjectTextStyle
                          .copyWith(color: Theme.of(context).accentColor)),
                ),
              ),
              Expanded(
                  child: Text(
                ifBody,
                style: StrategyCard.objectTextStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyText1.color),
              ))
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
                padding: EdgeInsets.only(right: StrategyCard.subjectPadding),
                child: Container(
                  width: StrategyCard.subjectWidth,
                  child: Text('Then',
                      style: StrategyCard.subjectTextStyle
                          .copyWith(color: Theme.of(context).accentColor)),
                ),
              ),
              Expanded(
                  child: Text(
                thenBody,
                style: StrategyCard.objectTextStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyText1.color),
              ))
            ],
          ),
        ),
      ],
    );
  }
}

class LinePaint extends CustomPainter {
  BuildContext context;

  LinePaint({@required this.context});

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
