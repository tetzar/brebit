import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:time_machine/time_machine.dart';

import '../../../model/comment.dart';
import '../../../model/favorite.dart';
import '../../../model/notification.dart';
import '../../../model/partner.dart';
import '../../../model/post.dart';
import '../../../provider/auth.dart';
import '../../../provider/notification.dart';
import '../../../provider/posts.dart';
import '../general/loading.dart';
import '../home/navigation.dart';
import '../profile/others-profile.dart';
import '../timeline/post.dart';
import '../timeline/posts.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';
import 'friend-request.dart';
import 'notification-information.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Future<void> getNotifications;

  @override
  void initState() {
    this.getNotifications = context
        .read(notificationProvider)
        .getNotifications(context.read(authProvider.state).user);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read(notificationProvider).markAsReadAll();
        return true;
      },
      child: Scaffold(
        appBar: getMyAppBar(
            context: context,
            backButton: AppBarBackButton.arrow,
            titleText: '通知',
            onBack: () {
              context.read(notificationProvider).markAsReadAll();
              Home.pop();
            }),
        body: Container(
          child: FutureBuilder(
            future: this.getNotifications,
            builder: (BuildContext ctx, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(child: CircularProgressIndicator());
              } else {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      PartnerRequestTile(),
                      NotificationList(),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class PartnerRequestTile extends HookWidget {
  @override
  Widget build(BuildContext context) {
    useProvider(authProvider.state);
    List<Partner> requestedPartners =
        context.read(authProvider.state).user.getRequestedPartners();
    if (requestedPartners.length == 0) {
      return SizedBox(
        height: 0,
      );
    }
    return InkWell(
      onTap: () {
        Home.push(
            MaterialPageRoute(builder: (context) => FriendRequestScreen()));
      },
      child: Container(
        width: double.infinity,
        height: 52,
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Text(
              'フレンド申請',
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 15),
            )),
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                  color: Theme.of(context).accentColor, shape: BoxShape.circle),
            ),
            SizedBox(
              width: 8,
            ),
            Text(
              requestedPartners.length.toString(),
              style:
                  Theme.of(context).textTheme.subtitle1.copyWith(fontSize: 15),
            )
          ],
        ),
      ),
    );
  }
}

class NotificationList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    useProvider(notificationProvider.state);
    List<UserNotification> notifications =
        context.read(notificationProvider.state).notifications;
    print(notifications
        .where((element) => element.readAt == null)
        .toList()
        .length);
    if (notifications.length == 0) {
      return Container(
        margin: EdgeInsets.only(top: 64),
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(
          '通知はまだ届いていません',
          style: Theme.of(context)
              .textTheme
              .bodyText1
              .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      );
    }
    Map<bool, List<UserNotification>> collectedNotifications =
        UserNotification.collectByRead(notifications);
    List<Widget> columnChild = <Widget>[];
    if (collectedNotifications[false].length > 0) {
      columnChild.add(getCategoryBar('新着', context));
      for (UserNotification notification in collectedNotifications[false]) {
        columnChild.add(NotificationTile(notification));
      }
    }
    for (UserNotification _notification in collectedNotifications[true]) {
      int index = collectedNotifications[true].indexOf(_notification);
      int _notificationIsDaysBefore = isDaysBefore(_notification.createdAt);
      if (index == 0) {
        if (_notificationIsDaysBefore == 0) {
          columnChild.add(getCategoryBar('今日', context));
        } else if (_notificationIsDaysBefore < 7) {
          columnChild.add(getCategoryBar('今週', context));
        } else {
          columnChild.add(getCategoryBar('過去', context));
        }
      } else {
        int _previousNotificationIsDaysBefore =
            isDaysBefore(collectedNotifications[true][index - 1].createdAt);
        if (_previousNotificationIsDaysBefore == 0) {
          if (_notificationIsDaysBefore != 0) {
            if (_notificationIsDaysBefore < 7) {
              columnChild.add(getCategoryBar('今週', context));
            } else {
              columnChild.add(getCategoryBar('過去', context));
            }
          }
        } else if (_previousNotificationIsDaysBefore < 7) {
          if (_previousNotificationIsDaysBefore >= 7) {
            columnChild.add(getCategoryBar('過去', context));
          }
        }
      }
      columnChild.add(NotificationTile(_notification));
    }
    return Container(
        child: RefreshIndicator(
      onRefresh: () async {
        try {
          context
              .read(notificationProvider)
              .refreshNotification(await context.read(authProvider).getUser());
        } catch (e) {
          MyErrorDialog.show(e);
        }
      },
      child: SingleChildScrollView(
        child: Column(
          children: columnChild,
        ),
      ),
    ));
  }

  Widget getCategoryBar(String title, BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      color: Theme.of(context).primaryColor,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyText1
            .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  int isDaysBefore(DateTime t) {
    DateTime _now = DateTime.now();
    _now = DateTime.parse(
        '${_now.year}-${_now.month ~/ 10 == 0 ? '0' + _now.month.toString() : _now.month}-${_now.day ~/ 10 == 0 ? '0' + _now.day.toString() : _now.day}');
    return _now.difference(t).inDays;
  }
}

