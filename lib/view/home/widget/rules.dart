import '../../../../model/habit.dart';
import '../../../../model/strategy.dart';
import '../../../../network/strategy.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../../search/search.dart';
import '../../widgets/bottom-sheet.dart';
import '../../widgets/strategy-card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../navigation.dart';

final rulesEditProvider = StateNotifierProvider((_) => RuleEditProvider(false));

class RuleEditProvider extends StateNotifier<bool> {
  RuleEditProvider(bool state) : super(state);

  void showEdit() {
    state = true;
  }

  void endEdit() {
    state = false;
  }
}

class MyRulesChecked {
  List<int> checkedStrategyIds = <int>[];

  void setStrategy(int strategyId) {
    if (!checkedStrategyIds.contains(strategyId)) {
      checkedStrategyIds.add(strategyId);
    }
  }

  bool hasSet(int strategyId) {
    return checkedStrategyIds.contains(strategyId);
  }

  void removeStrategy(int strategyId) {
    if (checkedStrategyIds.contains(strategyId)) {
      checkedStrategyIds.remove(strategyId);
    }
  }
}

MyRulesChecked myRulesChecked;

class MyRules extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final HomeProviderState _homeProviderState =
        useProvider(homeProvider.state);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24),
      color: Theme.of(context).primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 8),
                  child: Text(
                    '自分のストラテジー',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Theme.of(context).disabledColor),
                  ),
                ),
              ),
              GestureDetector(
                  onTap: () {
                    ApplicationRoutes.pushNamed(
                      '/explanation/strategy'
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/icon/explanation.svg',
                    width: 17,
                      height: 17,
                    color: Theme.of(context).disabledColor,
                  )
              )
            ],
          ),
          RuleCards(strategies: _homeProviderState.habit.strategies),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            alignment: Alignment.center,
            child: InkWell(
              onTap: () {
                Home.navKey.currentState.push(
                  MaterialPageRoute(
                    builder: (context) => Search(
                      args: 'strategy',
                    )
                  )
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 34,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).accentColor, width: 1),
                        borderRadius: BorderRadius.circular(17)),
                    alignment: Alignment.center,
                    child: Text(
                      'ストラテジーを追加',
                      style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class RuleCards extends StatelessWidget {
  final List<Strategy> strategies;

  RuleCards({@required this.strategies});

  @override
  Widget build(BuildContext context) {
    List<StrategyCard> cards = <StrategyCard>[];
    strategies.forEach((strategy) {
      cards.add(StrategyCard(
        strategy: strategy,
        onSelect: () {
          showSheet(context, strategy);
          return false;
        },
      ));
    });
    return Column(
      children: cards,
    );
  }

  void showSheet(BuildContext context, Strategy strategy) {
    bool isUsing =
        context.read(homeProvider).getHabit().isUsingStrategy(strategy);
    List<BottomSheetItem> items = <BottomSheetItem>[
      isUsing
          ? BottomSheetItem(
              onTap: () async {
                Habit habit = await StrategyApi.removeStrategies(
                    context.read(homeProvider).getHabit(), [strategy.id]);
                context.read(homeProvider).setHabit(habit);
                ApplicationRoutes.pop();
              },
              child: Text(
                '自分のストラテジーから削除',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ))
          : BottomSheetItem(
              onTap: () async {
                Habit habit = await StrategyApi.addStrategy(
                    strategy, context.read(homeProvider).getHabit());
                context.read(homeProvider).setHabit(habit);
                ApplicationRoutes.pop();
              },
              child: Text(
                '自分のストラテジーに追加',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              )),
      BottomSheetItem(
          onTap: () async {
            ApplicationRoutes.pop();
          },
          child: Text(
            'キャンセル',
            style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          )),
    ];
    showCustomBottomSheet(
        items: items,
        backGroundColor: Theme.of(context).primaryColor,
        context: ApplicationRoutes.materialKey.currentContext,
        hintText: isUsing
            ? null
            : strategy.getFollowers().toString() + '人のユーザーが使用しています');
  }
}
