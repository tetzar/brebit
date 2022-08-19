import 'dart:async';

import 'package:brebit/library/exceptions.dart';
import 'package:brebit/view/timeline/post.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../library/cache.dart';
import '../../../../model/post.dart';
import '../../../../model/user.dart';
import '../../../../provider/auth.dart';
import '../../../../provider/post.dart';
import '../../home/navigation.dart';
import '../../profile/others-profile.dart';
import '../../profile/widgets/post-card-body/basic.dart';
import '../posts.dart';

class PostCard extends ConsumerWidget {
  final Post post;
  final int index;

  PostCard({required this.post, required this.index});

  void redirectToProfile(WidgetRef ref, AuthUser user) {
    AuthUser? selfUser = ref.read(authProvider.notifier).user;
    if (selfUser != null && selfUser.id == user.id) {
      Home.pushNamed('/profile');
    } else {
      Home.push(
          MaterialPageRoute(builder: (context) => OtherProfile(user: user)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.read(postProvider(post.id).notifier).post == null) {
      ref.read(postProvider(post.id).notifier).setPost(post);
    }
    ref.watch(postProvider(post.id));
    Post? _post = ref.read(postProvider(post.id).notifier).post;
    if (_post == null) return Container();
    bool isMine = _post.isMine();
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
                  Post? _post = ref.read(postProvider(post.id).notifier).post;
                  if (_post != null) {
                    redirectToProfile(ref, _post.user);
                  }
                },
                child: Center(
                  child: CircleAvatar(
                    child: ClipOval(
                      child: isMine
                          ? Consumer(builder: (context, ref, child) {
                              ref.watch(authProvider);
                              AuthUser? _user =
                                  ref.read(authProvider.notifier).user;
                              return _user?.getImageWidget() ??
                                  post.user.getImageWidget();
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
                            child: isMine
                                ? Consumer(
                                    builder:
                                        (BuildContext context, ref, child) {
                                      ref.watch(authProvider);
                                      AuthUser? user =
                                          ref.read(authProvider.notifier).user;
                                      return RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1
                                                    ?.color,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15),
                                            children: <InlineSpan>[
                                              TextSpan(
                                                text: user?.name ??
                                                    _post.user.name,
                                              ),
                                              TextSpan(
                                                  text:
                                                      " @${user?.customId ?? _post.user.customId}"
                                                          .replaceAll(
                                                              "", "\u{200B}"),
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .subtitle1
                                                          ?.color,
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
                                                ?.color,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                        children: <InlineSpan>[
                                          TextSpan(
                                            text: _post.user.name,
                                          ),
                                          TextSpan(
                                              text: " @${_post.user.customId}"
                                                  .replaceAll("", "\u{200B}"),
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .subtitle1
                                                      ?.color,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 15))
                                        ]),
                                  ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child: Text(
                              ' ' + _post.getCreatedTime(),
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      ?.color,
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
                      child: PostBody(
                        post: _post,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          LikeButton(post: _post),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: CommentButton(post: _post),
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

class LikeButton extends ConsumerStatefulWidget {
  final Post post;

  LikeButton({required this.post});

  @override
  _LikeButtonState createState() => _LikeButtonState(post: post);
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  Post post;
  late bool _isLiked;
  Timer? _timer;
  bool waiting = false;
  late int favCount;

  _LikeButtonState({required this.post});

  @override
  void initState() {
    this._isLiked = this.post.isLiked();
    waiting = false;
    favCount = this.post.favoriteCount;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    this.post = widget.post;
    favCount = this.post.favoriteCount;
    _isLiked = this.post.isLiked();
    print('updated');
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (!waiting) {
      this._isLiked = post.isLiked();
    }
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
                      ? _theme.iconTheme.color
                      : _theme.textTheme.bodyText1?.color,
                  size: _theme.iconTheme.size,
                ),
                onPressed: () async {
                  waiting = true;
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
                    waiting = false;
                    try {
                      if (this._isLiked) {
                        await post.like();
                      } else {
                        await post.unlike();
                      }
                      setState(() {
                        Post? _post =
                            ref.read(postProvider(post.id).notifier).post;
                        if (_post != null) {
                          _isLiked = _post.isLiked();
                          favCount = _post.getFavCount();
                        }
                      });
                    } on RecordNotFoundException {
                      await removePostFromAllProvider(post, ref);
                    }
                    ref
                        .read(postProvider(post.id).notifier)
                        .setPostNotify(post);

                    await LocalManager.updateProfilePost(
                        await ref.read(authProvider.notifier).getUser(), post);
                    await LocalManager.updatePost(
                        await ref.read(authProvider.notifier).getUser(),
                        post,
                        friendProviderName);
                    await LocalManager.updatePost(
                        await ref.read(authProvider.notifier).getUser(),
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
                    ? _theme.iconTheme.color
                    : _theme.textTheme.bodyText1?.color,
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

  CommentButton({required this.post});

  @override
  _CommentButtonState createState() => _CommentButtonState(post: post);
}

class _CommentButtonState extends State<CommentButton> {
  Post post;

  _CommentButtonState({required this.post});

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
              color: _theme.textTheme.bodyText1?.color,
              size: _theme.iconTheme.size,
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              post.getCommentCount().toString(),
              style: TextStyle(
                color: _theme.textTheme.bodyText1?.color,
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
