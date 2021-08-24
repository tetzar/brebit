import 'dart:ui';

import '../../../provider/auth.dart';
import '../../../provider/posts.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../home/navigation.dart';
import 'notification.dart';
import '../timeline/posts.dart';
import '../widgets/back-button.dart';
import '../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'account.dart';
import 'widgets/setting-tile.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
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
                SettingProperty()
                  ..name = 'チャレンジ'
                  ..func = showChallenge,
                SettingProperty()
                  ..name = 'アカウント'
                  ..func = showAccount,
                SettingProperty()
                  ..name = '通知'
                  ..func = showNotification,
              ]),
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty()
                  ..name = 'ヘルプ'
                  ..func = showHelp
                  ..arrow = false,
                SettingProperty()
                  ..name = 'Brebitを評価する'
                  ..func = showReview
                  ..arrow = false,
                SettingProperty()
                  ..name = 'Brebitについて'
                  ..func = showAbout,
              ]),
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty()
                  ..name = 'サインアウト'
                  ..func = logout
                  ..arrow = false,
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showNotification(BuildContext ctx) async {
    Home.navKey.currentState.push(MaterialPageRoute(
        builder: (BuildContext context) => NotificationSettings()));
  }

  Future<void> showChallenge(BuildContext ctx) async {
    Home.pushNamed('/settings/challenge');
  }

  Future<void> showAccount(BuildContext ctx) async {
    List<CredentialProviders> providers = AuthProvider.getProviders();
    ctx.read(accountSettingProvider).set(
      appleAuthorized:providers.contains(CredentialProviders.apple),
      googleAuthorized: providers.contains(CredentialProviders.google),
      passwordAuthorized: providers.contains(CredentialProviders.password)
    );
    Home.pushNamed('/settings/account');
  }

  Future<void> showHelp(BuildContext ctx) async {
    String _url = 'https://www.instagram.com/brebitjp/';
    await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';
  }

  Future<void> showReview(BuildContext ctx) async {}

  Future<void> showAbout(BuildContext ctx) async {
    Home.pushNamed('/settings/about');
  }

  Future<void> logout(BuildContext ctx) async {
    showDialog(
        context: ctx,
        builder: (context) {
          return MyDialog(
            title: Text(
              'サインアウト',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyText1.color,
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
                      color: Theme.of(context).textTheme.bodyText1.color,
                      fontSize: 17,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ),
            action: () async {
              bool logoutSuccess = await ctx.read(authProvider).logout();
              ctx.read(homeProvider).logout();
              ctx.read(timelineProvider(friendProviderName)).logout();
              ctx.read(timelineProvider(challengeProviderName)).logout();
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
