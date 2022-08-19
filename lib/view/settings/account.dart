import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  bool? googleAuthorized;
  bool? appleAuthorized;
  bool? passwordAuthorized;

  AccountSettingProviderState(
      {this.googleAuthorized, this.appleAuthorized, this.passwordAuthorized});
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
      {bool? appleAuthorized,
      bool? googleAuthorized,
      bool? passwordAuthorized}) {
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

class AccountSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accountSettingProvider);
    List<SettingProperty> emailSettings = [
      SettingProperty(
          'メールアドレス',showEmail
      )
    ];
    if (ref.read(accountSettingProvider.notifier).passwordAuthorized) {
      emailSettings.add(
        SettingProperty('パスワード', showPassword)
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
                SettingProperty('ユーザーネーム', showUserName),
                SettingProperty('プロフィール', showProfile)
              ]),
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty('プライバシー', showPrivacy),
              ]),
              SettingListTileBox(properties: emailSettings),
              AuthSettingListTileBox(properties: <AuthSettingProperty>[
                AuthSettingProperty(ref.read(accountSettingProvider.notifier).googleAuthorized,
                    'Google', linkGoogle),
                AuthSettingProperty(
                    ref.read(accountSettingProvider.notifier).appleAuthorized,
                    'Apple', linkApple
                )
              ]),
              SettingListTileBox(properties: <SettingProperty>[
                SettingProperty('アカウント削除'
                , removeAccount)
                  ..arrow = false,
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showUserName(WidgetRef ref, BuildContext ctx) async {
    ApplicationRoutes.pushNamed('/settings/account/customId');
  }

  Future<void> showProfile(WidgetRef ref, BuildContext ctx) async {
    Home.pushNamed('/settings/account/profile');
  }

  Future<void> showEmail(WidgetRef ref, BuildContext ctx) async {
    ApplicationRoutes.pushNamed('/settings/account/email');
  }

  Future<void> showPassword(WidgetRef ref, BuildContext ctx) async {
    ApplicationRoutes.pushNamed('/settings/account/password');
  }

  Future<void> showPrivacy(WidgetRef ref, BuildContext ctx) async {
    Home.pushNamed('/settings/privacy');
  }

  Future<void> linkGoogle(WidgetRef ref, BuildContext ctx) async {
    List<CredentialProviders> credential = AuthProvider.getProviders();
    bool googleSignedIn = credential.contains(CredentialProviders.google);
    if (googleSignedIn) {
      if (credential.length == 1) {
        showDialog(
            context: ApplicationRoutes.materialKey.currentContext ?? ctx,
            builder: (context) {
              return MyDialog(
                  onlyAction: true,
                  title: Text(
                    'メールアドレスの登録を行ってから\nGoogleとの連携を\n解除してください？',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
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
          context: ApplicationRoutes.materialKey.currentContext ?? ctx,
          builder: (context) {
            return MyDialog(
                title: Text(
                  'Googleとの連携を解除しますか？',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                body: SizedBox(
                  height: 0,
                ),
                actionText: '解除する',
                action: () async {
                  ApplicationRoutes.pop();
                  final User? firebaseUser = FirebaseAuth.instance.currentUser;
                  if (firebaseUser == null) return;
                  await firebaseUser.unlink(
                      AuthProvider.getProviderIdFromCredentialProvider(
                          CredentialProviders.google)!);
                  await GoogleSignIn().signOut();
                  bool googleSignedIn = AuthProvider.getProviders()
                      .contains(CredentialProviders.google);
                  ref
                      .read(accountSettingProvider.notifier)
                      .setGoogleAuthorized(googleSignedIn);
                });
          });
    } else {
      showDialog(
          context: ApplicationRoutes.materialKey.currentContext ?? ctx,
          builder: (context) {
            return MyDialog(
                title: Text(
                  'Googleと連携しますか？',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                body: SizedBox(
                  height: 0,
                ),
                actionText: '連携する',
                action: () async {
                  ApplicationRoutes.pop();
                  // Trigger the Google Authentication flow.
                  try {
                    final GoogleSignInAccount? googleUser =
                        await GoogleSignIn().signIn();
                    if (googleUser == null)
                      throw Exception('google login failed');
                    // Obtain the auth details from the request.
                    final GoogleSignInAuthentication googleAuth =
                        await googleUser.authentication;
                    // Create a new credential.
                    final OAuthCredential googleCredential =
                        GoogleAuthProvider.credential(
                      accessToken: googleAuth.accessToken,
                      idToken: googleAuth.idToken,
                    );
                    final User? firebaseUser =
                        FirebaseAuth.instance.currentUser;
                    if (firebaseUser == null)
                      throw Exception('firebase user not found');
                    await firebaseUser.linkWithCredential(googleCredential);
                    bool googleSignedIn = AuthProvider.getProviders()
                        .contains(CredentialProviders.google);
                    ref
                        .read(accountSettingProvider.notifier)
                        .setGoogleAuthorized(googleSignedIn);
                  } catch (e) {
                    MyErrorDialog.show(e);
                  }
                });
          });
    }
  }

  Future<void> linkApple(WidgetRef ref, BuildContext ctx) async {
    List<CredentialProviders> credential = AuthProvider.getProviders();
    bool appleSignedIn = credential.contains(CredentialProviders.apple);
    if (appleSignedIn) {
      if (credential.length == 1) {
        showDialog(
            context: ApplicationRoutes.materialKey.currentContext ?? ctx,
            builder: (context) {
              return MyDialog(
                  onlyAction: true,
                  title: Text(
                    'メールアドレスの登録を行ってから\nApple IDとの連携を\n解除してください？',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
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
          context: ApplicationRoutes.materialKey.currentContext ?? ctx,
          builder: (context) {
            return MyDialog(
                title: Text(
                  'Apple IDとの連携を解除しますか？',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
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
          context: ApplicationRoutes.materialKey.currentContext ?? ctx,
          builder: (context) {
            return MyDialog(
                title: Text(
                  'Apple IDと連携しますか？',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
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

  Future<void> removeAccount(WidgetRef ref, BuildContext ctx) async {
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext ?? ctx,
        builder: (context) {
          return MyDialog(
            title: Text(
              'Brebitのアカウントを\n削除しますか？',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            body: SizedBox(
              height: 0,
            ),
            actionText: '削除',
            actionColor: Theme.of(context).primaryTextTheme.subtitle1?.color,
            action: () async {
              ApplicationRoutes.pop();
              try {
                MyLoading.startLoading();
                await ref.read(authProvider.notifier).deleteAccount();
                ref.read(homeProvider.notifier).logout();
                ref
                    .read(timelineProvider(friendProviderName).notifier)
                    .logout();
                ref
                    .read(timelineProvider(challengeProviderName).notifier)
                    .logout();
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
