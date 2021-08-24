import 'dart:async';

import '../../../model/post.dart';
import '../../../model/partner.dart';
import '../../../provider/auth.dart';
import '../../../provider/posts.dart';
import '../../../route/route.dart';
import '../home/navigation.dart' as Home;
import 'widgets/post-card.dart';
import 'widgets/profile-card.dart';
import 'widgets/tab-bar.dart';
import '../timeline/post.dart';
import '../timeline/posts.dart';
import '../widgets/back-button.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/user-card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'others-profile.dart';

class Profile extends HookWidget {
  @override
  Widget build(BuildContext context) {
    AuthProviderState _authProviderState = useProvider(authProvider.state);

    return Scaffold(
        appBar: AppBar(
          leading: MyBackButton(),
          title: Text(_authProviderState.user.customId),
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

  @override
  void initState() {
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
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // AppBarとTabBarの間のコンテンツ
            SliverList(
              delegate: SliverChildListDelegate([ProfileCard()]),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: ProfileTabBar(tabController: _tabController),
            ),
          ];
        },
        body: tabBarView,
      ),
    );
  }
}

class PostListView extends StatefulWidget {
  final ScrollController controller;

  PostListView({this.controller});

  @override
  _PostListViewState createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  List<Post> _posts;
  bool nowLoading;

  Future<void> reloadOlder(BuildContext ctx) async {
    if (!ctx.read(authProvider).noMoreContent) {
      if ((widget.controller.position.maxScrollExtent -
                  widget.controller.position.pixels) <
              400 &&
          !nowLoading) {
        nowLoading = true;
        await ctx.read(authProvider).reloadOlderTimeLine();
        nowLoading = false;
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    nowLoading = false;
    _posts = context.read(authProvider.state).user.posts;
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
    return RefreshIndicator(
      onRefresh: () async {
        await context.read(authProvider).reloadTimeLine();
        if (mounted) {
          setState(() {
            _posts = context.read(authProvider.state).user.posts;
          });
        }
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
                    height: 20, width: 20, child: CircularProgressIndicator()),
              ),
            );
          }
          return InkWell(
              onTap: () async {
                Post _post = _posts[index];
                bool removed = await Home.Home.pushNamed('/post',
                    args: PostArguments(
                        post: _post));
                if (removed ?? false) {
                  bool deleteSuccess = await context.read(authProvider).deletePost(_post);
                  if (deleteSuccess != null) {
                    if (deleteSuccess) {
                      context
                          .read(timelineProvider(friendProviderName))
                          .removePost(_post);
                      context
                          .read(timelineProvider(challengeProviderName))
                          .removePost(_post);
                    }
                  }
                }
              },
              onLongPress: () {
                _showActions(context, _posts[index]);
              },
              child: PostCard(post: _posts[index], index: index)
          );
        },
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
            ApplicationRoutes.pop(context);
            bool deleted = await context
                .read(authProvider)
                .deletePost(post);
            if (deleted) {
              context
                  .read(timelineProvider(friendProviderName))
                  .removePost(post);
              context
                  .read(timelineProvider(challengeProviderName))
                  .removePost(post);
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
    return ListView.builder(
      key: PageStorageKey('profile/friend'),
      itemCount: _partners.length,
      itemBuilder: (BuildContext context, int index) {
        bool isFriend = _authProviderState.user.isFriend(_partners[index].user);
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
    );
  }
}
