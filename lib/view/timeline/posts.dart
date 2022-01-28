import '../../../model/post.dart';
import '../../../provider/posts.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../general/report.dart';
import '../home/navigation.dart';
import 'post.dart';
import 'widget/tab-bar.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'widget/post-card.dart';

final friendProviderName = 'friend';
final challengeProviderName = 'challenge';

class TimeLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.read(timelineProvider(friendProviderName)).getTimeLine(context);
    context.read(timelineProvider(challengeProviderName)).getTimeLine(context);
    return TimelineWidget();
  }
}

class TimelineWidget extends StatefulHookWidget {
  @override
  _TimelineWidgetState createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    _tabController = new TabController(length: 2, vsync: this);
    _tabController.animation.addListener(() {
      context.read(tabProvider).set(_tabController.animation.value);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          TimelineTabBarContent(tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [FriendTab(), ChallengeTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class FriendTab extends StatefulHookWidget {
  @override
  _FriendTabState createState() => _FriendTabState();
}

class _FriendTabState extends State<FriendTab> {
  ScrollController _scrollController;

  bool noMoreContent;
  bool nowLoading;

  @override
  void initState() {
    nowLoading = false;
    noMoreContent = false;
    _scrollController = new ScrollController();
    _scrollController.addListener(() async {
      await reloadOlder();
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> reloadOlder() async {
    if (!noMoreContent) {
      if ((_scrollController.position.maxScrollExtent -
                  _scrollController.position.pixels) <
              400 &&
          !nowLoading) {
        nowLoading = true;
        noMoreContent = await context
            .read(timelineProvider(friendProviderName))
            .reloadPosts(context, true);
        nowLoading = false;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _timelineProviderState =
        useProvider(timelineProvider(friendProviderName).state);
    if (_timelineProviderState.posts == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (_timelineProviderState.posts.length < 10) {
      noMoreContent = true;
    }
    return RefreshIndicator(
      onRefresh: () async {
        await context
            .read(timelineProvider(friendProviderName))
            .reloadPosts(context);
      },
      child: ListView.builder(
        key: PageStorageKey('timeline/friend'),
        scrollDirection: Axis.vertical,
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _timelineProviderState.posts.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == (_timelineProviderState.posts.length)) {
            if (noMoreContent) {
              return Container(
                height: 0,
              );
            }
            return Container(
              width: double.infinity,
              height: 50,
              child: Center(
                child: Container(
                    height: 20, width: 20, child: CircularProgressIndicator()),
              ),
            );
          }
          if (_timelineProviderState.posts[index].hide) {
            return SizedBox(
              height: 0,
            );
          }
          return InkWell(
            onTap: () async {
              Post _post = _timelineProviderState.posts[index];
              bool reported = await Home.pushNamed('/post',
                  args: PostArguments(post: _post));
              if (reported != null && reported) {
                if (_post.isMine()) {
                  bool deleteSuccess = await context
                      .read(timelineProvider(friendProviderName))
                      .deletePost(_post);
                  if (!deleteSuccess) {
                    await context
                        .read(timelineProvider(challengeProviderName))
                        .deletePost(_post);
                  }
                }
                await removePostFromAllProvider(_post, context);
              }
            },
            onLongPress: () {
              _showActions(context, _timelineProviderState.posts[index]);
            },
            child: PostCard(
              post: _timelineProviderState.posts[index],
              index: index,
            ),
          );
        },
      ),
    );
  }

  Future<void> reloadPosts(BuildContext ctx) async {
    try {
      await ctx.read(timelineProvider(friendProviderName)).reloadPosts(ctx);
    } catch (e) {
      MyErrorDialog.show(e);
    }
  }
}

void _showActions(BuildContext context, Post post) {
  List<BottomSheetItem> items;
  if (post.isMine()) {
    items = [
      CautionBottomSheetItem(
          context: context,
          text: '投稿を破棄',
          onSelect: () async {
            ApplicationRoutes.pop(context);
            try {
              MyLoading.startLoading();
              bool deleted = await context
                  .read(timelineProvider(friendProviderName))
                  .deletePost(post);
              if (!deleted) {
                await context
                    .read(timelineProvider(challengeProviderName))
                    .deletePost(post);
              }
              await removePostFromAllProvider(post, context);
              await MyLoading.dismiss();
            } catch (e) {
              await MyLoading.dismiss();
              MyErrorDialog.show(e);
            }
          }),
      CancelBottomSheetItem(
        context: context,
        onSelect: () {
          ApplicationRoutes.pop();
        },
      )
    ];
  } else {
    items = [
      CautionBottomSheetItem(
          context: context,
          text: 'ポストを報告',
          onSelect: () async {
            ApplicationRoutes.pop();
            bool result = await ApplicationRoutes.push(
                MaterialPageRoute(builder: (context) => ReportView(post)));
            if (result != null && result) {
              await removePostFromAllProvider(post, context);
            }
          }),
      CancelBottomSheetItem(
          context: context,
          onSelect: () {
            ApplicationRoutes.pop();
          }),
    ];
  }
  showCustomBottomSheet(
      items: items,
      backGroundColor: Theme.of(context).primaryColor,
      context: ApplicationRoutes.materialKey.currentContext);
}

class ChallengeTab extends StatefulHookWidget {
  @override
  _ChallengeTabState createState() => _ChallengeTabState();
}

class _ChallengeTabState extends State<ChallengeTab> {
  ScrollController _scrollController;

  bool noMoreContent;
  bool nowLoading;

  @override
  void initState() {
    nowLoading = false;
    noMoreContent = false;
    _scrollController = new ScrollController();
    _scrollController.addListener(() async {
      await reloadOlder();
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> reloadOlder() async {
    if (!noMoreContent) {
      if ((_scrollController.position.maxScrollExtent -
                  _scrollController.position.pixels) <
              400 &&
          !nowLoading) {
        nowLoading = true;
        noMoreContent = await context
            .read(timelineProvider(challengeProviderName))
            .reloadPosts(context, true);
        nowLoading = false;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _timelineProviderState =
        useProvider(timelineProvider(challengeProviderName).state);
    if (_timelineProviderState.posts == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (_timelineProviderState.posts.length < 10) {
      noMoreContent = true;
    }
    return RefreshIndicator(
      onRefresh: () async {
        await context
            .read(timelineProvider(challengeProviderName))
            .reloadPosts(context);
      },
      child: ListView.builder(
        key: PageStorageKey('timeline/challenge'),
        scrollDirection: Axis.vertical,
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _timelineProviderState.posts.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == (_timelineProviderState.posts.length)) {
            if (noMoreContent) {
              return Container(
                height: 0,
              );
            }
            return Container(
              width: double.infinity,
              height: 50,
              child: Center(
                child: Container(
                    height: 20, width: 20, child: CircularProgressIndicator()),
              ),
            );
          }
          if (_timelineProviderState.posts[index].hide) {
            return SizedBox(
              height: 0,
            );
          }
          return InkWell(
            onTap: () async {
              Post _post = _timelineProviderState.posts[index];
              bool action = await Home.pushNamed('/post',
                  args: PostArguments(post: _post));
              if (action != null) {
                if (action) {
                  if (_post.isMine()) {
                    bool deleted = await context
                        .read(timelineProvider(friendProviderName))
                        .deletePost(_post);
                    if (deleted) {
                      context
                          .read(timelineProvider(challengeProviderName))
                          .removePost(_post);
                    } else {
                      await context
                          .read(timelineProvider(challengeProviderName))
                          .deletePost(_post);
                    }
                  } else {
                    context
                        .read(timelineProvider(challengeProviderName))
                        .removePost(_timelineProviderState.posts[index]);
                    context
                        .read(timelineProvider(friendProviderName))
                        .removePost(_timelineProviderState.posts[index]);
                  }
                }
              }
            },
            onLongPress: () {
              _showActions(context, _timelineProviderState.posts[index]);
            },
            child: PostCard(
              post: _timelineProviderState.posts[index],
              index: index,
            ),
          );
        },
      ),
    );
  }

  Future<void> reloadPosts(BuildContext ctx) async {
    try {
      await ctx.read(timelineProvider(challengeProviderName)).reloadPosts(ctx);
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }
}
