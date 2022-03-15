import 'dart:async';

import 'package:brebit/library/exceptions.dart';
import 'package:brebit/provider/posts.dart';
import 'package:brebit/provider/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../library/cache.dart';
import '../../../model/comment.dart';
import '../../../model/post.dart';
import '../../../model/user.dart';
import '../../../provider/auth.dart';
import '../../../provider/post.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../general/report.dart';
import '../home/navigation.dart';
import '../profile/widgets/post-card-body/basic.dart';
import '../widgets/app-bar.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'posts.dart';
import 'widget/comment-card.dart';

class PostArguments {
  Post post;

  PostArguments({@required this.post});
}

class PostPage extends StatefulWidget {
  final PostArguments args;

  PostPage({@required this.args});

  @override
  _PostPageState createState() => _PostPageState(args: args);
}

class _PostPageState extends State<PostPage> {
  PostArguments args;

  _PostPageState({@required this.args});

  String text = '';

  bool showForm;

  bool keyboardIsOpen;

  Post _post;

  @override
  void initState() {
    if (args.post.hide) {
      Home.pop();
    }
    _post = args.post;
    _post.setParentToComments();
    if (context.read(postProvider(args.post.id).state) == null) {
      context.read(postProvider(args.post.id)).setPost(args.post);
    } else if (context.read(postProvider(args.post.id).state).post == null) {
      context.read(postProvider(args.post.id)).setPost(args.post);
    }
    context.read(postProvider(widget.args.post.id)).reload().catchError(
        (error) async {
      await removePostFromAllProvider(widget.args.post, context);
      Home.pop();
    }, test: (e) => e is RecordNotFoundException);
    showForm = false;
    keyboardIsOpen = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        PostProviderState _postProviderState =
            useProvider(postProvider(args.post.id).state);
        useProvider(authProvider.state);
        _post = _postProviderState.post;
        return KeyboardVisibilityBuilder(builder: (context, visible) {
          if (!visible) {
            if (_focusNode != null) _focusNode.unfocus();
            if (keyboardIsOpen) {
              showForm = false;
              keyboardIsOpen = false;
            }
          } else {
            keyboardIsOpen = true;
          }
          return Container(
              width: MediaQuery.of(context).size.width,
              child: Scaffold(
                  appBar: getMyAppBar(
                    context: context,
                    titleText: 'ポスト',
                  ),
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      ListView(
                        children: [
                          PostContent(
                              post: _postProviderState.post,
                              onCommentTap: () {
                                setState(() {
                                  showForm = true;
                                });
                              }),
                          CommentList(
                            comments: _postProviderState.post.comments,
                          ),
                        ],
                      ),
                      Positioned(
                          width: MediaQuery.of(context).size.width,
                          bottom: 0,
                          left: 0,
                          child: showForm
                              ? CommentForm(
                                  post: _postProviderState.post,
                                  text: text,
                                  unFocus: (String t) {
                                    this.text = t;
                                  },
                                )
                              : SizedBox(
                                  height: 0,
                                ))
                    ],
                  )));
        });
      },
    );
  }

  @override
  void dispose() {
    if (_post != null) {
      LocalManager.updatePost(AuthUser.selfUser, _post, friendProviderName);
      LocalManager.updatePost(AuthUser.selfUser, _post, challengeProviderName);
    }
    super.dispose();
  }
}

class PostContent extends StatelessWidget {
  final Post post;
  final Function onCommentTap;

  PostContent({this.post, this.onCommentTap});

  void redirectToProfile(BuildContext context, AuthUser user) {
    Home.navKey.currentState.pushNamed('/profile', arguments: user);
  }

  void _showActions(BuildContext context) {
    List<BottomSheetItem> items;
    if (this.post.isMine()) {
      items = [
        CautionBottomSheetItem(
            context: context,
            text: '投稿を破棄',
            onSelect: () async {
              ApplicationRoutes.pop();
              Home.pop(true);
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
              bool result = await ApplicationRoutes.push(MaterialPageRoute(
                  builder: (context) => ReportView(this.post)));
              if (result != null) {
                if (result) {
                  Home.pop(true);
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
  Widget build(BuildContext context) {
    int thisUserId = context.read(authProvider.state).user.id;
    Widget _profileContent = Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    child: Stack(
                      children: <Widget>[post.user.getImageWidget()],
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
              child: Container(
            padding: EdgeInsets.only(left: 8),
            width: double.infinity,
            child: post.user.id == thisUserId
                ? HookBuilder(
                    builder: (BuildContext context) {
                      AuthUser user = useProvider(authProvider.state).user;
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                ),
                                Text(
                                  post.getCreatedTime(),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .subtitle1
                                          .color,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            Text('@' + user.customId,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .color,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15))
                          ]);
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                post.user.name,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15),
                              ),
                            ),
                            Text(
                              post.getCreatedTime(),
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      .color,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                        Text('@' + post.user.customId,
                            style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.subtitle1.color,
                                fontWeight: FontWeight.w400,
                                fontSize: 15))
                      ]),
          ))
        ],
      ),
    );
    return InkWell(
      onLongPress: () {
        _showActions(context);
      },
      child: Container(
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _profileContent,
              Container(
                margin: EdgeInsets.only(top: 16),
                width: double.infinity,
                child: PostBody(post: post),
              ),
              Container(
                margin: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    LikeButton(post: post),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: CommentButton(post: post, onTap: onCommentTap),
                    )
                  ],
                ),
              )
            ],
          )),
    );
  }
}

