import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../provider/auth.dart';
import '../../../provider/home.dart';
import '../../../provider/posts.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../home/navigation.dart';
import '../timeline/posts.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';
import 'widgets/setting-tile.dart';

class AccountSettingProviderState {
  bool googleAuthorized;
  bool appleAuthorized;
  bool passwordAuthorized;

  AccountSettingProviderState(
      {@required this.googleAuthorized,
      @required this.appleAuthorized,
      @required this.passwordAuthorized});
}

class AccountSettingProvider
    extends StateNotifier<AccountSettingProviderState> {
  AccountSettingProvider(AccountSettingProviderState state) : super(state);

  bool get googleAuthorized {
    return this.state.googleAuthorized ?? false;
  }

  bool get appleAuthorized {
    return this.state.appleAuthorized ?? false;
  }

  bool get passwordAuthorized {
    return this.state.passwordAuthorized ?? false;
  }

  void setGoogleAuthorized(bool s) {
    if (state.googleAuthorized != s) {
      state = AccountSettingProviderState(
        appleAuthorized: state.appleAuthorized,
        googleAuthorized: s,
        passwordAuthorized: state.passwordAuthorized,
      );
    }
  }

  void setAppleAuthorized(bool s) {
    if (state.appleAuthorized != s) {
      state = AccountSettingProviderState(
        googleAuthorized: state.googleAuthorized,
        appleAuthorized: s,
        passwordAuthorized: state.passwordAuthorized,
      );
    }
  }

  void setPasswordAuthorized(bool s) {
    if (state.appleAuthorized != s) {
      state = AccountSettingProviderState(
        googleAuthorized: state.googleAuthorized,
        appleAuthorized: state.appleAuthorized,
        passwordAuthorized: s,
      );
    }
  }

  void set(
      {bool appleAuthorized, bool googleAuthorized, bool passwordAuthorized}) {
    state = new AccountSettingProviderState(
        googleAuthorized: googleAuthorized ?? state.googleAuthorized,
        appleAuthorized: appleAuthorized ?? state.appleAuthorized,
        passwordAuthorized: passwordAuthorized ?? state.passwordAuthorized);
  }
}

final accountSettingProvider = StateNotifierProvider((res) =>
    AccountSettingProvider(AccountSettingProviderState(
        googleAuthorized: null,
        appleAuthorized: null,
        passwordAuthorized: null)));

