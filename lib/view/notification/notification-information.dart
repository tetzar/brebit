import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/notification.dart';
import '../../../model/notification.dart';
import '../widgets/app-bar.dart';
import '../widgets/back-button.dart';

class InformationNotification extends StatelessWidget {
  final UserNotification notification;

  InformationNotification(this.notification);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          backButton: AppBarBackButton.none,
          actions: [MyBackButtonX()]),
      body: FutureBuilder<String?>(
          future: getInformation(notification.getBody()['information_id']),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              if (snapshot.error is TimeoutException) {
                return Center(
                  child: Text(
                    "サーバーに接続できませんでした",
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                );
              } else {
                return Center(
                  child: Text(
                    "予期せぬエラーが発生しました",
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                );
              }
            }
            if (snapshot.connectionState != ConnectionState.done ||
                !snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return InformationBody(snapshot.data);
          }),
    );
  }

  Future<String?> getInformation(int informationId) async {
    return await NotificationApi.getInformationNotificationBody(informationId);
  }
}

class InformationBody extends StatelessWidget {
  final String? body;

  InformationBody(this.body);

  @override
  Widget build(BuildContext context) {
    // String? body = this.body;
    return SingleChildScrollView(
      child: Container(
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.all(24),
        // child: body != null ?  HtmlWidget(
        //   body,
        //   onTapUrl: (url) async {
        //     if (await canLaunchUrl(Uri.parse(url))) {
        //       await launchUrl(Uri.parse(url));
        //       return true;
        //     } else {
        //       print('cannot launch');
        //     }
        //     return false;
        //   },
        // customStylesBuilder: (element) {
        //   Map<String, Map<String, String>> style = {
        //     '.mt-4': {'margin': '4px'},
        //   '.mt-8': Style(margin: EdgeInsets.only(top: 8)),
        //   '.mt-12': Style(margin: EdgeInsets.only(top: 12)),
        //   '.mt-16': Style(margin: EdgeInsets.only(top: 16)),
        //   '.mt-20': Style(margin: EdgeInsets.only(top: 20)),
        //   '.mt-24': Style(margin: EdgeInsets.only(top: 24)),
        //   '.mb-4': Style(margin: EdgeInsets.only(top: 4)),
        //   '.mb-8': Style(margin: EdgeInsets.only(top: 8)),
        //   '.mb-12': Style(margin: EdgeInsets.only(top: 12)),
        //   '.mb-16': Style(margin: EdgeInsets.only(top: 16)),
        //   '.mb-20': Style(margin: EdgeInsets.only(top: 20)),
        //   '.mb-24': Style(margin: EdgeInsets.only(top: 24)),
        //   '.w-100': Style(width: double.infinity),
        //   '.horizontal-align-center': Style(
        //   textAlign: TextAlign.center,
        //   ),
        //   'a': Style(
        //   textDecoration: TextDecoration.underline,
        //   color: Theme.of(context).colorScheme.secondary),
        //   'li': Style(padding: EdgeInsets.all(0))}
        // },
        // ) :
        child: Container(),
      ),
    );
  }
}
