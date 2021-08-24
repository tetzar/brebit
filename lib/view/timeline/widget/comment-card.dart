import 'dart:async';

import '../../../../library/cache.dart';
import '../../../../model/comment.dart';
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../../../provider/post.dart';
import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../general/report.dart';
import '../../home/navigation.dart';
import '../posts.dart';
import '../../widgets/bottom-sheet.dart';
import '../../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;

  CommentTile({
    @required this.comment,
  });

  @override
  _CommentTileState createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  Comment _comment;

  void redirectToProfile(BuildContext context, AuthUser user) {
    Home.navKey.currentState.pushNamed('/profile', arguments: user);
  }

  void _showActions(BuildContext context) {
    List<BottomSheetItem> items;
    if (this._comment.isMine()) {
      items = [
        CautionBottomSheetItem(
            context: context,
            text: 'コメントを破棄',
            onSelect: () async {
              ApplicationRoutes.pop(context);
              try {
                MyLoading.startLoading();
                await context
                    .read(postProvider(_comment.parent.id))
                    .deleteComment(_comment);
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
            text: 'コメントを報告',
            onSelect: () async {
              ApplicationRoutes.pop();
              bool result = await ApplicationRoutes.push(MaterialPageRoute(
                  builder: (context) => ReportView(this._comment)));
              if (result != null) {
                if (result) {
                  context
                      .read(postProvider(widget.comment.parent.id))
                      .removeComment(widget.comment);
                }
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

  @override
  void initState() {
    this._comment = widget.comment;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int thisUserId = context.read(authProvider.state).user.id;
    return InkWell(
      onLongPress: () {
        _showActions(context);
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.only(top: 12, bottom: 12, right: 16, left: 16),
        child: Container(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                child: RawMaterialButton(
                  onPressed: () {
                    redirectToProfile(context, _comment.user);
                  },
                  child: Center(
                    child: CircleAvatar(
                      child: ClipOval(
                        child: Stack(
                          children: <Widget>[_comment.user.getImageWidget()],
                        ),
                      ),
                      radius: 28,
                      // backgroundImage: NetworkImage('https://via.placeholder.com/300'),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  shape: CircleBorder(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: _comment.user.id == thisUserId
                                  ? HookBuilder(
                                      builder: (BuildContext context) {
                                        AuthUser user =
                                            useProvider(authProvider.state)
                                                .user;
                                        return RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyText1
                                                      .color,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15),
                                              children: <InlineSpan>[
                                                TextSpan(
                                                  text: user.name,
                                                ),
                                                TextSpan(
                                                    text: " @${user.customId}"
                                                        .replaceAll(
                                                            "", "\u{200B}"),
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .subtitle1
                                                            .color,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 15))
                                              ]),
                                        );
                                      },
                                    )
                                  : RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1
                                                  .color,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15),
                                          children: <InlineSpan>[
                                            TextSpan(
                                              text: _comment.user.name,
                                            ),
                                            TextSpan(
                                                text:
                                                    " @${_comment.user.customId}"
                                                        .replaceAll(
                                                            "", "\u{200B}"),
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .subtitle1
                                                        .color,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 15))
                                          ]),
                                    ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              child: Text(
                                ' ' + _comment.getCreatedTime(),
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .color,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        width: double.infinity,
                        child: Text(
                          _comment.body,
                          style: Theme.of(context).textTheme.bodyText1.copyWith(
                              fontWeight: FontWeight.w400, fontSize: 13),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            CommentLikeButton(comment: _comment),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CommentLikeButton extends StatefulWidget {
  final Comment comment;

  CommentLikeButton({@required this.comment});

  @override
  _CommentLikeButtonState createState() =>
      _CommentLikeButtonState(comment: comment);
}

class _CommentLikeButtonState extends State<CommentLikeButton> {
  Comment comment;
  bool _isLiked;
  Timer _timer;
  bool waiting;
  int favCount;

  _CommentLikeButtonState({@required this.comment});

  @override
  void initState() {
    this._isLiked = this.comment.isLiked();
    waiting = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!waiting) {
      this._isLiked = comment.isLiked();
    }
    this.favCount = comment.getFavCount();
    ThemeData _theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        waiting = true;
        setState(() {
          if (this._isLiked) {
            this._isLiked = false;
          } else {
            this._isLiked = true;
          }
        });
        _timer?.cancel();
        _timer = Timer(Duration(milliseconds: 500), () async {
          waiting = false;
          int count;
          if (this._isLiked) {
            count = await comment.like();
          } else {
            count = await comment.unlike();
          }
          if (count != this.favCount && count != null) {
            setState(() {
              this.favCount = count;
            });
            await LocalManager.updatePost(
                await context.read(authProvider).getUser(),
                comment.parent,
                friendProviderName);
            await LocalManager.updatePost(
                await context.read(authProvider).getUser(),
                comment.parent,
                challengeProviderName);
          }
        });
      },
      child: Container(
        child: Row(
          children: [
            Icon(
              this._isLiked ? Icons.favorite : Icons.favorite_outline,
              color: this._isLiked
                  ? _theme.accentIconTheme.color
                  : _theme.textTheme.bodyText1.color,
              size: _theme.accentIconTheme.size,
            ),
            Container(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                this.favCount.toString(),
                style: TextStyle(
                  color: _isLiked
                      ? _theme.accentIconTheme.color
                      : _theme.textTheme.bodyText1.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