class AccountSettings extends HookWidget {
  @override
  Widget build(BuildContext context) {
    AccountSettingProviderState accountSettingProviderState =
        useProvider(accountSettingProvider.state);
    List<SettingProperty> emailSettings = [
      SettingProperty()
        ..name = 'メールアドレス'
        ..func = showEmail,
    ];
    if (context.read(accountSettingProvider).passwordAuthorized) {
      emailSettings.add(
        SettingProperty()
          ..name = 'パスワード'
          ..func = showPassword,
      );
    }
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: 'アカウント'),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).primaryColor,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty()
                  ..name = 'ユーザーネーム'
                  ..func = showUserName,
                SettingProperty()
                  ..name = 'プロフィール'
                  ..func = showProfile,
              ]),
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty()
                  ..name = 'プライバシー'
                  ..func = showPrivacy,
              ]),
              SettingListTileBox(properties: emailSettings),
              AuthSettingListTileBox(properties: <AuthSettingProperty>[
                AuthSettingProperty()
                  ..name = 'Google'
                  ..authorized = accountSettingProviderState.googleAuthorized
                  ..func = linkGoogle,
                AuthSettingProperty()
                  ..name = 'Apple'
                  ..authorized = accountSettingProviderState.appleAuthorized
                  ..func = linkApple,
              ]),
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty()
                  ..name = 'アカウント削除'
                  ..func = removeAccount
                  ..arrow = false,
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showUserName(BuildContext ctx) async {
    ApplicationRoutes.pushNamed('/settings/account/customId');
  }

  Future<void> showProfile(BuildContext ctx) async {
    Home.pushNamed('/settings/account/profile');
  }

  Future<void> showEmail(BuildContext ctx) async {
    ApplicationRoutes.pushNamed('/settings/account/email');
  }

  Future<void> showPassword(BuildContext ctx) async {
    ApplicationRoutes.pushNamed('/settings/account/password');
  }

  Future<void> showPrivacy(BuildContext ctx) async {
    Home.pushNamed('/settings/privacy');
  }

  Future<void> linkGoogle(BuildContext ctx) async {
    List<CredentialProviders> credential = AuthProvider.getProviders();
    bool googleSignedIn = credential.contains(CredentialProviders.google);
    if (googleSignedIn) {
      if (credential.length == 1) {
        showDialog(
            context: ApplicationRoutes.materialKey.currentContext,
            builder: (context) {
              return MyDialog(
                  onlyAction: true,
                  title: Text(
                    'メールアドレスの登録を行ってから\nGoogleとの連携を\n解除してください？',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  body: SizedBox(
                    height: 0,
                  ),
                  actionText: 'OK',
                  action: () async {
                    ApplicationRoutes.pop();
                  });
            });
        return;
      }
      showDialog(
          context: ApplicationRoutes.materialKey.currentContext,
          builder: (context) {
            return MyDialog(
                title: Text(
                  'Googleとの連携を解除しますか？',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                body: SizedBox(
                  height: 0,
                ),
                actionText: '解除する',
                action: () async {
                  ApplicationRoutes.pop();
                  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
                  await _firebaseAuth.currentUser.unlink(
                      AuthProvider.getProviderIdFromCredentialProvider(
                          CredentialProviders.google));
                  await GoogleSignIn().signOut();
                  bool googleSignedIn = AuthProvider.getProviders()
                      .contains(CredentialProviders.google);
                  ctx
                      .read(accountSettingProvider)
                      .setGoogleAuthorized(googleSignedIn);
                });
          });
    } else {
      showDialog(
          context: ApplicationRoutes.materialKey.currentContext,
          builder: (context) {
            return MyDialog(
                title: Text(
                  'Googleと連携しますか？',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                body: SizedBox(
                  height: 0,
                ),
                actionText: '連携する',
                action: () async {
                  ApplicationRoutes.pop();
                  // Trigger the Google Authentication flow.
                  final GoogleSignInAccount googleUser =
                      await GoogleSignIn().signIn();
                  // Obtain the auth details from the request.
                  final GoogleSignInAuthentication googleAuth =
                      await googleUser.authentication;
                  // Create a new credential.
                  final GoogleAuthCredential googleCredential =
                      GoogleAuthProvider.credential(
                    accessToken: googleAuth.accessToken,
                    idToken: googleAuth.idToken,
                  );
                  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
                  await _firebaseAuth.currentUser
                      .linkWithCredential(googleCredential);

                  bool googleSignedIn = AuthProvider.getProviders()
                      .contains(CredentialProviders.google);
                  ctx
                      .read(accountSettingProvider)
                      .setGoogleAuthorized(googleSignedIn);
                });
          });
    }
  }

  Future<void> linkApple(BuildContext ctx) async {
    List<CredentialProviders> credential = AuthProvider.getProviders();
    bool appleSignedIn = credential.contains(CredentialProviders.apple);
    if (appleSignedIn) {
      if (credential.length == 1) {
        showDialog(
            context: ApplicationRoutes.materialKey.currentContext,
            builder: (context) {
              return MyDialog(
                  onlyAction: true,
                  title: Text(
                    'メールアドレスの登録を行ってから\nApple IDとの連携を\n解除してください？',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  body: SizedBox(
                    height: 0,
                  ),
                  actionText: 'OK',
                  action: () async {
                    ApplicationRoutes.pop();
                  });
            });
        return;
      }
      showDialog(
          context: ApplicationRoutes.materialKey.currentContext,
          builder: (context) {
            return MyDialog(
                title: Text(
                  'Apple IDとの連携を解除しますか？',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                body: SizedBox(
                  height: 0,
                ),
                actionText: '解除する',
                action: () async {
                  print('unlink from apple id');
                });
          });
    } else {
      showDialog(
          context: ApplicationRoutes.materialKey.currentContext,
          builder: (context) {
            return MyDialog(
                title: Text(
                  'Apple IDと連携しますか？',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                body: SizedBox(
                  height: 0,
                ),
                actionText: '連携する',
                action: () async {
                  print('link with apple id');
                });
          });
    }
  }

  Future<void> removeAccount(BuildContext ctx) async {
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (context) {
          return MyDialog(
            title: Text(
              'Brebitのアカウントを\n削除しますか？',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            body: SizedBox(
              height: 0,
            ),
            actionText: '削除',
            actionColor: Theme.of(context).accentTextTheme.subtitle1.color,
            action: () async {
              ApplicationRoutes.pop();
              try {
                MyLoading.startLoading();
                await context.read(authProvider).deleteAccount();
                ctx.read(homeProvider).logout();
                ctx.read(timelineProvider(friendProviderName)).logout();
                ctx.read(timelineProvider(challengeProviderName)).logout();
                await MyLoading.dismiss();
                ApplicationRoutes.popUntil('/home');
                ApplicationRoutes.pushReplacementNamed('/title');
              } catch (e) {
                MyErrorDialog.show(e);
              }
            },
          );
        });
  }
}
