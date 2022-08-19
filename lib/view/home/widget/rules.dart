import 'package:brebit/view/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../api/strategy.dart';
import '../../../../model/habit.dart';
import '../../../../model/strategy.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../../../model/user.dart';
import '../../search/search.dart';
import '../../widgets/bottom-sheet.dart';
import '../../widgets/strategy-card.dart';
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

class MyRules extends ConsumerWidget {
  final AuthUser user;

  MyRules({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeProvider);
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    if (habit == null) {
      ref.read(homeProvider.notifier).getHome(user);
      return Container(
        height: 0,
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24),
      color: Theme.of(context).primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              margin: EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '自分のストラテジー',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Theme.of(context).disabledColor),
                    ),
                  ),
                  GestureDetector(
                      onTap: () {
                        ApplicationRoutes.pushNamed('/explanation/strategy');
                      },
                      child: SvgPicture.asset(
                        'assets/icon/explanation.svg',
                        width: 20,
                        height: 20,
                        color: Theme.of(context).disabledColor,
                      ))
                ],
              )),
          RuleCards(habit: habit),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            alignment: Alignment.center,
            child: InkWell(
              onTap: () {
                Home.push(MaterialPageRoute(
                    builder: (context) => Search(
                          args: 'strategy',
                        )));
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
                            color: Theme.of(context).colorScheme.secondary,
                            width: 1),
                        borderRadius: BorderRadius.circular(17)),
                    alignment: Alignment.center,
                    child: Text(
                      'ストラテジーを追加',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
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

class RuleCards extends ConsumerWidget {
  final Habit habit;

  RuleCards({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<StrategyCard> cards = <StrategyCard>[];
    habit.strategies.forEach((strategy) {
      cards.add(StrategyCard(
        strategy: strategy,
        onSelect: () {
          showSheet(ref, habit, context, strategy);
          return false;
        },
      ));
    });
    return Column(
      children: cards,
    );
  }

  void showSheet(WidgetRef ref, Habit currentHabit, BuildContext context,
      Strategy strategy) {
    bool isUsing = currentHabit.isUsingStrategy(strategy);
    int? strategyId = strategy.id;
    if (strategyId == null) return;
    List<BottomSheetItem> items = <BottomSheetItem>[
      isUsing
          ? BottomSheetItem(
              onTap: () async {
                try {
                  Habit habit = await StrategyApi.removeStrategies(
                      currentHabit, [strategyId]);
                  ref.read(homeProvider.notifier).setHabit(habit);
                  ApplicationRoutes.pop();
                } catch (e) {
                  MyErrorDialog.show(e);
                }
              },
              child: Text(
                '自分のストラテジーから削除',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ))
          : BottomSheetItem(
              onTap: () async {
                try {
                  Habit habit =
                      await StrategyApi.addStrategy(strategy, currentHabit);
                  ref.read(homeProvider.notifier).setHabit(habit);
                  ApplicationRoutes.pop();
                } catch (e) {
                  MyErrorDialog.show(e);
                }
              },
              child: Text(
                '自分のストラテジーに追加',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1?.color,
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
