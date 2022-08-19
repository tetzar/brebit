import 'package:brebit/library/exceptions.dart';
import 'package:brebit/model/comment.dart';
import 'package:brebit/view/timeline/post.dart';
import 'package:brebit/view/timeline/widget/comment-card.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../api/post.dart';
import '../../../model/post.dart';
import '../../../route/route.dart';
import '../widgets/app-bar.dart';
import '../widgets/back-button.dart';
import '../widgets/dialog.dart';
import '../widgets/text-field.dart';
import 'loading.dart';

enum ReportableType {
  comment,
  post,
}

class ReportView extends StatelessWidget {
  final dynamic reportable;

  ReportView(this.reportable);

  final Map<ReportableType, String> _appBarTitle = <ReportableType, String>{
    ReportableType.comment: 'コメントを報告',
    ReportableType.post: 'ポストを報告',
  };

  @override
  Widget build(BuildContext context) {
    ReportableType _type = ReportableType.comment;
    if (reportable is Post) {
      _type = ReportableType.post;
    }
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          titleText: _appBarTitle[_type]!,
          backButton: AppBarBackButton.none,
          actions: [MyBackButtonX()]),
      body: ReportViewContent(reportable),
    );
  }
}

class ReportViewContent extends ConsumerStatefulWidget {
  final dynamic reportable;

  ReportViewContent(this.reportable);

  @override
  _ReportViewContentState createState() => _ReportViewContentState();
}

enum ReportType { spam, aggressive, painful, none }

class _ReportViewContentState extends ConsumerState<ReportViewContent> {
  late ReportType _type;

  final Map<ReportableType, String> _question = <ReportableType, String>{
    ReportableType.comment: 'このコメントについて、問題の詳細を教えてください。',
    ReportableType.post: 'このポストについて、問題の詳細を教えてください。',
  };

  @override
  void initState() {
    _type = ReportType.none;
    super.initState();
  }

  String getBody() {
    switch (_type) {
      case ReportType.spam:
        return 'spam';
      case ReportType.aggressive:
        return 'aggressive';
      default:
        return 'painful';
    }
  }

  @override
  Widget build(BuildContext context) {
    ReportableType _reportableType = ReportableType.comment;
    if (widget.reportable is Post) {
      _reportableType = ReportableType.post;
    }
    return MyBottomFixedButton(
      label: '報告',
      enable: _type != ReportType.none,
      onTapped: () async {
        try {
          MyLoading.startLoading();
          await PostApi.report(widget.reportable, getBody());
          await MyLoading.dismiss();
          ApplicationRoutes.push(MaterialPageRoute(
              builder: (context) => ReportComplete(widget.reportable)));
        } on RecordNotFoundException {
          if (widget.reportable is Comment) {
            Comment comment = widget.reportable as Comment;
            removeCommentFromProvider(comment, ref);
          } else {
            Post post = widget.reportable as Post;
            await removePostFromAllProvider(post, ref);
          }
          await MyLoading.dismiss();
          ApplicationRoutes.pop(true);
        } catch (e) {
          await MyLoading.dismiss();
          MyErrorDialog.show(e);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: Theme.of(context).primaryColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _question[_reportableType]!,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w400),
            ),
            ReportCard(
                isSelected: _type == ReportType.spam,
                text: '不審な内容またはスパムである',
                onTap: () {
                  setState(() {
                    _type = ReportType.spam;
                  });
                }),
            ReportCard(
                isSelected: _type == ReportType.aggressive,
                text: '不適切または攻撃的な内容を含んでいる',
                onTap: () {
                  setState(() {
                    _type = ReportType.aggressive;
                  });
                }),
            ReportCard(
                isSelected: _type == ReportType.painful,
                text: '自傷行為または自殺の意思をほのめかしている',
                onTap: () {
                  setState(() {
                    _type = ReportType.painful;
                  });
                }),
          ],
        ),
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final bool isSelected;
  final String text;
  final void Function() onTap;

  ReportCard(
      {required this.isSelected, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(top: 16),
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor,
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 0),
              )
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
                width: 2)),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyText1
              ?.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

class ReportComplete extends StatelessWidget {
  final dynamic reportable;

  ReportComplete(this.reportable);

  final Map<ReportableType, String> _appBarTitle = <ReportableType, String>{
    ReportableType.comment: 'コメントを報告',
    ReportableType.post: 'ポストを報告',
  };

  @override
  Widget build(BuildContext context) {
    ReportableType _type = ReportableType.comment;
    if (reportable is Post) {
      _type = ReportableType.post;
    }
    return WillPopScope(
      onWillPop: () async {
        ApplicationRoutes.pop();
        ApplicationRoutes.pop(true);
        return false;
      },
      child: Scaffold(
        appBar: getMyAppBar(
            context: context,
            titleText: _appBarTitle[_type]!,
            backButton: AppBarBackButton.none,
            actions: [
              IconButton(
                  icon: Icon(Icons.check,
                      color: Theme.of(context).textTheme.bodyText1?.color),
                  onPressed: () {
                    ApplicationRoutes.pop();
                    ApplicationRoutes.pop(true);
                  })
            ]),
        body: Container(
          width: double.infinity,
          color: Theme.of(context).primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 64,
              ),
              Text(
                'ご報告ありがとうございます。',
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 24,
              ),
              Text(
                'アカウントの問題を\n確認でき次第対処します。',
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(fontSize: 15, fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}
