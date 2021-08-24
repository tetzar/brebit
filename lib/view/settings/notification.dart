import '../../../library/notification.dart';
import '../home/navigation.dart';
import 'notification/push.dart';
import '../widgets/app-bar.dart';
import 'package:flutter/material.dart';

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
                SettingProperty()
                  ..name = 'プッシュ通知'
                  ..func = showPush,
                SettingProperty()
                  ..name = 'デバイスの通知設定'
                  ..func = showDevice
                  ..arrow = false,
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showPush(BuildContext ctx) async {
    PushNotificationParam param = new PushNotificationParam();
    Map<String, bool> notificationPermission =
        await MyNotification.getSetting();
    param.challenge = notificationPermission['challenge'];
    param.information = notificationPermission['information'];
    param.reply = notificationPermission['reply'];
    param.friend = notificationPermission['friend'];
    Home.navKey.currentState.push(MaterialPageRoute(
        builder: (BuildContext context) =>
            PushNotificationSetting(param: param)));
  }

  Future<void> showDevice(BuildContext ctx) async {
    await MyNotification.setPermission();
  }
}
