import '../../../../model/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final tabProvider =
    StateNotifierProvider.family.autoDispose((ref, index) => TabProvider(0));

class TabProvider extends StateNotifier<double> {
  TabProvider(double state) : super(state);

  void set(double s) {
    state = s;
  }
}

class ProfileTabBar extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AuthUser user;

  static const double EXTENT = 43;

  ProfileTabBar({
    @required this.tabController,
    @required this.user,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (user.habitCategories.length == 0) {
      return _NotStartedProfileTabBarContent(
          tabController: tabController,
          user: user);
    }
    return _ProfileTabBarContent(
      tabController: tabController,
      user: user,
    );
  }

  @override
  double get maxExtent => EXTENT;

  @override
  double get minExtent => EXTENT;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

enum ShowingTab { posts, friend, challenge }

class _ProfileTabBarContent extends StatefulHookWidget {
  final TabController tabController;
  final AuthUser user;

  _ProfileTabBarContent({
    @required this.tabController,
    @required this.user,
  });

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
    double position = useProvider(tabProvider(widget.user.id).state);
    if (position < 0.1) {
      _showingTab = ShowingTab.posts;
    }
    if (position > 0.9 && position < 1.1) {
      _showingTab = ShowingTab.friend;
    }
    if (position > 1.9) {
      _showingTab = ShowingTab.challenge;
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
                          )
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
                                'チャレンジ',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: _showingTab == ShowingTab.challenge
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .color
                                        : Theme.of(context)
                                            .textTheme
                                            .subtitle1
                                            .color),
                              )
                            ],
                          ),
                        )),
                  ),
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
      case ShowingTab.challenge:
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
    double strokeWidth = 6;
    double lineLength;
    if (position < 1) {
      lineLength = 21 + position * 4;
    } else {
      lineLength = 25 + 16 * (position - 1);
    }
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


enum NotStartedShowingTab { posts, friend }

class _NotStartedProfileTabBarContent extends StatefulHookWidget {
  final TabController tabController;
  final AuthUser user;

  _NotStartedProfileTabBarContent({
    @required this.tabController,
    @required this.user,
  });

  @override
  __NotStartedProfileTabBarContentState createState() => __NotStartedProfileTabBarContentState();
}

class __NotStartedProfileTabBarContentState extends State<_NotStartedProfileTabBarContent> {
  NotStartedShowingTab _showingTab;

  @override
  void initState() {
    this._showingTab = NotStartedShowingTab.posts;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double position = useProvider(tabProvider(widget.user.id).state);
    if (position < 0.1) {
      _showingTab = NotStartedShowingTab.posts;
    }
    if (position > 0.9) {
      _showingTab = NotStartedShowingTab.friend;
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
                          changeTab(NotStartedShowingTab.posts);
                        },
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'ポスト',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: _showingTab == NotStartedShowingTab.posts
                                        ? Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color
                                        : Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .color),
                              )
                            ],
                          ),
                        )),
                  ),
                  Expanded(
                    child: InkWell(
                        onTap: () {
                          changeTab(NotStartedShowingTab.friend);
                        },
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'フレンド',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: _showingTab == NotStartedShowingTab.friend
                                        ? Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color
                                        : Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .color),
                              )
                            ],
                          ),
                        )),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 14,
              child: CustomPaint(
                size: Size(double.infinity, 6),
                painter:
                NotStartedTabBarLinePainter(position: position, context: context),
              ),
            )
          ],
        ),
      ),
    );
  }

  void changeTab(NotStartedShowingTab tab) {
    switch (tab) {
      case NotStartedShowingTab.posts:
        widget.tabController.animateTo(0);
        break;
      case NotStartedShowingTab.friend:
        widget.tabController.animateTo(1);
        break;
    }
  }
}

class NotStartedTabBarLinePainter extends CustomPainter {
  double position;
  BuildContext context;

  NotStartedTabBarLinePainter({this.position, this.context});

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 6;
    double lineLength;
    lineLength = 21 + position * 4;
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