class NotificationTile extends StatelessWidget {
  final UserNotification notification;

  NotificationTile(this.notification);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> notificationBody = notification.getBody();
    UserNotificationType _notificationType = notification.getType();
    Widget title;
    Widget body;
    Widget image;
    Function onTap;
    switch (_notificationType) {
      case UserNotificationType.liked:
        List<Favorite> favorites = notificationBody['favorites'];
        int favoriteCount = notificationBody['favorite_count'];
        if (notificationBody.containsKey('post')) {
          Post post = notificationBody['post'];
          Map postBody = post.getBody();
          bool withLog = false;
          if (postBody.containsKey('habit_log')) {
            if (postBody['habit_log'] != null) {
              withLog = true;
            }
          }
          switch (favoriteCount) {
            case 0:
              return SizedBox(
                height: 0,
              );
              break;
            case 1:
              title = RichText(
                  text: TextSpan(
                      text: favorites.first.user.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      children: [
                    TextSpan(
                        text: withLog ? 'さんがあなたの記録にいいねしました' : 'さんがいいねしました',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                  ]));
              break;
            case 2:
              title = RichText(
                  text: TextSpan(
                      text: favorites.first.user.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      children: [
                    TextSpan(
                        text: 'さん、',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                    TextSpan(
                      text: favorites.last.user.name,
                    ),
                    TextSpan(
                        text: withLog ? 'さんがあなたの記録にいいねしました' : 'さんがいいねしました',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                  ]));
              break;
            default:
              title = RichText(
                  text: TextSpan(
                      text: favorites.first.user.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      children: [
                    TextSpan(
                        text: 'さん、',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                    TextSpan(
                      text: favorites[1].user.name,
                    ),
                    TextSpan(
                        text: 'さん、他${favoriteCount - 2}人',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                    TextSpan(
                        text: withLog ? 'があなたの記録にいいねしました' : 'がいいねしました',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                  ]));
              break;
          }
          body = SizedBox(
            height: 0,
          );
          onTap = () async {
            PostArguments _args = PostArguments(post: post);
            bool action = await Home.push(MaterialPageRoute(builder: (context) {
              return PostPage(
                args: _args,
              );
            }));
            if (action ?? false) {
              onPostDelete(post, context);
            }
          };
          if (postBody['type'] == 'custom') {
            if (postBody['content'] != null) {
              String text;
              if (postBody['content'].isEmpty) {
                if (post.images.length > 0) {
                  text = '${post.images.length}枚の写真';
                }
              } else {
                text = postBody['content'];
              }
              if (text != null) {
                body = Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      .copyWith(fontSize: 12),
                );
              }
            }
          }
        } else if (notificationBody.containsKey('comment')) {
          switch (favoriteCount) {
            case 0:
              return SizedBox(
                height: 0,
              );
              break;
            case 1:
              title = RichText(
                  text: TextSpan(
                      text: favorites.first.user.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      children: [
                    TextSpan(
                        text: 'さんが返信にいいねしました',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                  ]));
              break;
            case 2:
              title = RichText(
                  text: TextSpan(
                      text: favorites.first.user.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      children: [
                    TextSpan(
                        text: 'さん、',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                    TextSpan(
                      text: favorites.last.user.name,
                    ),
                    TextSpan(
                        text: 'さんが返信にいいねしました',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                  ]));
              break;
            default:
              title = RichText(
                  text: TextSpan(
                      text: favorites.first.user.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      children: [
                    TextSpan(
                        text: 'さん、',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                    TextSpan(
                      text: favorites[1].user.name,
                    ),
                    TextSpan(
                        text: 'さん、他${favoriteCount - 2}人',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                    TextSpan(
                        text: 'さんが返信にいいねしました',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400)),
                  ]));
              break;
          }
          Comment comment = notificationBody['comment'];
          onTap = () async {
            Post post = notificationBody['post'];
            bool action = await Home.push(MaterialPageRoute(
                builder: (context) => PostPage(
                      args: PostArguments(post: post),
                    )));
            if (action ?? false) {
              onPostDelete(post, context);
            }
          };
          if ((comment.body ?? '').isEmpty) {
            body = SizedBox(
              height: 0,
            );
          } else {
            body = Text(
              comment.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style:
                  Theme.of(context).textTheme.subtitle1.copyWith(fontSize: 12),
            );
          }
        }
        switch (favoriteCount) {
          case 1:
            image =
                getImageWidget(context, favorites.first.user.getImageWidget());
            break;
          default:
            image = getImageWidget(
              context,
              favorites[0].user.getImageWidget(),
              favorites[1].user.getImageWidget(),
            );
        }
        break;
      case UserNotificationType.commented:
        Comment comment = notificationBody['comment'];
        title = RichText(
            text: TextSpan(
                text: comment.user.name,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                children: [
              TextSpan(
                  text: 'さんが返信しました',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
            ]));
        onTap = () async {
          Post post = notificationBody['post'];
          bool action = await Home.push(MaterialPageRoute(
              builder: (context) => PostPage(
                    args: PostArguments(post: post),
                  )));
          if (action ?? false) {
            onPostDelete(post, context);
          }
        };
        body = Text(
          comment.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.subtitle1.copyWith(fontSize: 12),
        );
        image = getImageWidget(context, comment.user.getImageWidget());
        break;
      case UserNotificationType.partnerAccepted:
        Partner partner = notificationBody['partner'];
        title = RichText(
            text: TextSpan(
                text: partner.user.name,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                children: [
              TextSpan(
                  text: 'さんへのフレンド申請が承認されました',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
            ]));
        image = getImageWidget(context, partner.user.getImageWidget());
        onTap = () {
          if (context.read(authProvider.state).user.id == partner.user.id) {
            Home.pushNamed('/profile');
          } else {
            Home.push(MaterialPageRoute(
                builder: (context) => OtherProfile(user: partner.user)));
          }
        };
        break;
      case UserNotificationType.partnerRequested:
        Partner partner = notificationBody['partner'];
        title = RichText(
            text: TextSpan(
                text: partner.user.name,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                children: [
              TextSpan(
                  text: 'さんからフレンドリクエストが届いています',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
            ]));
        image = getImageWidget(context, partner.user.getImageWidget());
        onTap = () {
          if (context.read(authProvider.state).user.id == partner.user.id) {
            Home.pushNamed('/profile');
          } else {
            Home.push(MaterialPageRoute(
                builder: (context) => OtherProfile(user: partner.user)));
          }
        };
        break;
      case UserNotificationType.information:
        image = Image.asset('assets/images/brebit_team.png');
        title = Text(
          notificationBody['title'],
          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 15),
        );
        onTap = () {
          Home.push(MaterialPageRoute(
              builder: (context) => InformationNotification(notification)));
        };
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Theme.of(context).primaryColor,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                child: ClipOval(child: image),
                radius: 28,
                // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
                backgroundColor: Colors.transparent,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  SizedBox(
                    height: 8,
                  ),
                  body ??
                      SizedBox(
                        height: 0,
                      ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    getTime(),
                    style: Theme.of(context).textTheme.subtitle1.copyWith(
                          fontSize: 10,
                        ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String getTime() {
    DateTime _t = this.notification.createdAt;
    Duration _d = DateTime.now().difference(_t);
    if (_d.inMinutes < 1) {
      return 'たった今';
    } else if (_d.inHours < 1) {
      return '${_d.inMinutes}分前';
    } else if (_d.inDays < 1) {
      return '${_d.inHours}時間前';
    } else if (_d.inDays < 7) {
      if (_d.inDays == 1) {
        return '昨日';
      }
      return '${_d.inDays}日前';
    } else {
      Period _p = LocalDate.today().periodSince(LocalDate.dateTime(_t));
      if (_p.months < 1) {
        return '${_d.inDays ~/ 7}週間前';
      } else if (_p.years < 1) {
        return '${_p.months}ヶ月前';
      } else {
        return '${_p.years}年前';
      }
    }
  }

  Future<void> onPostDelete(Post post, BuildContext context) async {
    if (post.isMine()) {
      try {
        MyLoading.startLoading();
        bool deleteSuccess = await context
            .read(timelineProvider(friendProviderName))
            .deletePost(post);
        if (deleteSuccess ?? false) {
          context
              .read(timelineProvider(challengeProviderName))
              .removePost(post);
        } else {
          await context
              .read(timelineProvider(friendProviderName))
              .deletePost(post);
        }
        await MyLoading.dismiss();
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    } else {
      context.read(timelineProvider(friendProviderName)).removePost(post);
      context.read(timelineProvider(challengeProviderName)).removePost(post);
    }
  }

  Widget getImageWidget(BuildContext context, Widget image,
      [Widget additionalImage]) {
    if (additionalImage == null) {
      return CircleAvatar(
        child: ClipOval(child: image),
        radius: 28,
        // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
        backgroundColor: Colors.transparent,
      );
    }
    return Container(
      height: 56,
      width: 56,
      child: Stack(
        children: [
          CircleAvatar(
            child: ClipOval(child: image),
            radius: 20,
            // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
            backgroundColor: Colors.transparent,
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                  border: Border.all(
                      color: Theme.of(context).primaryColor, width: 2)),
              child: CircleAvatar(
                child: ClipOval(child: additionalImage),
                radius: 20,
                // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
                backgroundColor: Colors.transparent,
              ),
            ),
          )
        ],
      ),
    );
  }
}
