import 'dart:math';

import '../../../library/cache.dart';
import 'package:brebit/main.dart';
import '../../../provider/auth.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../home/navigation.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SendVerificationCodeScreen extends StatelessWidget {
  final String nickName;

  SendVerificationCodeScreen(this.nickName);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: getMyAppBar(
            context: context,
            titleText: '新規登録',
            backButton: AppBarBackButton.none),
        body: SendVerificationCodeScreenContent(nickName),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

class SendVerificationCodeScreenContent extends StatefulWidget {
  final String nickName;

  SendVerificationCodeScreenContent(this.nickName);

  @override
  _SendVerificationCodeScreenContentState createState() =>
      _SendVerificationCodeScreenContentState();
}

class _SendVerificationCodeScreenContentState
    extends State<SendVerificationCodeScreenContent> {
  String email;

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EmailVerifyingScreen(dynamicLink)));
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });
  }

  @override
  void initState() {
    sendVerification();
    this.initDynamicLinks();
    try {
      email = FirebaseAuth.instance.currentUser.email;
      if (email == null) {
        ApplicationRoutes.pop();
      }
    } catch (e) {
      ApplicationRoutes.pop();
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 64,
            ),
            Text(
              'メールアドレス認証',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              '''${widget.nickName}さん、最後のステップです。
“$email”宛に
届いたメールのリンクを開くと、
登録が完了します。
            ''',
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                    fontSize: 17,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 64,
            ),
            InkWell(
              onTap: () async {
                await sendVerification();
              },
              borderRadius: BorderRadius.circular(17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 144,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).accentColor,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      'メールを再送する',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 16,
            ),
            InkWell(
              onTap: () async {
                if (!FirebaseAuth.instance.currentUser.emailVerified) {
                  try {
                    await FirebaseAuth.instance.currentUser.delete();
                  } on FirebaseAuthException {} catch (e) {
                    MyErrorDialog.show(e, onConfirm: () {
                      ApplicationRoutes.pop();
                      ApplicationRoutes.pop();
                    });
                    return;
                  }
                }
                Map<String, String> registrationData =
                    await LocalManager.getRegisterInformation(
                        FirebaseAuth.instance.currentUser);
                Navigator.pushReplacementNamed(context, '/register',
                    arguments: registrationData);
              },
              borderRadius: BorderRadius.circular(17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      border: Border.all(
                          color: Theme.of(context).accentColor, width: 1),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      '登録内容を修正する',
                      style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 24,
            ),
            RichText(
              text: TextSpan(
                style: Theme.of(context)
                    .textTheme
                    .subtitle1
                    .copyWith(fontSize: 12),
                children: <TextSpan>[
                  TextSpan(
                    text: 'アカウントをお持ちの方は',
                  ),
                  TextSpan(
                      text: 'サインイン',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          ApplicationRoutes.pushReplacementNamed('/login');
                        },
                      style: (TextStyle(
                        color: Theme.of(context).accentColor,
                        decoration: TextDecoration.underline,
                      ))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> sendVerification() async {
    try {
      MyLoading.startLoading();
      User firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null && !firebaseUser.emailVerified) {
        var actionCodeSettings = ActionCodeSettings(
          url: 'https://brebit.dev/email-verifying',
          androidPackageName: "dev.brebit",
          dynamicLinkDomain: 'brebit.page.link',
          androidInstallApp: true,
          iOSBundleId: "com.example.breabitApp",
          handleCodeInApp: true,
        );
        await firebaseUser.sendEmailVerification(actionCodeSettings);
      }
      await MyLoading.dismiss();
      return;
    } on FirebaseAuthException {} catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
      return;
    }
    await MyLoading.dismiss();
  }
}

class EmailVerifyingScreen extends StatefulWidget {
  final PendingDynamicLinkData dynamicLink;

  EmailVerifyingScreen(this.dynamicLink);

  @override
  _EmailVerifyingScreenState createState() => _EmailVerifyingScreenState();
}

class _EmailVerifyingScreenState extends State<EmailVerifyingScreen>
    with TickerProviderStateMixin {
  AnimationController _loadingAnimationController;
  Animation _loadingAnimation;
  AnimationController _indicatorAnimationController;
  Animation _indicatorAnimation;

  bool complete;

  @override
  void initState() {
    complete = false;
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _loadingAnimation =
        Tween<double>(begin: 0, end: 1).animate(_loadingAnimationController);
    _indicatorAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _indicatorAnimation =
        Tween<double>(begin: 0, end: 1).animate(_indicatorAnimationController);
    _loadingAnimationController.forward();
    _indicatorAnimationController.repeat();
    verifyEmail();
    super.initState();
  }

  Future<void> verifyEmail() async {
    bool verifyComplete = false;
    bool timerComplete = false;
    Future.delayed(Duration(seconds: 3), () {
      if (verifyComplete) {
        loadComplete();
      } else {
        timerComplete = true;
      }
    });
    final Uri deepLink = widget.dynamicLink?.link;
    FirebaseAuth auth = FirebaseAuth.instance;

    var actionCode = deepLink.queryParameters['oobCode'];
    try {
      await auth.checkActionCode(actionCode);
      await auth.applyActionCode(actionCode);

      // If successful, reload the user:
      await auth.currentUser.reload();
      if (auth.currentUser.emailVerified) {
        Map<String, String> registrationData =
            await LocalManager.getRegisterInformation(
                FirebaseAuth.instance.currentUser);
        if (registrationData == null) {
          Navigator.pushReplacementNamed(context, '/title');
          return;
        }
        await context.read(authProvider).registerWithFirebase(
            registrationData['nickName'],
            registrationData['userName'],
            auth.currentUser);
        await MyApp.initialize(context);
        if (timerComplete) {
          loadComplete();
        } else {
          verifyComplete = true;
        }
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, '/title');
    }
  }

  void loadComplete() {
    _loadingAnimationController.reverse().whenComplete(() {
      complete = true;
      _loadingAnimationController.forward().whenComplete(() {
        Future.delayed(Duration(seconds: 2), () {
          _loadingAnimationController.reverse();
          startPageTransition();
        });
      });
    });
  }

  void startPageTransition() {
    ApplicationRoutes.materialKey.currentState.pushReplacement(
      PageRouteBuilder(
        settings: RouteSettings(name: '/home'),
        pageBuilder: (context, animation1, animation2) =>
            Home(HomeActionCodes.verifyComplete),
        transitionDuration: Duration(seconds: 0),
      ),
    );
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _indicatorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).accentColor,
        body: Center(
          child: Stack(
            children: [
              AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, _) {
                    return Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 60,
                          ),
                          Text(
                            complete ? '完了！' : 'メールアドレスを認証しています',
                            style: TextStyle(
                                color:
                                    Theme.of(context).primaryColor.withOpacity(
                                          _loadingAnimation.value,
                                        ),
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                          AnimatedBuilder(
                              animation: _indicatorAnimation,
                              builder: (context, _) {
                                return Container(
                                  height: 60,
                                  width: 46,
                                  child: CustomPaint(
                                    painter: ThreeDotsProgressIndicatorPainter(
                                        complete
                                            ? Colors.transparent
                                            : Theme.of(context)
                                                .primaryColor
                                                .withOpacity(
                                                    _loadingAnimation.value),
                                        _indicatorAnimation.value),
                                  ),
                                );
                              })
                        ],
                      ),
                    );
                  })
            ],
          ),
        ),
      ),
    );
  }
}

class ThreeDotsProgressIndicatorPainter extends CustomPainter {
  final Color color;
  final double position;
  final double interval = 8;
  final double dotSize = 10;
  final double amp = 10;
  final double waveLength = 30;
  final double standard = 53;

  ThreeDotsProgressIndicatorPainter(this.color, this.position);

  @override
  void paint(Canvas canvas, Size size) {
    Paint circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      double x = dotSize / 2 + i * (interval + dotSize);
      canvas.drawCircle(Offset(x, standard - getVerticalPosition(x)),
          dotSize / 2, circlePaint);
    }
  }

  double getVerticalPosition(double x) {
    double maxWidth = 3 * dotSize + 2 * interval;
    double pivotRange = maxWidth + waveLength;
    double pivotPosition = pivotRange * position - (waveLength / 2);
    if ((pivotPosition - waveLength / 2) > x ||
        (pivotPosition + waveLength / 2) < x) {
      return 0;
    }
    return amp * sin((x - (pivotPosition - waveLength / 2)) / waveLength * pi);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
