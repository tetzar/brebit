import '../../../../library/notification.dart';
import '../widgets/setting-tile.dart';
import '../../widgets/app-bar.dart';
import 'package:flutter/material.dart';

class PushNotificationParam {
  bool challenge;
  bool reply;
  bool friend;
  bool information;
}

class PushNotificationSetting extends StatefulWidget {
  final PushNotificationParam param;

  PushNotificationSetting({@required this.param});

  @override
  _PushNotificationSettingState createState() =>
      _PushNotificationSettingState();
}

class _PushNotificationSettingState extends State<PushNotificationSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'プッシュ通知'),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).primaryColor,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              NotificationSettingListTileBox(
                  properties: <NotificationSettingProperty>[
                    NotificationSettingProperty()
                      ..name = '目標日数の達成'
                      ..enable = widget.param.challenge
                      ..onSwitch = (s) async {
                        await onChallengeChange(s);
                        return;
                      },
                    NotificationSettingProperty()
                      ..name = 'リプライ'
                      ..enable = widget.param.reply
                      ..onSwitch = (s) async {
                        await onReplyChange(s);
                        return;
                      },
                    NotificationSettingProperty()
                      ..name = 'フレンドリクエスト'
                      ..enable = widget.param.friend
                      ..onSwitch = (s) async {
                        await onFriendChange(s);
                        return;
                      },
                    NotificationSettingProperty()
                      ..name = 'Brebitからのお知らせ'
                      ..enable = widget.param.information
                      ..onSwitch = (s) async {
                        await onInformationChange(s);
                        return;
                      },
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onChallengeChange(bool s) async {
    await MyNotification.setSetting(
      s,
      'challenge',
    );
  }

  Future<void> onReplyChange(bool s) async {
    await MyNotification.setSetting(
      s,
      'reply',
    );
  }

  Future<void> onFriendChange(bool s) async {
    await MyNotification.setSetting(
      s,
      'friend',
    );
  }

  Future<void> onInformationChange(bool s) async {
    await MyNotification.setSetting(
      s,
      'information',
    );
  }
}
