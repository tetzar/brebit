
import 'package:brebit/view/widgets/back-button.dart';
import 'package:flutter_svg/svg.dart';

import '../../widgets/app-bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SmallStepExplanation extends StatelessWidget {
  Widget _buildImage(String assetName) {
    return Align(
      child: Image.asset('assets/explanation/$assetName.png'),
      alignment: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          titleText: '',
          backButton: AppBarBackButton.none,
          background: AppBarBackground.white,
          actions: [MyBackButtonX()]),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        color: Theme.of(context).primaryColor,
        alignment: Alignment.center,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage('small-step2x'),
              Container(
                margin: EdgeInsets.only(top: 24, bottom: 16),
                child:
                Text(
                  'スモールステップについて',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child:
                Text("「スモールステップ」とは、ある行動を習慣にしていくためにはそのためのステップを小刻みにすべきという考え方です。"
                    "\n\n具体的には、毎日、本を読むことを継続していきたい場合「読む本に手で触れる」という部分まで細分化して、習慣に落とし込んでいきます。本を触れることが習慣化されれば、あとは読むだけなので比較的スムーズに本を読むことが習慣化され継続することができます。"
                    "\n\nこのように、目標としている行動を細分化させて、スモールステップを習慣化させることで、継続することは容易になっていきます。",
                    style: Theme.of(context).textTheme.bodyText1),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 8),
                child:
                Text(
                  'Brbitにおけるスモールステップ',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700
                  ),
                ),
              ),
              Container(
                child:
                Text("Brebitでは短期目標をクリアしていくことをスモールステップとしています。短期目標では連続して達成できた日数をカウントします。最初のステップ1は1日、最後のステップ8は20日です。",
                    style: Theme.of(context).textTheme.bodyText1),
              ),
              SizedBox(height: 8,),
              Container(
                width: double.infinity,
                child: SvgPicture.asset(
                  'assets/steps/step0.svg',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 8,),
              Container(
                child:
                Text("ステップの途中で辞めたい習慣を実行してしまうと、カウントは0日に戻りますがステップは戻りません。\n目先の失敗ではなく過去の積み上げを意識して習慣改善に取り組んでみましょう。",
                    style: Theme.of(context).textTheme.bodyText1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
