import 'dart:ui';

import 'package:brebit/view/widgets/app-bar.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../provider/auth.dart';
import '../../../provider/home.dart';
import '../../../provider/posts.dart';
import '../../../route/route.dart';
import '../home/navigation.dart';
import '../timeline/posts.dart';
import '../widgets/back-button.dart';
import '../widgets/dialog.dart';
import 'account.dart';
import 'notification.dart';
import 'widgets/setting-tile.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: getMyAppBarTitle('設定', context),
        centerTitle: true,
        leading: MyBackButton(),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).primaryColor,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty('チャレンジ', showChallenge),
                SettingProperty('アカウント', showAccount),
                SettingProperty('通知', showNotification)
              ]),
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty('ヘルプ', showHelp)
                  ..arrow = false,
                SettingProperty('Brebitを評価する', showReview)
                  ..arrow = false,
                SettingProperty('Brebitについて', showAbout),
              ]),
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty('サインアウト', logout)
                  ..arrow = false,
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showNotification(WidgetRef ref, BuildContext ctx) async {
    Home.push(MaterialPageRoute(
        builder: (BuildContext context) => NotificationSettings()));
  }

  Future<void> showChallenge(WidgetRef ref, BuildContext ctx) async {
    Home.pushNamed('/settings/challenge');
  }

  Future<void> showAccount(WidgetRef ref, BuildContext ctx) async {
    List<CredentialProviders> providers = AuthProvider.getProviders();
    ref.read(accountSettingProvider.notifier).set(
        appleAuthorized: providers.contains(CredentialProviders.apple),
        googleAuthorized: providers.contains(CredentialProviders.google),
        passwordAuthorized: providers.contains(CredentialProviders.password));
    Home.pushNamed('/settings/account');
  }

  Future<void> showHelp(WidgetRef ref, BuildContext ctx) async {
    Uri _url = Uri.parse('https://www.instagram.com/brebitapp/');
    await canLaunchUrl(_url)
        ? await launchUrl(_url)
        : throw 'Could not launch $_url';
  }

  Future<void> showReview(WidgetRef ref, BuildContext ctx) async {}

  Future<void> showAbout(WidgetRef ref, BuildContext ctx) async {
    Home.pushNamed('/settings/about');
  }

  Future<void> logout(WidgetRef ref, BuildContext ctx) async {
    showDialog(
        context: ctx,
        builder: (context) {
          return MyDialog(
            title: Text(
              'サインアウト',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyText1?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
            body: Align(
              alignment: Alignment.center,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: '本当にBrebitから\n'
                      'サインアウトしますか？',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyText1?.color,
                      fontSize: 17,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ),
            action: () async {
              bool logoutSuccess =
                  await ref.read(authProvider.notifier).logout();
              ref.read(homeProvider.notifier).logout();
              ref.read(timelineProvider(friendProviderName).notifier).logout();
              ref
                  .read(timelineProvider(challengeProviderName).notifier)
                  .logout();
              if (logoutSuccess) {
                ApplicationRoutes.popUntil('/home');
                ApplicationRoutes.pushReplacementNamed('/title');
              } else {
                print('logout failed');
                throw Exception('logout failed');
              }
            },
            actionText: 'サインアウト',
          );
        });
  }
}