Future<void> removePostFromAllProvider(Post post, BuildContext context) async {
  context.read(timelineProvider(friendProviderName)).removePost(post);
  context.read(timelineProvider(challengeProviderName)).removePost(post);
  if (post.user.id == AuthUser.selfUser.id) {
    context.read(authProvider).removePost(post);
  } else {
    context.read(profileProvider(post.user.id)).removePost(post);
  }
  await LocalManager.deletePost(
      await context.read(authProvider).getUser(), post, friendProviderName);
  await LocalManager.deletePost(
      await context.read(authProvider).getUser(), post, challengeProviderName);
  await LocalManager.deleteProfilePost(
      await context.read(authProvider).getUser(), post);
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
  bool waiting;
  int favCount;

  _LikeButtonState({@required this.post});

  @override
  void initState() {
    this._isLiked = this.post.isLiked();
    waiting = false;
    favCount = post.getFavCount();
    super.initState();
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
                      ? _theme.accentIconTheme.color
                      : _theme.textTheme.bodyText1.color,
                  size: _theme.accentIconTheme.size,
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
                  _timer = Timer(Duration(milliseconds: 400), () async {
                    waiting = false;
                    try {
                      if (this._isLiked) {
                        await post.like();
                      } else {
                        await post.unlike();
                      }
                      setState(() {
                        _isLiked = post.isLiked();
                        favCount = post.getFavCount();
                      });
                    } on RecordNotFoundException {
                      await removePostFromAllProvider(post, context);
                      if (Home.navKey.currentState.canPop()) {
                        Home.navKey.currentState.pop();
                      }
                      return;
                    }
                    context.read(postProvider(post.id)).setPostNotify(post);
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
  final Function onTap;

  CommentButton({@required this.post, @required this.onTap});

  @override
  _CommentButtonState createState() => _CommentButtonState(post: post);
}

class _CommentButtonState extends State<CommentButton> {
  Post post;

  _CommentButtonState({@required this.post});

  void _showCommentForm(BuildContext context) {
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData _theme = Theme.of(context);
    return InkWell(
      onTap: () {
        _showCommentForm(context);
      },
      child: Container(
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
      ),
    );
  }
}

class CommentList extends StatefulWidget {
  final List<Comment> comments;

  CommentList({@required this.comments});

  @override
  _CommentListState createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  List<Comment> _comments;

  @override
  void initState() {
    _comments = widget.comments;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CommentList oldWidget) {
    _comments = widget.comments;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> commentTiles = <Widget>[];
    this._comments.forEach((cmt) {
      if (!cmt.hide) {
        CommentTile tile = new CommentTile(comment: cmt);
        commentTiles.add(tile);
      }
    });
    return Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: commentTiles,
        ));
  }
}

class CommentFormResult {
  String comment;
}

class CommentForm extends StatefulWidget {
  final Post post;
  final Function unFocus;
  final String text;

  CommentForm(
      {Key key,
      @required this.post,
      @required this.text,
      @required this.unFocus})
      : super(key: key);

  @override
  _CommentFormState createState() => _CommentFormState();
}

FocusNode _focusNode;

class _CommentFormState extends State<CommentForm> {
  GlobalKey<FormState> _key = new GlobalKey<FormState>();
  CommentFormResult res = new CommentFormResult();
  PostProvider _postProvider;
  bool _savable;

  TextEditingController _textController = new TextEditingController();

  @override
  void initState() {
    _textController.text = widget.text;
    _textController.selection =
        TextSelection.fromPosition(TextPosition(offset: widget.text.length));
    _focusNode = new FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.unFocus(_textController.text);
      }
    });
    _savable = widget.text.length > 0;
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    this._postProvider = context.read(postProvider(widget.post.id));
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _key,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: TextFormField(
                  autofocus: true,
                  focusNode: _focusNode,
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'コメント',
                    errorStyle: TextStyle(height: 0),
                    hintStyle: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w400),
                  maxLines: 4,
                  minLines: 1,
                  validator: (v) {
                    if (v.length > 0) {
                      return null;
                    } else {
                      return '';
                    }
                  },
                  onChanged: (String text) {
                    if (text.length > 0 && !_savable) {
                      setState(() {
                        _savable = true;
                      });
                    }
                    if (text.length == 0 && _savable) {
                      setState(() {
                        _savable = false;
                      });
                    }
                  },
                  onSaved: (comment) {
                    res.comment = comment;
                    _textController.text = '';
                  },
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 10),
              child: InkWell(
                child: Text(
                  '送信',
                  style: TextStyle(
                      color: _savable
                          ? Theme.of(context).accentColor
                          : Theme.of(context).disabledColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                onTap: _savable
                    ? () async {
                        await formSave();
                        _focusNode.unfocus();
                      }
                    : null,
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> formSave() async {
    final FormState form = this._key.currentState;
    if (form.validate()) {
      try {
        form.save();
        MyLoading.startLoading();
        await this._postProvider.addCommentToPost(res.comment);
        await LocalManager.updatePost(
            await context.read(authProvider).getUser(),
            _postProvider.getPost(),
            friendProviderName);
        await LocalManager.updatePost(
            await context.read(authProvider).getUser(),
            _postProvider.getPost(),
            challengeProviderName);
        await MyLoading.dismiss();
      } on RecordNotFoundException {
        await removePostFromAllProvider(widget.post, context);
        Home.pop();
        await MyLoading.dismiss();
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }
}
