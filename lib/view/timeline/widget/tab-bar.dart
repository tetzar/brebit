
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final tabProvider = StateNotifierProvider.autoDispose((ref) => TabProvider(0));

class TabProvider extends StateNotifier<double> {
  TabProvider(double state) : super(state);

  void set(double s) {
    state = s;
  }
}

enum ShowingTab {
  friends,
  challenge,
}

class TimelineTabBarContent extends StatefulHookWidget {
  final TabController tabController;

  TimelineTabBarContent({@required this.tabController});

  @override
  _TimelineTabBarContentState createState() => _TimelineTabBarContentState();
}

class _TimelineTabBarContentState extends State<TimelineTabBarContent> {
  ShowingTab _showingTab;

  @override
  void initState() {
    this._showingTab = ShowingTab.friends;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double position = useProvider(tabProvider.state);
    if (_showingTab == ShowingTab.friends) {
      if (position > 0.9) {
        _showingTab = ShowingTab.challenge;
      }
    } else {
      if (position < 0.1) {
        _showingTab = ShowingTab.friends;
      }
    }
    return Container(
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        top: 8,
        left: 48,
        right: 48,
      ),
      child: Container(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                        onTap: () {
                          changeTab(ShowingTab.friends);
                        },
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'フレンド',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _showingTab == ShowingTab.friends
                                        ? Theme.of(context)
                                            .textTheme
                                            .subtitle1
                                            .color
                                        : Theme.of(context).disabledColor),
                              )
                            ],
                          ),
                        )),
                  ),
                  Expanded(
                    child: InkWell(
                        onTap: () {
                          changeTab(ShowingTab.challenge);
                        },
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                '同じチャレンジ',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _showingTab == ShowingTab.challenge
                                        ? Theme.of(context)
                                            .textTheme
                                            .subtitle1
                                            .color
                                        : Theme.of(context).disabledColor),
                              ),
                            ],
                          ),
                        )),
                  )
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 14,
              child: CustomPaint(
                size: Size(double.infinity, 6),
                painter:
                    TabBarLinePainter(position: position, context: context),
              ),
            )
          ],
        ),
      ),
    );
  }

  void changeTab(ShowingTab tab) {
    switch (tab) {
      case ShowingTab.friends:
        widget.tabController.animateTo(0);
        break;
      case ShowingTab.challenge:
        widget.tabController.animateTo(1);
        break;
    }
  }
}

class TabBarLinePainter extends CustomPainter {
  double position;
  BuildContext context;

  TabBarLinePainter({this.position, this.context});

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 6;
    double lineLength = 37 + 36 * position;
    double center = (size.width * (1 + 2 * position)) / 4;
    double start = center - lineLength / 2;
    double end = center + lineLength / 2;
    Paint line = new Paint()
      ..color = Theme.of(context).accentColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = strokeWidth;
    canvas.drawLine(
        Offset(start, size.height / 2), Offset(end, size.height / 2), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
