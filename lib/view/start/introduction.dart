import 'package:flutter_svg/flutter_svg.dart';

import '../../../library/cache.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class Introduction extends StatefulWidget {
  @override
  _IntroductionState createState() => _IntroductionState();
}

class _IntroductionState extends State<Introduction> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    LocalManager.setHasStarted();
    Navigator.of(context).pushReplacementNamed('/title');
  }

  Widget _buildImage(String assetName) {
    return Align(
      child: Image.asset('assets/introduction/$assetName.png', width: 325.0),
      alignment: Alignment.bottomCenter,
    );
  }

  Widget _buildSvg(String assetName) {
    return Align(
      child:
          SvgPicture.asset('assets/introduction/$assetName.svg', width: 325.0),
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
          title: "ダウンロード\nありがとうございます\nみんなで習慣を\n改善しましょう",
          body: "悪い習慣を\n「やめる」に特化した\n習慣改善アプリです",
          image: _buildImage('img1'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "戦略を活用",
          body:
              "例えば「スマホを見そうになったら」「スクワットする」。\nこういった戦略を活用することは、効果的にやめることにつながります。\nあなたにあった戦略の提案と、あなただけの戦略を作成が可能です。",
          image: _buildImage('intro-strategy2x'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "習慣を記録",
          body:
              "悪い習慣を行ってしまった、欲求を回避した、そんなときはBrebitの記録機能を利用しましょう。過去の記録を振り返り、今の行動に繋げましょう！\nまた、目標への進捗状況がひと目でわかるようになっているので、少しづつ「やめる」に近づいていることを実感しながら継続できます。",
          image: _buildImage('intro-logs2x'),
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
      done: const Text('はじめる'),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      globalBackgroundColor: Theme.of(context).primaryColor,
    );
  }
}
