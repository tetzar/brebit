import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../provider/auth.dart';

final tabProvider = StateNotifierProvider.autoDispose((ref) => TabProvider(0));

class TabProvider extends StateNotifier<double> {
  TabProvider(double state) : super(state);

  void set(double s) {
    state = s;
  }
}

class ProfileTabBar extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  ProfileTabBar({@required this.tabController});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _ProfileTabBarContent(
      tabController: tabController,
    );
  }

  @override
  double get maxExtent => 43;

  @override
  double get minExtent => 43;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

enum ShowingTab {
  posts,
  friend,
}

class _ProfileTabBarContent extends StatefulHookWidget {
  final TabController tabController;

  _ProfileTabBarContent({@required this.tabController});

  @override
  __ProfileTabBarContentState createState() => __ProfileTabBarContentState();
}

class __ProfileTabBarContentState extends State<_ProfileTabBarContent> {
  ShowingTab _showingTab;

  @override
  void initState() {
    this._showingTab = ShowingTab.posts;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double position = useProvider(tabProvider.state);
    if (_showingTab == ShowingTab.posts) {
      if (position > 0.9) {
        _showingTab = ShowingTab.friend;
      }
    } else {
      if (position < 0.1) {
        _showingTab = ShowingTab.posts;
      }
    }

    useProvider(authProvider.state);
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
                          changeTab(ShowingTab.posts);
                        },
                        child: Center(
                          child: Text(
                            'ポスト',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: _showingTab == ShowingTab.posts
                                    ? Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color
                                    : Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .color),
                          ),
                        )),
                  ),
                  Expanded(
                    child: InkWell(
                        onTap: () {
                          changeTab(ShowingTab.friend);
                        },
                        child: Center(
                          child: Text(
                            'フレンド',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: _showingTab == ShowingTab.friend
                                    ? Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color
                                    : Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .color),
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
      case ShowingTab.posts:
        widget.tabController.animateTo(0);
        break;
      case ShowingTab.friend:
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
    double lineLength = 16 + 22 * position;
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
