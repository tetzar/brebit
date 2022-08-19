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

class CheckedValue {
  List<int> checked = <int>[];

  void setChecked(int id) {
    if (!checked.contains(id)) {
      checked.add(id);
    }
  }

  void unsetChecked(int id) {
    if (checked.contains(id)) {
      checked.remove(id);
    }
  }

  bool isChecked(int id) {
    return checked.contains(id);
  }
}

final buttonTextProvider =
    StateNotifierProvider.autoDispose((ref) => ButtonTextProvider(false));

class ButtonTextProvider extends StateNotifier<bool> {
  ButtonTextProvider(bool state) : super(state);

  void notify() {
    state = !state;
  }
}

late CheckedValue checkedValue;

class CheckStrategyDid extends ConsumerWidget {
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
          print("label change");
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

  Future<void> save(WidgetRef ref, Habit habit) async {
    if (habit.hasLimit()) {
      ApplicationRoutes.pushNamed('/did/used-amount', checkedValue);
    } else {
      try {
        MyLoading.startLoading();
        ConditionValueState _value = ref.read(conditionValueProvider.notifier).getState();
        MentalValue? _mental = _value.mental;
        if (_mental == null) return;
        Map<String, dynamic> result = await HabitApi.did(
            _mental,
            _value.desire.toInt(),
            _value.tags,
            checkedValue.checked,
            1,
            habit);
        ref.read(homeProvider.notifier).setHabit(result['habit']);
        await MyLoading.dismiss();
        ApplicationRoutes.pushNamed('/did/confirmation', result['log']);
      } catch (e) {
        MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }
}
