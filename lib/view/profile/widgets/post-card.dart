import 'dart:async';

import 'package:brebit/library/exceptions.dart';
import 'package:brebit/view/timeline/post.dart';
import 'package:brebit/view/widgets/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../library/cache.dart';
import '../../../../model/post.dart';
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../../../provider/post.dart';
import '../../home/navigation.dart';
import '../../timeline/posts.dart';
import '../others-profile.dart';
import 'post-card-body/basic.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final int index;

  PostCard({@required this.post, @required this.index});

  void redirectToProfile(BuildContext ctx, AuthUser user) {
    if (ctx.read(authProvider.state).user.id == user.id) {
      Home.pushNamed('/profile');
    } else {
      Home.push(
          MaterialPageRoute(builder: (context) => OtherProfile(user: user)));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMine = post.isMine();
    return Container(
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
                  redirectToProfile(context, post.user);
                },
                child: Center(
                  child: CircleAvatar(
                    child: ClipOval(
                      child: isMine
                          ? HookBuilder(builder: (context) {
                              AuthUser _user =
                                  useProvider(authProvider.state).user;
                              return _user.getImageWidget();
                            })
                          : post.user.getImageWidget(),
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
                            child: Container(
                              child: isMine
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
                                              text: post.user.name,
                                            ),
                                            TextSpan(
                                                text: " @${post.user.customId}"
                                                    .replaceAll("", "\u{200B}"),
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
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child: Text(
                              ' ' + post.getCreatedTime(),
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      .color,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      width: double.infinity,
                      child: PostBody(post: post, num: index),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          LikeButton(post: post),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: CommentButton(post: post),
                          )
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
    );
  }
}

class LikeButton extends StatefulWidget {
  final Post post;

  LikeButton({@required this.post});

  @override
  _LikeButtonState createState() => _LikeButtonState(post: post);
}

class _LikeButtonState extends State<LikeButton> {
  Post post;
  bool _isLiked;
  Timer _timer;
  int favCount;

  _LikeButtonState({@required this.post});

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    this.post = widget.post;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    this._isLiked = this.post.isLiked();
    context.read(postProvider(post.id)).setPost(post);
    favCount = context.read(postProvider(post.id).state).post.getFavCount();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData _theme = Theme.of(context);
    return Container(
      child: Row(
        children: [
          Container(
            width: 18,
            child: IconButton(
                iconSize: 18,
                padding: EdgeInsets.all(0),
                icon: Icon(
                  this._isLiked ? Icons.favorite : Icons.favorite_outline,
                  color: this._isLiked
                      ? _theme.accentIconTheme.color
                      : _theme.textTheme.bodyText1.color,
                  size: _theme.accentIconTheme.size,
                ),
                onPressed: () async {
                  setState(() {
                    if (this._isLiked) {
                      if (favCount > 0) favCount -= 1;
                      this._isLiked = false;
                    } else {
                      favCount += 1;
                      this._isLiked = true;
                    }
                  });
                  _timer?.cancel();
                  _timer = Timer(Duration(milliseconds: 500), () async {
                    try {
                      if (this._isLiked) {
                        await post.like();
                      } else {
                        await post.unlike();
                      }
                      setState(() {
                        _isLiked = context
                            .read(postProvider(post.id).state)
                            .post
                            .isLiked();
                        favCount = context
                            .read(postProvider(post.id).state)
                            .post
                            .getFavCount();
                      });
                    } on RecordNotFoundException {
                      removePostFromAllProvider(post, context);
                    } catch (e) {
                      MyErrorDialog.show(e);
                    }
                    context.read(postProvider(post.id)).setPostNotify(post);
                    await LocalManager.updateProfilePost(
                        await context.read(authProvider).getUser(), post);
                    await LocalManager.updatePost(
                        await context.read(authProvider).getUser(),
                        post,
                        friendProviderName);
                    await LocalManager.updatePost(
                        await context.read(authProvider).getUser(),
                        post,
                        challengeProviderName);
                  });
                }),
          ),
          Container(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              favCount.toString(),
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
    );
  }
}

class CommentButton extends StatefulWidget {
  final Post post;

  CommentButton({@required this.post});

  @override
  _CommentButtonState createState() => _CommentButtonState(post: post);
}

class _CommentButtonState extends State<CommentButton> {
  Post post;

  _CommentButtonState({@required this.post});

  @override
  void didUpdateWidget(covariant CommentButton oldWidget) {
    this.post = widget.post;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData _theme = Theme.of(context);
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 18,
            child: Icon(
              Icons.mode_comment_outlined,
              color: _theme.textTheme.bodyText1.color,
              size: _theme.accentIconTheme.size,
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              post.getCommentCount().toString(),
              style: TextStyle(
                color: _theme.textTheme.bodyText1.color,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          )
        ],
      ),
    );
  }
}
