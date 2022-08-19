import 'dart:async';

import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../api/habit.dart';
import '../../../../model/habit.dart';
import '../../../../model/strategy.dart';
import '../../../../provider/condition.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/strategy-card.dart';
import '../../widgets/text-field.dart';
import '../did/check_strategy.dart';

late CheckedValue checkedValue;

final buttonTextProvider =
    StateNotifierProvider.autoDispose((ref) => ButtonTextProvider(false));

class ButtonTextProvider extends StateNotifier<bool> {
  ButtonTextProvider(bool state) : super(state);

  void notify() {
    state = !state;
  }
}

class CheckStrategyEndured extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    checkedValue = new CheckedValue();
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    if (habit == null) return ErrorToHomeWidget();
    List<Widget> strategyCards = <Widget>[];
    habit.strategies.forEach((strategy) {
      strategyCards.add(StrategyCard(
        strategy: strategy,
        onSelect: () {
          return strategyCheck(strategy, ref);
        },
        initialSelected: false,
      ));
    });

    return Scaffold(
      appBar: getMyAppBar(context: context, titleText: ''),
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
          await save(ref, habit);
        },
        child: Container(
          color: Theme.of(context).primaryColor,
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
                        color: Theme.of(context).textTheme.bodyText1?.color),
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

  bool strategyCheck(Strategy strategy, WidgetRef _ref) {
    int? strategyId = strategy.id;
    if (strategyId == null) return false;
    if (checkedValue.isChecked(strategyId)) {
      checkedValue.unsetChecked(strategyId);
      _ref.read(buttonTextProvider.notifier).notify();
      return false;
    } else {
      checkedValue.setChecked(strategyId);
      _ref.read(buttonTextProvider.notifier).notify();
      return true;
    }
  }

  Future<void> save(WidgetRef ref, Habit currentHabit) async {
    try {
      MyLoading.startLoading();
      MentalValue? mentalValue = ref.read(conditionValueProvider.notifier).getMental();
      if (mentalValue != null) {
        Habit habit = await HabitApi.endured(
            checkedValue.checked,
            ref.read(conditionValueProvider.notifier).getTags(),
            mentalValue,
            ref.read(conditionValueProvider.notifier).getDesire().toInt(),
            currentHabit);
        ref.read(homeProvider.notifier).setHabit(habit);
      }
      await MyLoading.dismiss();
      ApplicationRoutes.pushNamed('/endured/confirmation');
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}
