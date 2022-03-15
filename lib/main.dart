// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'library/messaging.dart';
import 'library/notification.dart';
import 'provider/auth.dart';
import 'provider/home.dart';
import 'provider/notification.dart';
import 'route/route.dart';
import 'view/general/loading.dart';
import 'view/home/navigation.dart';
import 'view/start/introduction.dart';
import 'view/start/title.dart' as MyTitle;
import 'view/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'library/cache.dart';
import 'model/user.dart';
import 'network/auth.dart';

String _initialRoute;
AuthUser _user;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MyNotification.init();
  FirebaseMessaging.onBackgroundMessage(MyFirebaseMessaging.onBackGround);
  MyLoading.initialize();
  await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,//縦固定
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
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;
    if (deepLink != null) {
      _initialRoute = '/';
    }

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          final Uri deepLink = dynamicLink?.link;
          if (deepLink.queryParameters.containsKey('continueUrl')) {
            final Uri continueUrl =
            Uri.parse(deepLink.queryParameters['continueUrl']);
            if (deepLink.queryParameters['mode'] == 'verifyEmail') {
              FirebaseAuth.instance.currentUser.reload();
              if (continueUrl.path == '/email-verifying') {
                if (!FirebaseAuth.instance.currentUser.emailVerified) {
                  ApplicationRoutes.pushReplacementNamed('/email-verifying', arguments: dynamicLink);
                }
                return;
              }
              if (continueUrl.path == '/email-set') {
                if (!FirebaseAuth.instance.currentUser.emailVerified) {
                  ApplicationRoutes.pushReplacementNamed('/title');
                }
                return;
              }
            }
            if (deepLink.queryParameters['mode'] == 'resetPassword') {
              try {
                await FirebaseAuth.instance
                    .verifyPasswordResetCode(deepLink.queryParameters['oobCode']);
                ApplicationRoutes.pushReplacementNamed('/password-reset/form',
                    arguments: dynamicLink);
              } catch (e) {
                ApplicationRoutes.pushReplacementNamed('/title');
              }
            }
            ApplicationRoutes.pushReplacementNamed(continueUrl.path, arguments: dynamicLink);
            return;
          }
          if (deepLink != null) {
            ApplicationRoutes.pushReplacementNamed(deepLink.path);
          }
        }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });
  }

  runApp(ProviderScope(child: MyApp()));
}

Future<bool> isFirstStart() async {
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
  User _firebaseUser = _auth.currentUser;
  if (_firebaseUser == null) {
    return false;
  } else {
    try {
      List<CredentialProviders> credentials = AuthProvider.getProviders();
      if (!credentials.contains(CredentialProviders.apple) &&
          !credentials.contains(CredentialProviders.google) &&
          credentials.contains(CredentialProviders.password) &&
          !FirebaseAuth.instance.currentUser.emailVerified
      ) {
        return false;
      }
      _user = await AuthApi.getUser();
      if (_user == null) {
        return false;
      }
      AuthUser.selfUser = _user;
      return true;
    } catch (e) {
      return false;
    }
  }
}

class MyApp extends StatelessWidget {
  static Future<void> initialize(BuildContext context) async {
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
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }
    List<CredentialProviders> providers = FirebaseAuth
        .instance.currentUser.providerData
        .map((userInfo) {
          return AuthProvider.getCredentialProviderFromId(userInfo.providerId);
        })
        .toList()
        .cast<CredentialProviders>();
    if (!providers.contains(CredentialProviders.google) &&
        !providers.contains(CredentialProviders.apple)) {
      if (!providers.contains(CredentialProviders.password) ||
          !FirebaseAuth.instance.currentUser.emailVerified) {
        _initialRoute = '/title';
        return;
      }
    }
    AuthUser user = await context.read(authProvider).getUser();
    AuthUser.selfUser = user;
    Map<String, dynamic> result =
        await context.read(homeProvider).getHome(user);
    if (result != null) {
      context.read(notificationProvider).unreadCount =
          result['notificationCount'];
    }
  }

  @override
  Widget build(BuildContext context) {
    context.read(authProvider.state).user = _user;
    return MaterialApp(
        title: 'Brebit',
        initialRoute: '/splash',
        onGenerateRoute: ApplicationRoutes.generateRoute,
        navigatorKey: ApplicationRoutes.materialKey,
        builder: EasyLoading.init(),
        theme: BrightThemeData.getThemeData(context));
  }
}

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    MyApp.initialize(context).then((_) {
      Navigator.pushReplacement(
          context,
          new PageRouteBuilder(
              settings: RouteSettings(name: _initialRoute ?? '/title'),
              pageBuilder: (BuildContext context, _, __) {
                switch (_initialRoute) {
                  case '/home':
                    return Home(null);
                    break;
                  case '/introduction':
                    return Introduction();
                    break;
                  default:
                    return MyTitle.Title();
                    break;
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
      backgroundColor: Theme.of(context).accentColor,
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
