import '../../../../model/habit.dart';
import '../../../../model/strategy.dart';
import '../../../../network/habit.dart';
import '../../../../provider/condition.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../did/check_strategy.dart';
import '../../general/loading.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/strategy-card.dart';
import '../../widgets/text-field.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

CheckedValue checkedValue;

final buttonTextProvider = StateNotifierProvider.autoDispose(
    (ref) => ButtonTextProvider('')
);

class ButtonTextProvider extends StateNotifier<String> {
  ButtonTextProvider(String state) : super(state);
  
  void notify() {
    state = '';
  }
  
}

class CheckStrategyEndured extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    checkedValue = new CheckedValue();
    Habit habit = context.read(homeProvider.state).habit;
    List<Widget> strategyCards = <Widget>[];
    habit.strategies.forEach((strategy) {
      strategyCards.add(
          StrategyCard(
            strategy: strategy,
            onSelect: () {
              return strategyCheck(strategy, context);
            },
            initialSelected: false,
          )
      );
    });

    return Scaffold(
      appBar: getMyAppBar(
        context: context,
        titleText: ''
      ),
      body: MyHookFlexibleLabelBottomFixedButton(
        labelChange: () {
          if (checkedValue.checked.length > 0) {
            return '次へ';
          } else {
            return 'ストラテジーを使用しなかった';
          }
        },
        provider: buttonTextProvider,
        enable: () {
          return true;
        },
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
                height: 108,
                child: Center(
                  child: Text(
                    'ストラテジーは\n実行しましたか？',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Theme.of(context).textTheme.bodyText1.color),
                  ),
                ),
              ),
              Text(
                '自分のストラテジー',
                style: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400),
              ),
              Column(
                children: strategyCards,
              )
            ],
          ),
        ),
      ),
    );
  }

  bool strategyCheck(Strategy strategy, BuildContext _ctx) {
    if (checkedValue.isChecked(strategy.id)) {
      checkedValue.unsetChecked(strategy.id);
      _ctx.read(buttonTextProvider).notify();
      return false;
    } else {
      checkedValue.setChecked(strategy.id);
      _ctx.read(buttonTextProvider).notify();
      return true;
    }
  }

  Future<void> save(BuildContext ctx) async {
    try {
      MyLoading.startLoading();
      Habit habit = await HabitApi.endured(
          checkedValue.checked,
          ctx.read(conditionValueProvider.state).tags,
          ctx.read(conditionValueProvider.state).mental,
          ctx.read(conditionValueProvider.state).desire.toInt(),
          ctx.read(homeProvider.state).habit);
      ctx.read(homeProvider).setHabit(habit);
      await MyLoading.dismiss();
      ApplicationRoutes.pushNamed('/endured/confirmation');
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}
