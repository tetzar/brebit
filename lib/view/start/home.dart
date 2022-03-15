import '../home/navigation.dart';
import 'password-reset.dart';
import 'send-verification.dart';
import 'title.dart' as MyTitle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ApplicationHome extends StatefulWidget {
  @override
  _ApplicationHomeState createState() => _ApplicationHomeState();
}

class _ApplicationHomeState extends State<ApplicationHome> {
  @override
  void initState() {
    this.initDynamicLinks();
    super.initState();
  }

  void initDynamicLinks() async {

    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;
    if (deepLink == null) return;
    if (deepLink.queryParameters.containsKey('continueUrl')) {
      final Uri continueUrl =
          Uri.parse(deepLink.queryParameters['continueUrl']);
      if (deepLink.queryParameters['mode'] == 'verifyEmail') {
        FirebaseAuth.instance.currentUser.reload();
        if (continueUrl.path == '/email-verifying') {
          if (FirebaseAuth.instance.currentUser.emailVerified) {
            pushReplacementNamed(context, '/home');
          } else {
            pushReplacementNamed(context, '/email-verifying', arguments: data);
          }
          return;
        }
        if (continueUrl.path == '/email-set') {
          if (FirebaseAuth.instance.currentUser.emailVerified) {
            pushReplacementNamed(context, '/home');
          } else {
            pushReplacementNamed(context, '/title');
          }
          return;
        }
      }
      if (deepLink.queryParameters['mode'] == 'resetPassword') {
        try {
          await FirebaseAuth.instance
              .verifyPasswordResetCode(deepLink.queryParameters['oobCode']);
          pushReplacementNamed(context, '/password-reset/form',
              arguments: data);
        } catch (e) {
          pushReplacementNamed(context, '/title');
        }
      }
      pushReplacementNamed(context, continueUrl.path, arguments: data);
      return;
    }
    if (deepLink != null) {
      pushReplacementNamed(context, deepLink.path);
    }
  }

  void pushReplacementNamed(BuildContext context, String path,
      {dynamic arguments}) {
    Widget page;
    switch (path) {
      case '/title':
        page = MyTitle.Title();
        break;
      case '/home':
        page = Home(arguments);
        break;
      case '/email-verifying':
        page = EmailVerifyingScreen(arguments);
        break;
      case '/password-reset/form':
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => PasswordResetForm(arguments)));
        return;
        break;
    }
    if (page == null) {
      Navigator.pushReplacementNamed(context, path, arguments: arguments);
    }
    Navigator.pushReplacement(
        context,
        new PageRouteBuilder(
            settings: RouteSettings(name: path),
            pageBuilder: (BuildContext context, _, __) {
              return page;
            },
            transitionDuration: Duration(milliseconds: 1000),
            transitionsBuilder:
                (_, Animation<double> animation, __, Widget child) {
              return new FadeTransition(opacity: animation, child: child);
            }));
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
