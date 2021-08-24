import '../../../../model/habit.dart';
import '../../../../model/strategy.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../did/check_strategy.dart';
import 'confirmation.dart';
import '../../widgets/back-button.dart';
import '../../widgets/strategy-card.dart';
import '../../widgets/text-field.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ExecuteStrategyWannaParam {
  List<Strategy> recommends;
}

class ExecuteStrategyWanna extends StatelessWidget {
  final ExecuteStrategyWannaParam params;

  ExecuteStrategyWanna({@required this.params});

  final CheckedValue checkedValue = CheckedValue();

  @override
  Widget build(BuildContext context) {
    Habit habit = context.read(homeProvider.state).habit;
    List<Widget> strategyCards = <Widget>[];
    habit.strategies.forEach((strategy) {
      strategyCards.add(StrategyCard(
        strategy: strategy,
        onSelect: () {
          return strategyCheck(strategy);
        },
        initialSelected: false,
      ));
    });
    List<Widget> recommendStrategyCard = <Widget>[];
    params.recommends.forEach((strategy) {
      recommendStrategyCard.add(StrategyCard(
        strategy: strategy,
        onSelect: () {
          return strategyCheck(strategy);
        },
        initialSelected: false,
      ));
    });

    return Scaffold(
      appBar: AppBar(
        leading: MyBackButton(),
      ),
      body: MyBottomFixedButton(
        label: '次へ',
        enable: true,
        onTapped: () async {
          await save(context);
        },
        child: Container(
          color: Theme.of(context).primaryColor,
          height: double.infinity,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                child: Text(
                  '欲求に立ち向かうため、どのストラテジーを使用しますか？',
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyText1.color),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 16),
                child: Text(
                  '自分のストラテジー',
                  style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400),
                ),
              ),
              Column(
                children: strategyCards,
              ),
              Container(
                margin: EdgeInsets.only(top: 24),
                child: Text(
                  'おすすめのストラテジー',
                  style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400),
                ),
              ),
              Column(
                children: recommendStrategyCard,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool strategyCheck(Strategy strategy) {
    if (checkedValue.isChecked(strategy.id)) {
      checkedValue.unsetChecked(strategy.id);
      return false;
    } else {
      checkedValue.setChecked(strategy.id);
      return true;
    }
  }

  Future<void> save(BuildContext ctx) async {
    WantConfirmationArguments args = new WantConfirmationArguments();
    args.checkedValue = checkedValue;
    ApplicationRoutes.pushNamed('/want/confirmation', args);
  }
}
