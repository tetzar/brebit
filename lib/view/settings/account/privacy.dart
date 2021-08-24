import '../../../../provider/auth.dart';
import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../home/navigation.dart';
import '../widgets/setting-tile.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PrivacySettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'プライバシー'),
      body: PrivacySettingContent(),
    );
  }
}

class PrivacySettingContent extends StatefulWidget {
  @override
  _PrivacySettingContentState createState() => _PrivacySettingContentState();
}

class _PrivacySettingContentState extends State<PrivacySettingContent> {
  @override
  Widget build(BuildContext context) {
    bool hidden = context.read(authProvider.state).user.isHidden();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          children: [
            PrivacySettingListTileBox(properties: <PrivacySettingProperty>[
              PrivacySettingProperty()
                ..name = 'ポストとステータス'
                ..hidden = hidden
                ..func = changeOpen,
            ]),
            SettingListTileBox(properties: <SettingProperty>[
              SettingProperty()
                ..name = 'ブロック中'
                ..func = showBlocking,
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> changeOpen(BuildContext context) async {
    bool hidden = context.read(authProvider.state).user.isHidden();
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (context) {
          return MyDialog(
            title: Text(
              hidden ? '公開' : '非公開',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            body: Text(
              'フレンド以外のユーザーが\nポストやステータスを確認できます',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            actionText: hidden ? '公開' : '非公開',
            action: () async {
              ApplicationRoutes.pop();
              try {
                MyLoading.startLoading();
                await context.read(authProvider).switchOpened(hidden);
                await MyLoading.dismiss();
                setState(() {});
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme.of(context).accentColor,
          );
        });
  }

  Future<void> showBlocking(BuildContext context) async {
    Home.pushNamed('/settings/privacy/blocking');
  }
}
