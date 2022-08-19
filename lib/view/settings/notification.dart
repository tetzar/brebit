import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../library/notification.dart';
import '../home/navigation.dart';
import '../widgets/app-bar.dart';
import 'notification/push.dart';
import 'widgets/setting-tile.dart';

class NotificationSettings extends StatefulWidget {
  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: '通知'),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).primaryColor,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty('プッシュ通知', showPush),
                SettingProperty('デバイスの通知設定', showDevice)
                  ..arrow = false,
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showPush(WidgetRef ref, BuildContext ctx) async {
    Map<String, bool> notificationPermission =
        await MyNotification.getSetting();
    PushNotificationParam param = new PushNotificationParam(
        challenge: notificationPermission['challenge']!,
        information: notificationPermission['information']!,
        reply: notificationPermission['reply']!,
        friend: notificationPermission['friend']!);
    Home.push(MaterialPageRoute(
        builder: (BuildContext context) =>
            PushNotificationSetting(param: param)));
  }

  Future<void> showDevice(WidgetRef ref, BuildContext ctx) async {
    await MyNotification.setPermission();
  }
}
