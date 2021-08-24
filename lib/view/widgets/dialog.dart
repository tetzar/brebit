import 'dart:developer';

import '../../../route/route.dart';
import 'package:flutter/material.dart';

class MyDialog extends StatelessWidget {
  final Widget title;
  final Widget body;
  final String actionText;
  final Function action;
  final Color actionColor;
  final Color disableColor;
  final bool onlyAction;

  MyDialog(
      {@required this.title,
      @required this.body,
      @required this.actionText,
      @required this.action,
      this.actionColor,
      this.onlyAction = false,
      this.disableColor});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width > 346
        ? 312
        : MediaQuery.of(context).size.width * 0.9;
    return AlertDialog(
      contentPadding: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30))),
      content: Container(
        width: width,
        child: Wrap(
          children: [
            Container(
              padding:
                  EdgeInsets.only(top: 20, bottom: 16, left: 16, right: 16),
              child: Column(
                children: [
                  Center(
                    child: title,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: body,
                    ),
                  )
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Theme.of(context).primaryColorDark,
                          width: 1))),
              height: 67,
              child: onlyAction
                  ? InkWell(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      onTap: () async {
                        await action();
                      },
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          actionText,
                          style: TextStyle(
                            color: actionColor ?? Theme.of(context).accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              child: Center(
                                child: Text(
                                  'キャンセル',
                                  style: TextStyle(
                                    color: disableColor ??
                                        Theme.of(context).disabledColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              await action();
                            },
                            child: Container(
                              child: Center(
                                child: Text(
                                  actionText,
                                  style: TextStyle(
                                    color: actionColor ??
                                        Theme.of(context).accentColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
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
}

class MyErrorDialog extends StatelessWidget {
  final Function onConfirm;

  MyErrorDialog({this.onConfirm});

  static void show(var e, {Function onConfirm}) {
    assert (e is Error || e is Exception);
    print('=======================================');
    print('Error');
    print('=======================================');
    log('error', error: e);
    debugDumpRenderTree();
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (context) {
          return MyErrorDialog(onConfirm: onConfirm);
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyDialog(
      title: Text(
        '予期せぬエラーが発生したため\n処理を完了できませんでした',
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyText1
            .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      body: SizedBox(
        height: 0,
      ),
      actionText: '戻る',
      action: onConfirm ?? () {
        ApplicationRoutes.pop();
      },
      actionColor: Theme.of(context).disabledColor,
      onlyAction: true,
    );
  }
}
