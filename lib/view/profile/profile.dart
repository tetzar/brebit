import 'dart:async';
import 'dart:developer' as dv;
import 'dart:math';

import 'package:brebit/view/widgets/app-bar.dart';
import 'package:brebit/view/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/partner.dart';
import '../../../model/post.dart';
import '../../../provider/auth.dart';
import '../../../route/route.dart';
import '../home/navigation.dart' as Home;
import '../timeline/post.dart';
import '../widgets/back-button.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/user-card.dart';
import 'others-profile.dart';
import 'widgets/post-card.dart';
import 'widgets/profile-card.dart';
import 'widgets/tab-bar.dart';

class Profile extends HookWidget {
  @override
  Widget build(BuildContext context) {
    AuthProviderState _authProviderState = useProvider(authProvider.state);

    return Scaffold(
        appBar: AppBar(
          leading: MyBackButton(),
          title: getMyAppBarTitle(_authProviderState.user.customId, context),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                GlobalKey<NavigatorState> key = Home.Home.navKey;
                key.currentState.pushNamed('/settings');
              },
            )
          ],
        ),
        body: ProfileContent());
  }
}

class ProfileContent extends StatefulWidget {
  @override
  _ProfileContentState createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent>
    with SingleTickerProviderStateMixin {
  Future<bool> _futureGetTimeline;
  TabController _tabController;

  StreamController _scrollStream;

  ScrollController scrollController;

  GlobalKey _profileCardKey;

  @override
  void initState() {
    _profileCardKey = GlobalKey();
    scrollController = ScrollController();
    _scrollStream = StreamController<double>();
    scrollController.addListener(() {
      if (mounted) {
        _scrollStream.sink.add(max<double>(
            scrollController.offset -
                _profileCardKey.currentContext.size.height,
            0));
      }
    });
    _futureGetTimeline = context.read(authProvider).getProfileTimeline();
    _tabController = new TabController(
        length: 2,
        vsync: this,
        initialIndex: context.read(tabProvider.state).toInt());
    _tabController.animation.addListener(() {
      context.read(tabProvider).set(_tabController.animation.value);
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
                return PostListView(
                    controller: PrimaryScrollController.of(context));
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

class PostListView extends StatefulHookWidget {
  final ScrollController controller;

  PostListView({this.controller});

  @override
  _PostListViewState createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  List<Post> _posts;
  bool nowLoading;

  Future<void> reloadOlder(BuildContext ctx) async {
    print("scrolled");
    if (!ctx.read(authProvider).noMoreContent && !nowLoading) {
      print("start reload");
      nowLoading = true;
      try {
        await ctx.read(authProvider).reloadOlderTimeLine();
      } catch (e) {
        dv.log('debug', error: e);
      }
      nowLoading = false;
      setState(() {});
    }
  }

  @override
  void initState() {
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
    _posts = context.read(authProvider.state).user.posts;
    return RefreshIndicator(
      onRefresh: () async {
        await context.read(authProvider).reloadTimeLine();
        if (mounted) {
          setState(() {
            _posts = context.read(authProvider.state).user.posts;
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
              if (context.read(authProvider).noMoreContent) {
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
                  bool removed = await Home.Home.pushNamed('/post',
                      args: PostArguments(post: _post));
                  if (removed ?? false) {
                    bool deleteSuccess =
                        await context.read(authProvider).deletePost(_post);
                    if (deleteSuccess != null && deleteSuccess) {
                      await removePostFromAllProvider(_post, context);
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
              bool deleted = await context.read(authProvider).deletePost(post);
              if (deleted) {
                await removePostFromAllProvider(post, context);
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

class FriendListView extends StatefulHookWidget {
  @override
  _FriendListViewState createState() => _FriendListViewState();
}

class _FriendListViewState extends State<FriendListView> {
  @override
  Widget build(BuildContext context) {
    AuthProviderState _authProviderState = useProvider(authProvider.state);
    List<Partner> _partners = _authProviderState.user.getAcceptedPartners();
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await context.read(authProvider).reloadProfile();
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
          bool isFriend =
              _authProviderState.user.isFriend(_partners[index].user);
          return InkWell(
              onTap: () {
                if (context.read(authProvider.state).user.id ==
                    _partners[index].user.id) {
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
