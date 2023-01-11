import 'dart:async';
import 'dart:developer' as dv;
import 'dart:math';

import 'package:brebit/view/widgets/app-bar.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../api/partner.dart';
import '../../../model/category.dart';
import '../../../model/habit.dart';
import '../../../model/habit_log.dart';
import '../../../model/partner.dart';
import '../../../model/post.dart';
import '../../../model/user.dart';
import '../../../provider/auth.dart';
import '../../../provider/posts.dart';
import '../../../provider/profile.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../general/report.dart';
import '../home/navigation.dart' as Home;
import '../timeline/create_post.dart';
import '../timeline/post.dart';
import '../timeline/posts.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'activity.dart';
import 'did-confirmation.dart';
import 'widgets/friend-card.dart';
import 'widgets/others-profile-card.dart';
import 'widgets/others-tab-bar.dart';
import 'widgets/post-card.dart';

class OtherProfile extends ConsumerWidget {
  final AuthUser user;

  OtherProfile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar:
            getMyAppBar(context: context, titleText: user.customId, actions: [
          IconButton(
            icon: Icon(Icons.more_horiz),
            onPressed: () {
              showActions(context, ref);
            },
          )
        ]),
        body: ProfileContent(
          user: user,
        ));
  }

  void showActions(BuildContext context, WidgetRef ref) {
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser == null) return;
    Partner? _partner = selfUser.getPartner(user);
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
              await requestFriend(ref);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'ブロック',
            onSelect: () async {
              await block(ref);
            }));
        break;
      case PartnerState.request:
        _items.add(CautionBottomSheetItem(
            context: context,
            text: '申請を取消',
            onSelect: () async {
              await cancelRequest(ref);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'ブロック',
            onSelect: () async {
              await block(ref);
            }));
        break;
      case PartnerState.requested:
        _items.add(SuccessBottomSheetItem(
            context: context,
            text: 'フレンド申請を承認',
            onSelect: () async {
              await acceptRequest(ref);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: '申請を拒否',
            onSelect: () async {
              await cancelRequest(ref);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'ブロック',
            onSelect: () async {
              await block(ref);
            }));
        break;
      case PartnerState.partner:
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'フレンドを解除',
            onSelect: () async {
              await breakOffFriend(ref);
            }));
        _items.add(CautionBottomSheetItem(
            context: context,
            text: 'ブロック',
            onSelect: () async {
              await block(ref);
            }));
        break;
      case PartnerState.block:
        _items.add(NormalBottomSheetItem(
            context: context,
            text: 'ブロック解除',
            onSelect: () async {
              await unblock(ref);
            }));
        break;
      default:
        break;
    }
    _items.add(CancelBottomSheetItem(
        context: context,
        onSelect: () {
          ApplicationRoutes.pop();
        }));
    showCustomBottomSheet(
        hintText: user.customId,
        context: ApplicationRoutes.materialKey.currentContext ?? context,
        backGroundColor: Theme.of(context).primaryColor,
        items: _items);
  }

  Future<void> breakOffFriend(WidgetRef ref) async {
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser == null) return;
    Partner? partner = selfUser.getPartner(user);
    if (partner == null) return;
    try {
      MyLoading.startLoading();
      await PartnerApi.breakOffWithPartner(partner);
      ref.read(authProvider.notifier).breakOffWithFriend(partner);
      Partner? othersPartner = user.getPartner(selfUser);
      if (othersPartner != null) {
        user.removePartner(othersPartner);
      }
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> requestFriend(WidgetRef ref) async {
    try {
      MyLoading.startLoading();
      Map<String, Partner> partners = await PartnerApi.requestPartner(user);
      ref.read(authProvider.notifier).setPartner(partners['self_relation']!);
      ref
          .read(profileProvider(user.id).notifier)
          .setPartner(partners['other_relation']!);
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> acceptRequest(WidgetRef ref) async {
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser == null) return;
    Partner? partner = selfUser.getPartner(user);
    if (partner == null) return;
    try {
      MyLoading.startLoading();
      Map<String, Partner> result =
          await PartnerApi.acceptPartnerRequest(partner);
      ref.read(authProvider.notifier).setPartner(result['self_relation']!);
      ref
          .read(profileProvider(user.id).notifier)
          .setPartner(result['other_relation']!);
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> cancelRequest(WidgetRef ref) async {
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser == null) return;
    Partner? partner = selfUser.getPartner(user);
    if (partner == null) return;
    try {
      MyLoading.startLoading();
      await PartnerApi.cancelPartnerRequest(partner);
      ref.read(authProvider.notifier).removePartner(partner);
      ref.read(profileProvider(user.id).notifier).removePartner(selfUser);
      await MyLoading.dismiss();
      ApplicationRoutes.pop();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> block(WidgetRef ref) async {
    ApplicationRoutes.pop();
    BuildContext? routeContext = ApplicationRoutes.materialKey.currentContext;
    if (routeContext == null) return;
    showDialog(
        context: routeContext,
        builder: (context) {
          return MyDialog(
            title: Text(
              '@${user.customId}さん\nをブロック',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            body: Text(
              '@${user.customId}さんはあなたのプロフィールを表示したりフレンド申請したりできなくなります。',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: 'ブロック',
            action: () async {
              try {
                MyLoading.startLoading();
                Map<String, Partner> partners = await PartnerApi.block(user);
                ref
                    .read(authProvider.notifier)
                    .setPartner(partners['self_relation']!);
                ref
                    .read(profileProvider(user.id).notifier)
                    .setPartner(partners['other_relation']!);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme.of(context).primaryTextTheme.subtitle1?.color ??
                Colors.pink,
          );
        });
  }

  Future<void> unblock(WidgetRef ref) async {
    ApplicationRoutes.pop();
    BuildContext? routeContext = ApplicationRoutes.materialKey.currentContext;
    if (routeContext == null) return;
    showDialog(
        context: routeContext,
        builder: (context) {
          return MyDialog(
            title: SizedBox(
              height: 0,
            ),
            body: Text(
              '@${user.customId}さんの\nブロックを解除',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: '解除',
            action: () async {
              AuthUser? selfUser = ref.read(authProvider.notifier).user;
              if (selfUser == null) return;
              Partner? partner = selfUser.getPartner(user);
              if (partner == null) return;
              try {
                MyLoading.startLoading();
                await PartnerApi.unblock(user);
                ref.read(authProvider.notifier).removePartner(partner);
                ref
                    .read(profileProvider(user.id).notifier)
                    .removePartner(selfUser);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme.of(context).primaryTextTheme.subtitle1?.color ??
                Colors.pink,
          );
        });
  }
}

class ProfileContent extends ConsumerStatefulWidget {
  final AuthUser user;

  ProfileContent({required this.user});

  @override
  _ProfileContentState createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<ProfileContent>
    with SingleTickerProviderStateMixin {
  late Future<void> _futureGetProfile;
  late TabController _tabController;
  late GlobalKey _profileCardKey;

  late StreamController<double> _scrollStream;

  late ScrollController scrollController;

  Future<void> _getProfile() async {
    Partner _partner =
        await ref.read(profileProvider(widget.user.id).notifier).getProfile();
    ref.read(profileProvider(widget.user.id).notifier).setPartner(_partner);
  }

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
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser != null && selfUser.id == widget.user.id) {
      Home.Home.pushReplacementNamed('/profile');
    }
    if (selfUser != null && selfUser.isBlocked(widget.user)) {
      Home.Home.pop();
    }
    ref.read(profileProvider(widget.user.id).notifier).setUser(widget.user);
    _futureGetProfile = _getProfile();
    if (widget.user.habitCategories.length > 0) {
      _tabController = new TabController(
          length: 3,
          vsync: this,
          initialIndex:
              ref.read(tabProvider(widget.user.id).notifier).position.toInt());
      Animation? animation = _tabController.animation;
      if (animation != null) {
        animation.addListener(() {
          ref.read(tabProvider(widget.user.id).notifier).set(animation.value);
        });
      }
    } else {
      _tabController = new TabController(
          length: 2,
          vsync: this,
          initialIndex:
              ref.read(tabProvider(widget.user.id).notifier).position.toInt());

      Animation? animation = _tabController.animation;
      if (animation != null) {
        animation.addListener(() {
          ref.read(tabProvider(widget.user.id).notifier).set(animation.value);
        });
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _scrollStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabContents = <Widget>[
      FutureBuilder(
          future: _futureGetProfile,
          builder: (BuildContext context, AsyncSnapshot<void> snapshots) {
            if (snapshots.hasError) {
              dv.log(snapshots.error.toString());
              return Container();
            }
            if (snapshots.connectionState == ConnectionState.done) {
              ScrollController? scrollController =
                  PrimaryScrollController.of(context);
              if (scrollController == null) {
                MyErrorDialog.show(Exception('scroll controller not found'));
                return Container();
              }
              return PostListView(
                  user: widget.user, controller: scrollController);
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

    ref.watch(authProvider);
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser != null && selfUser.isBlocking(widget.user)) {
      return Container(
        height: double.infinity,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 24),
              color: Theme.of(context).primaryColor,
              child: ProfileCard(
                containerKey: _profileCardKey,
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Text(
                      '@${widget.user.customId}さんはあなたのプロフィールを表示したり' +
                          'フレンド申請することができません。',
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(fontSize: 17),
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
                                color: Theme.of(context).colorScheme.secondary),
                            child: Text(
                              'ブロック解除',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
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
      bool isRequesting = selfUser?.isRequesting(widget.user) ?? false;
      return Container(
        height: double.infinity,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 24),
              color: Theme.of(context).primaryColor,
              child: ProfileCard(
                containerKey: _profileCardKey,
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Text(
                      'フレンドのみがポストや\nチャレンジを見ることができます。。',
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(fontSize: 17),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isRequesting
                            ? InkWell(
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          width: 1),
                                      color: Theme.of(context).primaryColor),
                                  child: Text(
                                    'フレンド申請を取り消す',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: () {
                                  request(context);
                                },
                                child: Container(
                                  height: 34,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(17),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                  child: Text(
                                    'フレンド申請',
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
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
            width: MediaQuery.of(context).size.width,
            child: NestedScrollView(
              controller: scrollController,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  // AppBarとTabBarの間のコンテンツ
                  SliverList(
                    delegate: SliverChildListDelegate([
                      ProfileCard(
                        containerKey: _profileCardKey,
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
          ),
        )
      ],
    );
  }

  Future<void> unblock(BuildContext context) async {
    BuildContext? routeContext = ApplicationRoutes.materialKey.currentContext;
    if (routeContext == null) return;
    showDialog(
        context: routeContext,
        builder: (context) {
          return MyDialog(
            title: SizedBox(
              height: 0,
            ),
            body: Text(
              '@${widget.user.customId}さんの\nブロックを解除',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: '解除',
            action: () async {
              AuthUser? selfUser = ref.read(authProvider.notifier).user;
              Partner? partner = selfUser?.getPartner(widget.user);
              if (selfUser == null || partner == null) return;
              try {
                MyLoading.startLoading();
                await PartnerApi.unblock(widget.user);
                ref.read(authProvider.notifier).removePartner(partner);
                ref
                    .read(profileProvider(widget.user.id).notifier)
                    .removePartner(selfUser);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme.of(context).primaryTextTheme.subtitle1?.color ??
                Colors.pink,
          );
        });
  }

  Future<void> request(BuildContext context) async {
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext ?? context,
        builder: (context) {
          return MyDialog(
            title: SizedBox(
              height: 0,
            ),
            body: Text(
              '@${widget.user.customId}さんに\nフレンド申請',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: '申請',
            action: () async {
              try {
                MyLoading.startLoading();
                Map<String, Partner> relations =
                    await PartnerApi.requestPartner(widget.user);
                ref
                    .read(authProvider.notifier)
                    .setPartner(relations['self_relation']!);
                ref
                    .read(profileProvider(widget.user.id).notifier)
                    .setPartner(relations['other_relation']!);
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
        context: ApplicationRoutes.materialKey.currentContext ?? context,
        builder: (context) {
          return MyDialog(
            title: SizedBox(
              height: 0,
            ),
            body: Text(
              'フレンド申請を取り消す',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: '取り消す',
            action: () async {
              AuthUser? selfUser = ref.read(authProvider.notifier).user;
              Partner? partner = selfUser?.getPartner(widget.user);
              if (selfUser == null || partner == null) return;
              try {
                MyLoading.startLoading();
                await PartnerApi.cancelPartnerRequest(partner);
                ref.read(authProvider.notifier).removePartner(partner);
                ref
                    .read(profileProvider(widget.user.id).notifier)
                    .removePartner(selfUser);
                await MyLoading.dismiss();
                ApplicationRoutes.pop();
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme.of(context).primaryTextTheme.subtitle1?.color,
          );
        });
  }
}

class RequestedBar extends ConsumerStatefulWidget {
  final AuthUser user;

  RequestedBar({required this.user});

  @override
  _RequestedBarState createState() => _RequestedBarState();
}

class _RequestedBarState extends ConsumerState<RequestedBar> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    _show = false;
    Partner? partner =
        ref.read(authProvider.notifier).user?.getPartner(widget.user);
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
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              widget.user.name + 'さんからフレンド申請が届いています',
              style:
                  Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 12),
            ),
          ),
          InkWell(
            onTap: () async {
              acceptRequest(ref);
            },
            child: Container(
              margin: EdgeInsets.only(left: 8),
              height: 34,
              width: 72,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: Theme.of(context).colorScheme.secondary),
              alignment: Alignment.center,
              child: Text(
                '承認',
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
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
                  color: Theme.of(context).primaryColor,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 1)),
              alignment: Alignment.center,
              child: Text(
                '削除',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> acceptRequest(WidgetRef ref) async {
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    Partner? partner = selfUser?.getPartner(widget.user);
    if (selfUser == null || partner == null) return;
    try {
      MyLoading.startLoading();
      Map<String, Partner> result =
          await PartnerApi.acceptPartnerRequest(partner);
      ref.read(authProvider.notifier).setPartner(result['self_relation']!);
      ref
          .read(profileProvider(widget.user.id).notifier)
          .setPartner(result['other_relation']!);
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
      Partner? partner =
          ref.read(authProvider.notifier).user?.getPartner(widget.user);
      if (partner == null) return;
      await PartnerApi.cancelPartnerRequest(partner);
      ref.read(authProvider.notifier).breakOffWithFriend(partner);
      await MyLoading.dismiss();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}

class PostListView extends ConsumerStatefulWidget {
  final ScrollController controller;
  final AuthUser user;

  PostListView({required this.controller, required this.user});

  @override
  _PostListViewState createState() => _PostListViewState();
}

class _PostListViewState extends ConsumerState<PostListView> {
  late List<Post> _posts;
  bool nowLoading = false;

  Future<void> reloadOlder(WidgetRef ref) async {
    if (!ref.read(profileProvider(widget.user.id).notifier).noMoreContent) {
      if ((widget.controller.position.maxScrollExtent -
                  widget.controller.position.pixels) <
              400 &&
          !nowLoading) {
        nowLoading = true;
        try {
          await ref
              .read(profileProvider(widget.user.id).notifier)
              .reloadOlderTimeLine();
          nowLoading = false;
          setState(() {});
        } catch (e) {
          MyErrorDialog.show(e);
        }
      }
    }
  }

  @override
  void initState() {
    nowLoading = false;
    _posts = ref.read(profileProvider(widget.user.id).notifier).user.posts;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.controller.addListener(() async {
        if (mounted) {
          await reloadOlder(ref);
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref
              .read(profileProvider(widget.user.id).notifier)
              .reloadTimeLine();
        } catch (e) {
          MyErrorDialog.show(e);
        }
        if (mounted) {
          setState(() {
            _posts =
                ref.read(profileProvider(widget.user.id).notifier).user.posts;
          });
        }
      },
      child: ListView.builder(
        key: PageStorageKey('profile/${widget.user.id}/posts'),
        itemCount: _posts.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == (_posts.length)) {
            if (ref
                .read(profileProvider(widget.user.id).notifier)
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
                bool? reported = await Home.Home.pushNamed('/post',
                    args: PostArguments(post: _post)) as bool?;
                if (reported != null) {
                  if (reported) {
                    ref
                        .read(profileProvider(_post.user.id).notifier)
                        .removePost(_post);
                    ref
                        .read(timelineProvider(friendProviderName).notifier)
                        .removePost(_post);
                    ref
                        .read(timelineProvider(challengeProviderName).notifier)
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
              await removePostFromAllProvider(post, ref);
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
        context: ApplicationRoutes.materialKey.currentContext ?? context);
  }
}

class FriendListView extends ConsumerStatefulWidget {
  final AuthUser user;

  FriendListView({required this.user});

  @override
  _FriendListViewState createState() => _FriendListViewState();
}

class _FriendListViewState extends ConsumerState<FriendListView> {
  late List<Partner> _partners;

  @override
  void initState() {
    _partners = ref
        .read(profileProvider(widget.user.id).notifier)
        .user
        .getAcceptedPartners();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profileProvider(widget.user.id));
    _partners = ref
        .read(profileProvider(widget.user.id).notifier)
        .user
        .getAcceptedPartners();
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(profileProvider(widget.user.id).notifier).getProfile();
        } catch (e) {
          dv.log('debug', error: e);
        }
      },
      child: ListView.builder(
        key: PageStorageKey('profile/${widget.user.id}/friend'),
        itemCount: _partners.length,
        itemBuilder: (BuildContext context, int index) {
          return FriendCard(user: _partners[index].user);
        },
      ),
    );
  }
}

class ChallengeTab extends ConsumerWidget {
  final AuthUser user;

  ChallengeTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileProvider(user.id));
    List<HabitLog> logs = ref.read(profileProvider(user.id).notifier).logs;
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
            width: MediaQuery.of(context).size.width,
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
                        color: Theme.of(context).primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor,
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: Offset(0, 0),
                          )
                        ]),
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    child: Text('詳細なアクティビティ',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
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
        color: Theme.of(context).primaryColor,
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: Theme.of(context)
                .textTheme
                .bodyText1
                ?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
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
    TextStyle? _style = Theme.of(context)
        .textTheme
        .bodyText1
        ?.copyWith(fontSize: 13, fontWeight: FontWeight.w400);
    switch (log.getState()) {
      case HabitLogStateName.started:
        return Text(
          '・チャレンジを開始しました。',
          style: _style,
        );
      case HabitLogStateName.finished:
        return Text(
          '・チャレンジを終了しました。',
          style: _style,
        );
      case HabitLogStateName.strategyChanged:
        return Text(
          '・ストラテジーを変更しました。',
          style: _style,
        );
      case HabitLogStateName.aimDateUpdated:
        return Text(
          '・スモールステップを更新しました。',
          style: _style,
        );
      case HabitLogStateName.aimDateOvercame:
        int step = log.getBody()['step'];
        return Text('・スモールステップを達成しました($step/${Habit.getStepCount()})');
      case HabitLogStateName.did:
        final Map<CategoryName, String> didText = {
          CategoryName.cigarette: 'タバコを吸いました。',
          CategoryName.alcohol: 'お酒を飲みました。',
          CategoryName.sweets: 'お菓子を食べました。',
          CategoryName.sns: 'SNSを見てしまいました。',
        };
        String text = didText[log.category.name]!;
        return GestureDetector(
            onTap: () {
              CreatePostArguments args = new CreatePostArguments();
              args.log = log;
              ApplicationRoutes.push(MaterialPageRoute(
                  builder: (context) => DidConfirmation(log: log)));
            },
            child: RichText(
                text: TextSpan(text: '・', style: _style, children: [
              TextSpan(
                  text: text,
                  style: TextStyle(decoration: TextDecoration.underline))
            ])));
      case HabitLogStateName.wannaDo:
        final Map<CategoryName, String> wannaDoText = {
          CategoryName.cigarette: '・タバコを吸いたい気持ちを抑えました。',
          CategoryName.alcohol: '・お酒を飲みたい気持ちを抑えました。',
          CategoryName.sweets: '・お菓子を食べたい気持ちを抑えました。',
          CategoryName.sns: '・SNSを見たい気持ちを抑えました。',
        };
        String text = wannaDoText[log.category.name]!;
        return Text(
          text,
          style: _style,
        );
      default:
        return SizedBox(
          height: 0,
        );
    }
  }
}
