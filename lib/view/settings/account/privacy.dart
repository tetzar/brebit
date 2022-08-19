import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../provider/auth.dart';
import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../home/navigation.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../widgets/setting-tile.dart';

class PrivacySettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'プライバシー'),
      body: PrivacySettingContent(),
    );
  }
}

class PrivacySettingContent extends ConsumerStatefulWidget {
  @override
  _PrivacySettingContentState createState() => _PrivacySettingContentState();
}

class _PrivacySettingContentState extends ConsumerState<PrivacySettingContent> {
  @override
  Widget build(BuildContext context) {
    bool hidden = ref.read(authProvider.notifier).user?.isHidden() ?? true;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          children: [
            PrivacySettingListTileBox(properties: <PrivacySettingProperty>[
              PrivacySettingProperty(
                hidden,
                'ポストとステータス',
                changeOpen,
              )
            ]),
            SettingListTileBox(properties: <SettingProperty>[
              SettingProperty('ブロック中', showBlocking)
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> changeOpen(BuildContext context) async {
    bool hidden = ref.read(authProvider.notifier).user?.isHidden() ?? true;
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext ?? context,
        builder: (context) {
          return MyDialog(
            title: Text(
              hidden ? '公開' : '非公開',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
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
                await ref.read(authProvider.notifier).switchOpened(hidden);
                await MyLoading.dismiss();
                setState(() {});
              } catch (e) {
                await MyLoading.dismiss();
                MyErrorDialog.show(e);
              }
            },
            actionColor: Theme.of(context).colorScheme.secondary,
          );
        });
  }

  Future<void> showBlocking(WidgetRef ref, BuildContext context) async {
    Home.pushNamed('/settings/privacy/blocking');
  }
}
