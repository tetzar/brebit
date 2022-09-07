import 'package:flutter/material.dart';
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

class TimeLine extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(timelineProvider(friendProviderName).notifier).getTimeLine(ref);
    ref.read(timelineProvider(challengeProviderName).notifier).getTimeLine(ref);
    return TimelineWidget();
  }
}

class TimelineWidget extends ConsumerStatefulWidget {
  @override
  _TimelineWidgetState createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends ConsumerState<TimelineWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = new TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(() {
      Animation? animation = _tabController.animation;
      if (animation != null) {
        ref.read(tabProvider.notifier).set(animation.value);
      }
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

class TimelineTab extends ConsumerStatefulWidget {
  final String providerName;

  TimelineTab({required this.providerName});

  @override
  _TimelineTabState createState() => _TimelineTabState();
}

class _TimelineTabState extends ConsumerState<TimelineTab> {
  late ScrollController _scrollController;

  bool nowLoading = false;

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
    if (ref.read(timelineProvider(widget.providerName).notifier).noMoreContent)
      return;
    if ((_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels) <
            400 &&
        !nowLoading) {
      print("reload older");
      nowLoading = true;
      await ref
          .read(timelineProvider(widget.providerName).notifier)
          .reloadPosts(ref, true);
      nowLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(timelineProvider(widget.providerName));
    List<Post> posts =
        ref.read(timelineProvider(widget.providerName).notifier).posts;
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(timelineProvider(widget.providerName).notifier)
            .reloadPosts(ref);
      },
      child: ListView.builder(
        key: PageStorageKey('timeline/friend'),
        scrollDirection: Axis.vertical,
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        shrinkWrap: true,
        itemCount: posts.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == (posts.length)) {
            if (ref
                .read(timelineProvider(widget.providerName).notifier)
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
          if (posts[index].hide) {
            return SizedBox(
              height: 0,
            );
          }
          return InkWell(
            onTap: () async {
              Post _post = posts[index];
              bool? reported = await Home.pushNamed('/post',
                  args: PostArguments(post: _post)) as bool?;
              if (reported != null && reported) {
                if (_post.isMine()) {
                  try {
                    await ref
                        .read(timelineProvider(widget.providerName).notifier)
                        .deletePost(_post);
                  } catch (e) {
                    await ref
                        .read(timelineProvider(challengeProviderName).notifier)
                        .deletePost(_post);
                  }
                }
                await removePostFromAllProvider(_post, ref);
              }
            },
            onLongPress: () {
              _showActions(ref, context, posts[index]);
            },
            child: PostCard(
              post: posts[index],
              index: index,
            ),
          );
        },
      ),
    );
  }

  Future<void> reloadPosts(WidgetRef ref) async {
    try {
      await ref
          .read(timelineProvider(widget.providerName).notifier)
          .reloadPosts(ref);
    } catch (e) {
      MyErrorDialog.show(e);
    }
  }
}

void _showActions(WidgetRef ref, BuildContext context, Post post) {
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
              await ref
                  .read(timelineProvider(friendProviderName).notifier)
                  .deletePost(post);
              await removePostFromAllProvider(post, ref);
              await MyLoading.dismiss();
            } catch (e) {
              try {
                await ref
                    .read(timelineProvider(challengeProviderName).notifier)
                    .deletePost(post);
                await MyLoading.dismiss();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
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
            bool? result = await ApplicationRoutes.push(
                MaterialPageRoute(builder: (context) => ReportView(post)));
            if (result != null && result) {
              await removePostFromAllProvider(post, ref);
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
      context: ApplicationRoutes.materialKey.currentContext ?? context);
}
