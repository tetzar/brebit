import 'dart:async';

import '../../../model/category.dart';
import '../../../model/post.dart';
import '../../../model/habit.dart';
import '../../../model/habit_log.dart';
import '../../../model/partner.dart';
import '../../../model/user.dart';
import '../../../network/partner.dart';
import '../../../provider/auth.dart';
import '../../../provider/posts.dart';
import '../../../provider/profile.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../general/report.dart';
import '../home/navigation.dart' as Home;
import 'did-confirmation.dart';
import 'widgets/post-card.dart';
import 'widgets/friend-card.dart';
import 'widgets/others-profile-card.dart';
import 'widgets/others-tab-bar.dart';
import '../timeline/create_post.dart';
import '../timeline/post.dart';
import '../timeline/posts.dart';
import '../widgets/back-button.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'activity.dart';

class OtherProfile extends StatelessWidget {
  final AuthUser user;

  OtherProfile({@required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: MyBackButton(),
          title: Text(user.customId),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.more_horiz),
              onPressed: () {
                showActions(context);
              },
            )
          ],
        ),
        body: ProfileContent(
          user: user,
        ));
  }

  void showActions(BuildContext context) {
    Partner _partner = context
        .read(authProvider.state)
        .user
        .getPartner(user);
    PartnerState _partnerState = PartnerState.notRelated;
    if (_partner != null) {
      _partnerState = _partner.getState();
    }
    List<BottomSheetItem> _items = <BottomSheetItem>[];
    switch (_partnerState) {
      case PartnerState.notRelated:
        _items.add(NormalBottomSheetItem(
            context: context,
            text: 'フレンド申請',
            onSelect: () async {
              await requestFriend(context);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'ブロック',
            onSelect: () async {
              await block(context);
            }));
        break;
      case PartnerState.request:
        _items.add(CautionBottomSheetItem(
            context: context,
            text: '申請を取消',
            onSelect: () async {
              await cancelRequest(context);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'ブロック',
            onSelect: () async {
              await block(context);
            }));
        break;
      case PartnerState.requested:
        _items.add(SuccessBottomSheetItem(
            context: context,
            text: 'フレンド申請を承認',
            onSelect: () async {
              await acceptRequest(context);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: '申請を拒否',
            onSelect: () async {
              await cancelRequest(context);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'ブロック',
            onSelect: () async {
              await block(context);
            }));
        break;
      case PartnerState.partner:
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'フレンドを解除',
            onSelect: () async {
              await breakOffFriend(context);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'ブロック',
            onSelect: () async {
              await block(context);
            }));
        break;
      case PartnerState.block:
        _items.add(NormalBottomSheetItem(
            context: context,
            text: 'ブロック解除',
            onSelect: () async {
              await unblock(context);
            }));
        break;
      default:
        break;
    }
    _items.add(CancelBottomSheetItem(
        context: context,
        onSelect: () {
          Navigator.pop(ApplicationRoutes.materialKey.currentContext);
        }));
    showCustomBottomSheet(
        hintText: user.customId,
        context: ApplicationRoutes.materialKey.currentContext,
        backGroundColor: Theme
            .of(context)
            .primaryColor,
        items: _items);
  }

  Future<void> breakOffFriend(BuildContext context) async {
    Partner partner = context
        .read(authProvider.state)
        .user
        .getPartner(user);
    try {
      MyLoading.startLoading();
      await PartnerApi.breakOffWithPartner(partner);
      context.read(authProvider).breakOffWithFriend(partner);
      user.removePartner(user.getPartner(context
          .read(authProvider.state)
          .user));
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> requestFriend(BuildContext context) async {
    try {
      MyLoading.startLoading();
      Map<String, Partner> partners = await PartnerApi.requestPartner(user);
      context.read(authProvider).setPartner(partners['self_relation']);
      context
          .read(profileProvider(user.id))
          .setPartner(partners['other_relation']);
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> acceptRequest(BuildContext context) async {
    try {
      MyLoading.startLoading();
      Map<String, Partner> result = await PartnerApi.acceptPartnerRequest(
          context
              .read(authProvider.state)
              .user
              .getPartner(user));
      context.read(authProvider).setPartner(result['self_relation']);
      context.read(profileProvider(user.id)).setPartner(result['other_relation']);
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> cancelRequest(BuildContext context) async {
    try {
      MyLoading.startLoading();
      Partner partner = context
          .read(authProvider.state)
          .user
          .getPartner(user);
      await PartnerApi.cancelPartnerRequest(partner);
      context.read(authProvider).removePartner(partner);
      context
          .read(profileProvider(user.id))
          .removePartner(context
          .read(authProvider.state)
          .user);
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> block(BuildContext context) async {
    Navigator.pop(ApplicationRoutes.materialKey.currentContext);
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (context) {
          return MyDialog(
            title: Text(
              '@${user.customId}さん\nをブロック',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            body: Text(
              '@${user.customId}さんはあなたのプロフィールを表示したりフレンド申請したりできなくなります。',
              style: TextStyle(
                  color: Theme
                      .of(context)
                      .disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: 'ブロック',
            action: () async {
              try {
                MyLoading.startLoading();
                Map<String, Partner> partners = await PartnerApi.block(user);
                context.read(authProvider).setPartner(partners['self_relation']);
                context
                    .read(profileProvider(user.id))
                    .setPartner(partners['other_relation']);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme
                .of(context)
                .accentTextTheme
                .subtitle1
                .color,
          );
        });
  }

  Future<void> unblock(BuildContext context) async {
    Navigator.pop(ApplicationRoutes.materialKey.currentContext);
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (context) {
          return MyDialog(
            title: SizedBox(
              height: 0,
            ),
            body: Text(
              '@${user.customId}さんの\nブロックを解除',
              style: TextStyle(
                  color: Theme
                      .of(context)
                      .disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: '解除',
            action: () async {
              try {
                MyLoading.startLoading();
                await PartnerApi.unblock(user);
                context.read(authProvider).removePartner(
                    context
                        .read(authProvider.state)
                        .user
                        .getPartner(user));
                context
                    .read(profileProvider(user.id))
                    .removePartner(context
                    .read(authProvider.state)
                    .user);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e){
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme
                .of(context)
                .accentTextTheme
                .subtitle1
                .color,
          );
        });
  }
}

class ProfileContent extends StatefulHookWidget {
  final AuthUser user;

  ProfileContent({@required this.user});

  @override
  _ProfileContentState createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent>
    with SingleTickerProviderStateMixin {
  Future<void> _futureGetProfile;
  TabController _tabController;

  Future<void> _getProfile() async {
    Partner _partner = await context.read(profileProvider(widget.user.id))
        .getProfile();
    if (_partner != null) {
      context.read(authProvider).setPartner(_partner);
    }
  }

  @override
  void initState() {
    if (context
        .read(authProvider.state)
        .user
        .id == widget.user.id) {
      Home.Home.pushReplacementNamed('/profile');
    }
    if (context
        .read(authProvider.state)
        .user
        .isBlocked(widget.user)) {
      Home.Home.pop();
    }
    context.read(profileProvider(widget.user.id)).setUser(widget.user);
    _futureGetProfile = _getProfile();
    if (widget.user.habitCategories.length > 0) {
      _tabController = new TabController(
          length: 3,
          vsync: this,
          initialIndex:
          context.read(tabProvider(widget.user.id).state).toInt());
      _tabController.animation.addListener(() {
        context
            .read(tabProvider(widget.user.id))
            .set(_tabController.animation.value);
      });
    } else {
      _tabController = new TabController(
          length: 2,
          vsync: this,
          initialIndex:
          context.read(tabProvider(widget.user.id).state).toInt());
      _tabController.animation.addListener(() {
        context
            .read(tabProvider(widget.user.id))
            .set(_tabController.animation.value);
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabContents = <Widget>[
      FutureBuilder(
          future: _futureGetProfile,
          builder: (BuildContext context, AsyncSnapshot<void> snapshots) {
            if (snapshots.connectionState == ConnectionState.done) {
              return PostListView(
                  user: widget.user,
                  controller: PrimaryScrollController.of(context));
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
      FutureBuilder(
        future: _futureGetProfile,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return FriendListView(user: widget.user);
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    ];
    if (widget.user.habitCategories.length > 0) {
      tabContents.add(FutureBuilder(
        future: _futureGetProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ChallengeTab(
              user: widget.user,
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ));
    }
    TabBarView tabBarView =
    TabBarView(controller: _tabController, children: tabContents);

    useProvider(authProvider.state);
    if (context
        .read(authProvider.state)
        .user
        .isBlocking(widget.user)) {
      return Container(
        height: double.infinity,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 24),
              color: Theme
                  .of(context)
                  .primaryColor,
              child: ProfileCard(
                user: widget.user,
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                height: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 48,
                    ),
                    Text(
                      '@${widget.user.customId}さんは\nブロックされています',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Text(
                      '@${widget.user.customId}さんはあなたのプロフィールを表示したり' +
                          'フレンド申請することができません。',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            unblock(context);
                          },
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17),
                                color: Theme
                                    .of(context)
                                    .accentColor),
                            child: Text(
                              'ブロック解除',
                              style: TextStyle(
                                  color: Theme
                                      .of(context)
                                      .primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (widget.user.isHidden()) {
      bool isRequesting = context
          .read(authProvider.state)
          .user
          .isRequesting(widget.user);
      return Container(
        height: double.infinity,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 24),
              color: Theme
                  .of(context)
                  .primaryColor,
              child: ProfileCard(
                user: widget.user,
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                height: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 48,
                    ),
                    Text(
                      '@${widget.user.customId}さんは\n非公開アカウントです',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Text(
                      'フレンドのみがポストや\nチャレンジを見ることができます。。',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isRequesting ? InkWell(
                          onTap: () {
                            cancelRequest(context);
                          },
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: Theme.of(context).accentColor,
                                  width: 1
                                ),
                                color: Theme
                                    .of(context)
                                    .primaryColor),
                            child: Text(
                              'フレンド申請を取り消す',
                              style: TextStyle(
                                  color: Theme
                                      .of(context)
                                      .accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ) : InkWell(
                          onTap: () {
                            request(context);
                          },
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17),
                                color: Theme
                                    .of(context)
                                    .accentColor),
                            child: Text(
                              'フレンド申請',
                              style: TextStyle(
                                  color: Theme
                                      .of(context)
                                      .primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        RequestedBar(
          user: widget.user,
        ),
        Expanded(
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  // AppBarとTabBarの間のコンテンツ
                  SliverList(
                    delegate: SliverChildListDelegate([
                      ProfileCard(
                        user: widget.user,
                      )
                    ]),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: ProfileTabBar(
                        tabController: _tabController, user: widget.user),
                  ),
                ];
              },
              body: tabBarView,
            ),
          ),
        )
      ],
    );
  }

  Future<void> unblock(BuildContext context) async {
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (context) {
          return MyDialog(
            title: SizedBox(
              height: 0,
            ),
            body: Text(
              '@${widget.user.customId}さんの\nブロックを解除',
              style: TextStyle(
                  color: Theme
                      .of(context)
                      .disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: '解除',
            action: () async {
              try {
                MyLoading.startLoading();
                await PartnerApi.unblock(widget.user);
                context.read(authProvider).removePartner(context
                    .read(authProvider.state)
                    .user
                    .getPartner(widget.user));
                context
                    .read(profileProvider(widget.user.id))
                    .removePartner(context
                    .read(authProvider.state)
                    .user);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme
                .of(context)
                .accentTextTheme
                .subtitle1
                .color,
          );
        });
  }

  Future<void> request(BuildContext context) async {
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (context) {
          return MyDialog(
            title: SizedBox(
              height: 0,
            ),
            body: Text(
              '@${widget.user.customId}さんに\nフレンド申請',
              style: TextStyle(
                  color: Theme
                      .of(context)
                      .disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: '申請',
            action: () async {
              try {
                MyLoading.startLoading();
                Map<String, Partner> relations = await PartnerApi.requestPartner(widget.user);
                context.read(authProvider).setPartner(relations['self_relation']);
                context
                    .read(profileProvider(widget.user.id)).setPartner(relations['other_relation']);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
          );
        });
  }

  Future<void> cancelRequest(BuildContext context) async {
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (context) {
          return MyDialog(
            title: SizedBox(
              height: 0,
            ),
            body: Text(
              'フレンド申請を取り消す',
              style: TextStyle(
                  color: Theme
                      .of(context)
                      .disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: '取り消す',
            action: () async {
              try {
                MyLoading.startLoading();
                Partner partner = context
                    .read(authProvider.state)
                    .user
                    .getPartner(widget.user);
                await PartnerApi.cancelPartnerRequest(partner);
                context.read(authProvider).removePartner(partner);
                context
                    .read(profileProvider(widget.user.id))
                    .removePartner(context
                    .read(authProvider.state)
                    .user);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme.of(context).accentTextTheme.subtitle1.color,
          );
        });
  }
}

class RequestedBar extends StatefulHookWidget {
  final AuthUser user;

  RequestedBar({@required this.user});

  @override
  _RequestedBarState createState() => _RequestedBarState();
}

class _RequestedBarState extends State<RequestedBar> {
  bool _show;

  @override
  Widget build(BuildContext context) {
    useProvider(authProvider.state);
    _show = false;
    Partner partner =
    context
        .read(authProvider.state)
        .user
        .getPartner(widget.user);
    if (partner != null) {
      if (partner.stateIs(PartnerState.requested)) {
        _show = true;
      }
    }
    if (!_show) {
      return SizedBox(
        height: 0,
      );
    }
    return Container(
      color: Theme
          .of(context)
          .primaryColor,
      width: MediaQuery
          .of(context)
          .size
          .width,
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              widget.user.name + 'さんからフレンド申請が届いています',
              style:
              Theme
                  .of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontSize: 12),
            ),
          ),
          InkWell(
            onTap: () async {
              acceptRequest(context);
            },
            child: Container(
              margin: EdgeInsets.only(left: 8),
              height: 34,
              width: 72,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: Theme
                      .of(context)
                      .accentColor),
              alignment: Alignment.center,
              child: Text(
                '承認',
                style: TextStyle(
                    color: Theme
                        .of(context)
                        .primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              await dennyRequest(context);
            },
            child: Container(
              margin: EdgeInsets.only(left: 4),
              height: 34,
              width: 72,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: Theme
                      .of(context)
                      .primaryColor,
                  border: Border.all(
                      color: Theme
                          .of(context)
                          .accentColor, width: 1)),
              alignment: Alignment.center,
              child: Text(
                '削除',
                style: TextStyle(
                    color: Theme
                        .of(context)
                        .accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> acceptRequest(BuildContext context) async {
    try {
      MyLoading.startLoading();
      Map<String, Partner> result = await PartnerApi.acceptPartnerRequest(
          context
              .read(authProvider.state)
              .user
              .getPartner(widget.user));
      context.read(authProvider).setPartner(result['self_relation']);
      context
          .read(profileProvider(widget.user.id))
          .setPartner(result['other_relation']);
      await MyLoading.dismiss();
      setState(() {
        _show = false;
      });
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> dennyRequest(BuildContext context) async {
    try {
      MyLoading.startLoading();
      Partner partner =
      context
          .read(authProvider.state)
          .user
          .getPartner(widget.user);
      await PartnerApi.cancelPartnerRequest(partner);
      context.read(authProvider).breakOffWithFriend(partner);
      await MyLoading.dismiss();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}

class PostListView extends StatefulWidget {
  final ScrollController controller;
  final AuthUser user;

  PostListView({@required this.controller, @required this.user});

  @override
  _PostListViewState createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  List<Post> _posts;
  bool nowLoading;

  Future<void> reloadOlder(BuildContext ctx) async {
    if (!ctx
        .read(profileProvider(widget.user.id))
        .noMoreContent) {
      if ((widget.controller.position.maxScrollExtent -
          widget.controller.position.pixels) <
          400 &&
          !nowLoading) {
        nowLoading = true;
        await ctx.read(profileProvider(widget.user.id)).reloadOlderTimeLine();
        nowLoading = false;
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    nowLoading = false;
    _posts = context
        .read(profileProvider(widget.user.id).state)
        .user
        .posts;
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
        await context.read(profileProvider(widget.user.id)).reloadTimeLine();
        if (mounted) {
          setState(() {
            _posts =
                context
                    .read(profileProvider(widget.user.id).state)
                    .user
                    .posts;
          });
        }
      },
      child: ListView.builder(
        key: PageStorageKey('profile/${widget.user.id}/posts'),
        itemCount: _posts.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == (_posts.length)) {
            if (context
                .read(profileProvider(widget.user.id))
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
          if (_posts[index].hide) {
            return SizedBox(
              height: 0,
            );
          }
          return InkWell(
              onTap: () async {
                Post _post = _posts[index];
                bool reported = await Home.Home.pushNamed('/post',
                    args: PostArguments(post: _post));
                if (reported != null) {
                  if (reported) {
                    context.read(profileProvider(_post.user.id)).removePost(
                        _post);
                    context
                        .read(timelineProvider(friendProviderName))
                        .removePost(_post);
                    context
                        .read(timelineProvider(challengeProviderName))
                        .removePost(_post);
                  }
                }
              },
              onLongPress: () {
                _showActions(context, _posts[index]);
              },
              child: PostCard(post: _posts[index], index: index));
        },
      ),
    );
  }

  void _showActions(BuildContext context, Post post) {
    List<BottomSheetItem> items;
    items = [
      CautionBottomSheetItem(
          context: context,
          text: 'ポストを報告',
          onSelect: () async {
            ApplicationRoutes.pop();
            bool result = await ApplicationRoutes.push(
                MaterialPageRoute(builder: (context) => ReportView(post)));
            if (result) {
              context.read(profileProvider(post.user.id)).removePost(post);
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
        backGroundColor: Theme
            .of(context)
            .primaryColor,
        context: ApplicationRoutes.materialKey.currentContext);
  }
}

class FriendListView extends StatefulHookWidget {
  final AuthUser user;

  FriendListView({@required this.user});

  @override
  _FriendListViewState createState() => _FriendListViewState();
}

class _FriendListViewState extends State<FriendListView> {
  @override
  Widget build(BuildContext context) {
    ProfileProviderState _profileProviderState =
    useProvider(profileProvider(widget.user.id).state);
    List<Partner> _partners = _profileProviderState.user.getAcceptedPartners();
    return ListView.builder(
      key: PageStorageKey('profile/${widget.user.id}/friend'),
      itemCount: _partners.length,
      itemBuilder: (BuildContext context, int index) {
        return FriendCard(user: _partners[index].user);
      },
    );
  }
}

class ChallengeTab extends HookWidget {
  final AuthUser user;

  ChallengeTab({@required this.user});

  @override
  Widget build(BuildContext context) {
    useProvider(profileProvider(user.id).state);
    List<HabitLog> logs = context
        .read(profileProvider(user.id).state)
        .logs;
    List<List<HabitLog>> collected = HabitLog.collectByDate(logs);
    return Stack(
      children: [
        SingleChildScrollView(
          key: PageStorageKey('profile/${user.id}/challenge'),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: collected.map((logs) => LogCard(logs)).toList(),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    Home.Home.push(MaterialPageRoute(
                        builder: (context) => Activity(user)));
                  },
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        color: Theme
                            .of(context)
                            .primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme
                                .of(context)
                                .shadowColor,
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: Offset(0, 0),
                          )
                        ]),
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    child: Text('詳細なアクティビティ',
                        style: TextStyle(
                            color: Theme
                                .of(context)
                                .accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}

class LogCard extends StatelessWidget {
  final List<HabitLog> logs;

  LogCard(this.logs);

  @override
  Widget build(BuildContext context) {
    String date = '{month}月{day}日';
    Map<String, String> data = {
      'month': logs.first.createdAt.month.toString(),
      'day': logs.first.createdAt.day.toString(),
    };
    data.forEach((key, value) {
      date = date.replaceAll('{$key}', value);
    });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme
            .of(context)
            .primaryColor,
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: Theme
                .of(context)
                .textTheme
                .bodyText1
                .copyWith(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          SizedBox(
            height: 16,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: logs.map((log) => getSubject(log, context)).toList(),
          )
        ],
      ),
    );
  }

  Widget getSubject(HabitLog log, BuildContext context) {
    TextStyle _style = Theme
        .of(context)
        .textTheme
        .bodyText1
        .copyWith(fontSize: 13, fontWeight: FontWeight.w400);
    switch (log.getState()) {
      case HabitLogStateName.started:
        return Text(
          '・チャレンジを開始しました。',
          style: _style,
        );
        break;
      case HabitLogStateName.finished:
        return Text(
          '・チャレンジを終了しました。',
          style: _style,
        );
        break;
      case HabitLogStateName.strategyChanged:
        return Text(
          '・ストラテジーを変更しました。',
          style: _style,
        );
        break;
      case HabitLogStateName.aimdateUpdated:
        return Text(
          '・スモールステップを更新しました。',
          style: _style,
        );
        break;
      case HabitLogStateName.aimdateOvercame:
        int step = log.getBody()['step'];
        return Text('・スモールステップを達成しました($step/${Habit.getStepCount()})');
        break;
      case HabitLogStateName.did:
        final Map<CategoryName, String> didText = {
          CategoryName.cigarette: 'タバコを吸いました。',
          CategoryName.alcohol: 'お酒を飲みました。',
          CategoryName.sweets: 'お菓子を食べました。',
          CategoryName.sns: 'SNSを見てしまいました。',
        };
        String text = didText[log.category.name];
        return GestureDetector(
            onTap: () {
              CreatePostArguments args = new CreatePostArguments();
              args.log = log;
              ApplicationRoutes.push(MaterialPageRoute(
                  builder: (context) => DidConfirmation(log: log)));
            },
            child: RichText(
                text: TextSpan(
                    text: '・',
                    style: _style,
                    children: [
                      TextSpan(
                          text: text,
                          style: TextStyle(
                              decoration: TextDecoration.underline
                          )
                      )
                    ]
                )
            )
        );
        break;
      case HabitLogStateName.wannaDo:
        final Map<CategoryName, String> wannaDoText = {
          CategoryName.cigarette: '・タバコを吸いたい気持ちを抑えました。',
          CategoryName.alcohol: '・お酒を飲みたい気持ちを抑えました。',
          CategoryName.sweets: '・お菓子を食べたい気持ちを抑えました。',
          CategoryName.sns: '・SNSを見たい気持ちを抑えました。',
        };
        String text = wannaDoText[log.category.name];
        return Text(
          text,
          style: _style,
        );
        break;
      default:
        return SizedBox(
          height: 0,
        );
        break;
    }
  }
}
