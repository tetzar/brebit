import 'dart:async';
import 'dart:developer' as dv;
import 'dart:math';

import 'package:brebit/view/general/error-widget.dart';
import 'package:brebit/view/widgets/app-bar.dart';
import 'package:brebit/view/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/partner.dart';
import '../../../model/post.dart';
import '../../../provider/auth.dart';
import '../../../route/route.dart';
import '../../model/user.dart';
import '../home/navigation.dart' as Home;
import '../timeline/post.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/user-card.dart';
import 'others-profile.dart';
import 'widgets/post-card.dart';
import 'widgets/profile-card.dart';
import 'widgets/tab-bar.dart';

class Profile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    AuthUser? user = ref.read(authProvider.notifier).user;
    if (user == null) return ErrorToHomeWidget();
    return Scaffold(
        appBar:
            getMyAppBar(context: context, titleText: user.customId, actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Home.Home.pushNamed('/settings');
            },
          )
        ]),
        body: ProfileContent());
  }
}

class ProfileContent extends ConsumerStatefulWidget {
  @override
  _ProfileContentState createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<ProfileContent>
    with SingleTickerProviderStateMixin {
  late Future<bool> _futureGetTimeline;
  late TabController _tabController;

  late StreamController<double> _scrollStream;

  late ScrollController scrollController;

  late GlobalKey _profileCardKey;

  @override
  void initState() {
    _profileCardKey = GlobalKey();
    scrollController = ScrollController();
    _scrollStream = StreamController<double>();
    scrollController.addListener(() {
      if (mounted) {
        _scrollStream.sink.add(max<double>(
            scrollController.offset -
                (_profileCardKey.currentContext?.size?.height ?? 0),
            0));
      }
    });
    _futureGetTimeline = ref.read(authProvider.notifier).getProfileTimeline();
    _tabController = new TabController(
        length: 2,
        vsync: this,
        initialIndex: ref.read(tabProvider.notifier).position.toInt());
    _tabController.animation?.addListener(() {
      Animation? animation = _tabController.animation;
      if (animation != null) {
        ref.read(tabProvider.notifier).set(animation.value);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TabBarView tabBarView = TabBarView(
      controller: _tabController,
      children: [
        FutureBuilder(
            future: _futureGetTimeline,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshots) {
              if (snapshots.connectionState == ConnectionState.done) {
                ScrollController? scrollController =
                    PrimaryScrollController.of(context);
                if (scrollController == null) {
                  MyErrorDialog.show(Exception('scroll controller not found'));
                  return Container();
                }
                return PostListView(controller: scrollController);
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            }),
        FriendListView()
      ],
    );
    return Container(
      width: MediaQuery.of(context).size.width,
      child: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // AppBarとTabBarの間のコンテンツ
            SliverList(
              delegate: SliverChildListDelegate(
                  [ProfileCard(containerKey: _profileCardKey)]),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: ProfileTabBar(tabController: _tabController),
            ),
          ];
        },
        body: Column(
          children: [
            StreamBuilder<double>(
                stream: _scrollStream.stream,
                builder: (context, snapshot) {
                  return SizedBox(
                    height: snapshot.data ?? 0,
                  );
                }),
            Expanded(child: tabBarView),
          ],
        ),
      ),
    );
  }
}

class PostListView extends ConsumerStatefulWidget {
  final ScrollController controller;

  PostListView({required this.controller});

  @override
  _PostListViewState createState() => _PostListViewState();
}

class _PostListViewState extends ConsumerState<PostListView> {
  late List<Post> _posts;
  bool nowLoading = false;

  Future<void> reloadOlder(BuildContext ctx) async {
    print("scrolled");
    if (!ref.read(authProvider.notifier).noMoreContent && !nowLoading) {
      print("start reload");
      nowLoading = true;
      try {
        await ref.read(authProvider.notifier).reloadOlderTimeLine();
      } catch (e) {
        dv.log('debug', error: e);
      }
      nowLoading = false;
      setState(() {});
    }
  }

  @override
  void initState() {
    _posts = ref.read(authProvider.notifier).user?.posts ?? [];
    nowLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.controller.addListener(() async {
        if (mounted) {
          await reloadOlder(context);
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _posts = ref.read(authProvider.notifier).user?.posts ?? [];
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(authProvider.notifier).reloadTimeLine();
        if (mounted) {
          setState(() {
            _posts = ref.read(authProvider.notifier).user?.posts ?? [];
          });
        }
      },
      child: NotificationListener(
        onNotification: (t) {
          if (t is ScrollEndNotification) {
            reloadOlder(context);
          }
          return true;
        },
        child: ListView.builder(
          key: PageStorageKey('profile/post'),
          itemCount: _posts.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == (_posts.length)) {
              if (ref.read(authProvider.notifier).noMoreContent) {
                return Container(
                  height: 0,
                );
              }
              return Container(
                width: double.infinity,
                height: 50,
                child: Center(
                  child: Container(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator()),
                ),
              );
            }
            return InkWell(
                onTap: () async {
                  Post _post = _posts[index];
                  bool? removed = await Home.Home.pushNamed('/post',
                      args: PostArguments(post: _post)) as bool?;
                  if (removed ?? false) {
                    try {
                      await ref.read(authProvider.notifier).deletePost(_post);
                      await removePostFromAllProvider(_post, ref);
                    } catch (e) {
                      MyErrorDialog.show(e);
                    }
                  }
                },
                onLongPress: () {
                  _showActions(context, _posts[index]);
                },
                child: PostCard(post: _posts[index], index: index));
          },
        ),
      ),
    );
  }

  void _showActions(BuildContext context, Post post) {
    List<BottomSheetItem> items;
    items = [
      CautionBottomSheetItem(
          context: context,
          text: '投稿を破棄',
          onSelect: () async {
            try {
              ApplicationRoutes.pop(context);
              bool deleted =
                  await ref.read(authProvider.notifier).deletePost(post);
              if (deleted) {
                await removePostFromAllProvider(post, ref);
              }
            } catch (e) {
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
    showCustomBottomSheet(
        items: items,
        backGroundColor: Theme.of(context).primaryColor,
        context: ApplicationRoutes.materialKey.currentContext);
  }
}

class FriendListView extends ConsumerStatefulWidget {
  @override
  _FriendListViewState createState() => _FriendListViewState();
}

class _FriendListViewState extends ConsumerState<FriendListView> {
  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    AuthUser? user = ref.read(authProvider.notifier).user;
    List<Partner> _partners = user?.getAcceptedPartners() ?? [];
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(authProvider.notifier).reloadProfile();
        } catch (e) {
          dv.log('debug', error: e);
        }
        if (mounted) {
          setState(() {});
        }
      },
      child: ListView.builder(
        key: PageStorageKey('profile/friend'),
        itemCount: _partners.length,
        itemBuilder: (BuildContext context, int index) {
          bool isFriend = user?.isFriend(_partners[index].user) ?? false;
          return InkWell(
              onTap: () {
                if (user != null && user.id == _partners[index].user.id) {
                  Home.Home.pushNamed('/profile');
                } else {
                  Home.Home.push(MaterialPageRoute(
                      builder: (context) =>
                          OtherProfile(user: _partners[index].user)));
                }
              },
              child: UserCard(
                user: _partners[index].user,
                isFriend: isFriend,
              ));
        },
      ),
    );
  }
}
