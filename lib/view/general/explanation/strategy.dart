import 'package:brebit/model/strategy.dart';
import 'package:brebit/model/user.dart';
import 'package:brebit/view/widgets/back-button.dart';
import 'package:brebit/view/widgets/strategy-card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/svg.dart';

import '../../widgets/app-bar.dart';
import 'package:flutter/material.dart';

import '../../theme/customTheme.dart';

class StrategyExplanation extends StatelessWidget {
  Widget _buildImage(String assetName) {
    return Align(
      child: Image.asset('assets/explanation/$assetName.png'),
      alignment: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    var linkTextStyle = CustomTheme.getLinkTextStyle(context);
    Map<String, dynamic> ifThenBody = {
      "type": {"data_type": "text", "value": "if-then"},
      "if": {"data_type": "text", "value": "スマホを見そうになったら"},
      "then": {"data_type": "text", "value": "スクワットする"},
      'tags': {'data_type': "array(unknown)", 'value': "[]"}
    };
    Map<String, dynamic> twentySecBody = {
      'type': {'data_type': 'text', 'value': 'twenty_sec'},
      'rule': {'data_type': 'text', 'value': 'SNSのアプリを削除する'},
      'tags': {'data_type': 'array(unknown)', 'value': '[]'}
    };
    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: '', backButton: AppBarBackButton.none, background: AppBarBackground.white, actions: [MyBackButtonX()]),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        color: Theme.of(context).primaryColor,
        alignment: Alignment.center,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage('strategy2x'),
              Container(
                margin: EdgeInsets.only(top: 24),
                child: Text(
                  '戦略的に習慣づけを行う',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                child: Text(
                    "多くの人が陥りがちな思い込みとして、「自分の行動は自分の意思でコントロールしている」というものが挙げられます。実際には、毎日の行動で意思によるものは思っているほど多くありません。人生の半分は習慣的な行動からできている、という調査もあるのです。"
                    "\n\n強い意志は悪い習慣を断つ上では役に立ちますが、なくても問題ありません。むしろ、行動を継続することで意志力が鍛わるのです。"
                    "\n\nBrebitでは様々な習慣づけのテクニックのうち、「If-Thenプランニング」と「20秒ルール」をストラテジー(戦略)として活用できるようになっています。",
                    style: Theme.of(context).textTheme.bodyText1),
              ),
              SizedBox(
                height: 8,
              ),
              GestureDetector(
                onTap: () {
                  //TODO
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      // 下線の位置が下からどれくらい離れているか(0で1番離れる)
                      bottom: 0,
                      child: Container(
                        height: 0.5,
                        decoration: BoxDecoration(color: Theme.of(context).accentColor, borderRadius: BorderRadius.circular(1.5)),
                      ),
                    ),
                    Text('If-Thenプランニングとは', textAlign: TextAlign.center, style: linkTextStyle),
                  ],
                ),
              ),
              SizedBox(
                height: 8,
              ),
              GestureDetector(
                onTap: () {
                  //TODO
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      // 下線の位置が下からどれくらい離れているか(0で1番離れる)
                      bottom: 0,
                      child: Container(
                        height: 0.5,
                        decoration: BoxDecoration(color: Theme.of(context).accentColor, borderRadius: BorderRadius.circular(1.5)),
                      ),
                    ),
                    Text('20秒ルールとは', textAlign: TextAlign.center, style: linkTextStyle),
                  ],
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                child: Text(
                  '習慣化の帝王、\nIf-Thenプランニング',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                child: Text(
                    "If-Thenプランニングとは、「Aが起きたらBをする」「Aの状況に陥ったらBをする」というように、行動のきっかけをあらかじめ決めておくことです。"
                    "\n「If=もし〇〇したら」→「then=そのとき〇〇する」というように、条件と行動を結びつけるのが通常のTODOリストと異なる点です。"
                    "\nただ目標を決めるだけではなく具体的な条件を決めることで、脳が反応しやすくなります。"
                    "\n\nこのIf-Thenプランニングは例えば次のようにして習慣改善に用いることができます：",
                    style: Theme.of(context).textTheme.bodyText1),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                child: StrategyCard(
                  strategy: Strategy(
                    body: ifThenBody,
                  ),
                  onSelect: () {
                    return false;
                  },
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                child: Text("ポイントは、「何かをやる習慣」に置き換えることです。\n一般的に「何かをやらない習慣」をつくることは「何かをやる習慣」をつくるより難しいということがわかっています。そのため、「肉を注文しない」より「低カロリーのメニューを注文する」という習慣を作るほうが実行しやすくなります。",
                    style: Theme.of(context).textTheme.bodyText1),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                child: Text(
                  '習慣づくりの基本、20秒ルール',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                child: Text("新しい習慣を身に付けようとする時には、その行動を「やりやすいようにすること」が大切です。逆に、ある習慣をやめるためにはその行動を「やりにくいようにすること」が大切です。\nひとつの行動にかかる時間を20秒増やすのが「20秒ルール」です。例えば、SNSをついつい見すぎてしまう場合は、次のような20秒ルールを取り入れるといいかもしれません：",
                    style: Theme.of(context).textTheme.bodyText1),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                child: StrategyCard(
                  strategy: Strategy(
                    body: twentySecBody,
                  ),
                  onSelect: () {
                    return false;
                  },
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                child: Text(" こうすることで、SNSはアプリではなくブラウザから見なければならなくなり、手間が増えます。\n\n「20秒ルール」とはいっても20秒にこだわりすぎず、ワンステップずつ手間を増やすところから初めていきましょう。", style: Theme.of(context).textTheme.bodyText1),
              ),
              SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
