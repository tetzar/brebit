// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'api/auth.dart';
import 'library/cache.dart';
import 'library/messaging.dart';
import 'library/notification.dart';
import 'model/user.dart';
import 'provider/auth.dart';
import 'provider/home.dart';
import 'provider/notification.dart';
import 'route/route.dart';
import 'view/general/loading.dart';
import 'view/home/navigation.dart';
import 'view/start/introduction.dart';
import 'view/start/title.dart' as MyTitle;
import 'view/theme/theme.dart';

String? _initialRoute;
AuthUser? _user;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MyNotification.init();
  FirebaseMessaging.onBackgroundMessage(MyFirebaseMessaging.onBackGround);
  MyLoading.initialize();
  await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, //縦固定
  ]);
  // SharedPreferences pref = await SharedPreferences.getInstance();
  // await pref.clear();
  if (await isFirstStart()) {
    _initialRoute = '/introduction';
  } else {
    if (await isLoggedIn()) {
      _initialRoute = '/home';
    } else {
      _initialRoute = '/title';
    }
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      _initialRoute = '/';
    }

    FirebaseDynamicLinks.instance.onLink
        .listen((PendingDynamicLinkData dynamicLink) async {
      final Uri? deepLink = dynamicLink.link;
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (deepLink == null || firebaseUser == null) return;
      if (deepLink.queryParameters.containsKey('continueUrl')) {
        final Uri continueUrl =
            Uri.parse(deepLink.queryParameters['continueUrl']!);
        if (deepLink.queryParameters['mode'] == 'verifyEmail') {
          firebaseUser.reload();
          if (continueUrl.path == '/email-verifying') {
            if (!firebaseUser.emailVerified) {
              ApplicationRoutes.pushReplacementNamed('/email-verifying',
                  arguments: dynamicLink);
            }
            return;
          }
          if (continueUrl.path == '/email-set') {
            if (!firebaseUser.emailVerified) {
              ApplicationRoutes.pushReplacementNamed('/title');
            }
            return;
          }
        }
        if (deepLink.queryParameters['mode'] == 'resetPassword') {
          try {
            String? oobCode = deepLink.queryParameters['oobCode'];
            if (oobCode == null) throw Exception('oobCode is null');
            await FirebaseAuth.instance.verifyPasswordResetCode(oobCode);
            ApplicationRoutes.pushReplacementNamed('/password-reset/form',
                arguments: dynamicLink);
          } catch (e) {
            ApplicationRoutes.pushReplacementNamed('/title');
          }
        }
        ApplicationRoutes.pushReplacementNamed(continueUrl.path,
            arguments: dynamicLink);
        return;
      }
      ApplicationRoutes.pushReplacementNamed(deepLink.path);
    });
  }

  runApp(ProviderScope(child: MyApp()));
}

Future<bool> isFirstStart() async {
  // return true; // for introduction dev mode
  try {
    bool started = await LocalManager.getHasStarted();
    return !started;
    // return true;
  } catch (e) {
    print(e.toString());
    print('error occurred while getting whether this application has started');
    throw e;
  }
}

Future<bool> isLoggedIn() async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  User? _firebaseUser = _auth.currentUser;
  if (_firebaseUser == null) {
    print('firebase user null');
    return false;
  } else {
    try {
      List<CredentialProviders> credentials = AuthProvider.getProviders();
      if (!credentials.contains(CredentialProviders.apple) &&
          !credentials.contains(CredentialProviders.google) &&
          !credentials.contains(CredentialProviders.password) &&
          !_firebaseUser.emailVerified) {
        return false;
      }
      _user = await AuthApi.getUser();
      if (_user == null) {
        return false;
      }
      AuthUser.selfUser = _user;
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}

class MyApp extends ConsumerWidget {
  static Future<void> initialize(WidgetRef ref) async {
    await MyFirebaseMessaging.init();
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return;
    }
    List<CredentialProviders> providers = firebaseUser.providerData
        .map((userInfo) {
          return AuthProvider.getCredentialProviderFromId(userInfo.providerId);
        })
        .toList()
        .cast<CredentialProviders>();
    if (!providers.contains(CredentialProviders.google) &&
        !providers.contains(CredentialProviders.apple)) {
      if (!providers.contains(CredentialProviders.password) ||
          !firebaseUser.emailVerified) {
        _initialRoute = '/title';
        return;
      }
    }
    AuthUser user = await ref.read(authProvider.notifier).getUser();
    AuthUser.selfUser = user;
    Map<String, dynamic>? result =
        await ref.read(homeProvider.notifier).getHome(user);
    if (result != null) {
      ref.read(notificationProvider.notifier).unreadCount =
          result['notificationCount'];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AuthUser? user = _user;
    if (user != null) {
      ref.read(authProvider.notifier).setUser(user);
    }
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Brebit',
        initialRoute: '/splash',
        onGenerateRoute: ApplicationRoutes.generateRoute,
        navigatorKey: ApplicationRoutes.materialKey,
        builder: EasyLoading.init(),
        theme: BrightThemeData.getThemeData(context));
  }
}

class Splash extends ConsumerStatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends ConsumerState<Splash> {
  @override
  void initState() {
    MyApp.initialize(ref).then((_) {
      Navigator.pushReplacement(
          context,
          new PageRouteBuilder(
              settings: RouteSettings(name: _initialRoute ?? '/title'),
              pageBuilder: (BuildContext context, _, __) {
                switch (_initialRoute) {
                  case '/home':
                    return Home(null);
                  case '/introduction':
                    return Introduction();
                  default:
                    return MyTitle.Title();
                }
              },
              transitionDuration: Duration(milliseconds: 1000),
              transitionsBuilder:
                  (_, Animation<double> animation, __, Widget child) {
                return new FadeTransition(opacity: animation, child: child);
              }));
    }).onError((error, stackTrace) {
      Navigator.pushReplacement(
          context,
          new PageRouteBuilder(
              settings: RouteSettings(name: '/title'),
              pageBuilder: (BuildContext context, _, __) {
                return MyTitle.Title();
              },
              transitionDuration: Duration(milliseconds: 1000),
              transitionsBuilder:
                  (_, Animation<double> animation, __, Widget child) {
                return new FadeTransition(opacity: animation, child: child);
              }));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Center(
        child: SvgPicture.asset(
          'assets/splash/logo.svg',
          width: 375,
          height: 120,
        ),
      ),
    );
  }
}
