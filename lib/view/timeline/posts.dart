import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/post.dart';
import '../../../provider/posts.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../general/report.dart';
import '../home/navigation.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'post.dart';
import 'widget/post-card.dart';
import 'widget/tab-bar.dart';

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
              children: [
                TimelineTab(providerName: friendProviderName),
                TimelineTab(providerName: challengeProviderName)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineTab extends StatefulHookWidget {
  final String providerName;

  TimelineTab({@required this.providerName});

  @override
  _TimelineTabState createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  ScrollController _scrollController;

  bool nowLoading;

  @override
  void initState() {
    nowLoading = false;
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
    if (context.read(timelineProvider(widget.providerName)).noMoreContent)
      return;
    if ((_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels) <
            400 &&
        !nowLoading) {
      print("reload older");
      nowLoading = true;
      await context
          .read(timelineProvider(widget.providerName))
          .reloadPosts(context, true);
      nowLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final _timelineProviderState =
        useProvider(timelineProvider(widget.providerName).state);
    if (_timelineProviderState.posts == null) {
      return Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () async {
        await context
            .read(timelineProvider(widget.providerName))
            .reloadPosts(context);
      },
      child: ListView.builder(
        key: PageStorageKey('timeline/friend'),
        scrollDirection: Axis.vertical,
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        shrinkWrap: true,
        itemCount: _timelineProviderState.posts.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == (_timelineProviderState.posts.length)) {
            if (context
                .read(timelineProvider(widget.providerName))
                .noMoreContent) {
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
                      .read(timelineProvider(widget.providerName))
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
      await ctx.read(timelineProvider(widget.providerName)).reloadPosts(ctx);
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
