import '../../../library/cache.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class Introduction extends StatefulWidget {
  @override
  _IntroductionState createState() => _IntroductionState();
}

class _IntroductionState extends State<Introduction> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context){
    LocalManager.setHasStarted();
    Navigator.of(context).pushReplacementNamed('/title');
  }

  Widget _buildImage(String assetName) {
    return Align(
      child: Image.asset('assets/introduction/$assetName.png', width: 325.0),
      alignment: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,

    );

    return IntroductionScreen(
      key: introKey,
      pages: [
        PageViewModel(
          title: "はじめよう、習慣管理",
          body:
          "Brebitは、みなさんが悪い習慣を\n断つためのお手伝いをします。",
          image: _buildImage('img1'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "アプリの説明1",
          body:
          "Download the Stockpile app and master the market with our mini-lesson.",
          image: _buildImage('img2'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "アプリの説明2",
          body:
          "Kids and teens can track their stocks 24/7 and place trades that you approve.",
          image: _buildImage('img2'),

          // footer: ButtonTheme(
          //   minWidth: 300.0,
          //   height: 56.0,
          //   child: RaisedButton(
          //     onPressed: () {
          //       introKey.currentState?.animateScroll(0);
          //     },
          //     child: const Text(
          //       'はじめる',
          //       style: TextStyle(color: Colors.white),
          //     ),
          //     color: Theme.of(context).primaryColor,
          //     shape: const StadiumBorder(),
          //   ),
          // ),

          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      //onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipFlex: 0,
      nextFlex: 0,
      skip: const Text('スキップ'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('はじめる', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
