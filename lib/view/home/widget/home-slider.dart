
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final tabProvider = StateNotifierProvider((ref) => TabProvider(0));

class TabProvider extends StateNotifier<double> {
  TabProvider(double state) : super(state);

  void set(double s) {
    state = s;
  }
}

enum ShowingTab {
  progress,
  analytics,
  pileUp
}

class HomeTabBarContent extends StatefulHookWidget {
  final TabController tabController;

  HomeTabBarContent({@required this.tabController});

  @override
  _HomeTabBarContentState createState() => _HomeTabBarContentState();
}

class _HomeTabBarContentState extends State<HomeTabBarContent> {
  ShowingTab _showingTab;

  @override
  void initState() {
    this._showingTab = ShowingTab.progress;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double position = useProvider(tabProvider.state);
    if (position < 0.1) {
      _showingTab = ShowingTab.progress;
    }
    if (position > 0.9 && position < 1.1) {
      _showingTab = ShowingTab.analytics;
    }
    if (position > 1.9) {
      _showingTab = ShowingTab.pileUp;
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
                          changeTab(ShowingTab.progress);
                        },
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                '概要',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: _showingTab == ShowingTab.progress
                                        ? Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color
                                        : Theme.of(context).textTheme.subtitle1.color),
                              )
                            ],
                          ),
                        )),
                  ),
                  Expanded(
                    child: InkWell(
                        onTap: () {
                          changeTab(ShowingTab.analytics);
                        },
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                '分析',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: _showingTab == ShowingTab.analytics
                                        ? Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color
                                        : Theme.of(context).textTheme.subtitle1.color),
                              ),
                            ],
                          ),
                        )),
                  ),
                  Expanded(
                    child: InkWell(
                        onTap: () {
                          changeTab(ShowingTab.pileUp);
                        },
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'アクティビティ',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: _showingTab == ShowingTab.pileUp
                                        ? Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color
                                        : Theme.of(context).textTheme.subtitle1.color),
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
      case ShowingTab.progress:
        widget.tabController.animateTo(0);
        break;
      case ShowingTab.analytics:
        widget.tabController.animateTo(1);
        break;
      case ShowingTab.pileUp:
        widget.tabController.animateTo(2);
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
    double lineLength;
    if (position < 1) {
      lineLength = 16;
    } else {
      lineLength = 16 + 35 * (position - 1);
    }
    double strokeWidth = 6;
    double center = (size.width * (1 + 2 * position)) / 6;
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
