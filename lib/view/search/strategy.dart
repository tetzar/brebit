import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../api/strategy.dart';
import '../../../model/habit.dart';
import '../../../model/strategy.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../strategy/create.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import '../widgets/strategy-card.dart';
import 'search.dart';

class StrategyResult extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(inputFormProvider);
    List<Strategy>? result = ref.read(inputFormProvider.notifier).strategies;
    List<Widget> strategyCards = <Widget>[];
    if (result != null) {
      if (result.length == 0 &&
          ref.read(inputFormProvider.notifier).word.length > 0) {
        strategyCards.add(Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '申し訳ありません！”${ref.read(inputFormProvider.notifier).word}”に関するストラテジーはみつかりませんでした。',
            style: Theme.of(context)
                .textTheme
                .bodyText1
                ?.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
            textAlign: TextAlign.left,
          ),
        ));
      } else {
        result.forEach((strategy) {
          strategyCards.add(StrategyCard(
            strategy: strategy,
            showFollower: true,
            onSelect: () {
              showSheet(context, ref, strategy);
              return false;
            },
          ));
        });
      }
      if (result.length < 5) {
        List<Strategy> recommendation =
            ref.read(inputFormProvider.notifier).recommendation?.strategies ??
                [];
        int recommendationLength = recommendation.length;
        if (recommendationLength > 0) {
          strategyCards.add(Container(
            width: double.infinity,
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(top: 8),
            child: Text(
              'チャレンジに基づいたおすすめ',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 13),
            ),
          ));
        }
        for (int i = 0; i < min(recommendationLength, 5); i++) {
          strategyCards.add(StrategyCard(
            strategy: recommendation[i],
            showFollower: true,
            onSelect: () {
              showSheet(context, ref, recommendation[i]);
              return false;
            },
          ));
        }
      }
      // strategyCards.add(TextButton(
      //   onPressed: () async {
      //     await reload(context);
      //   },
      //   child: Container(
      //     margin: EdgeInsets.symmetric(vertical: 8),
      //     height: 34,
      //     width: 72,
      //     decoration: BoxDecoration(
      //         borderRadius: BorderRadius.circular(17),
      //         border:
      //             Border.all(color: Theme.of(context).colorScheme.secondary, width: 1)),
      //     alignment: Alignment.center,
      //     child: Text(
      //       '更新',
      //       style: TextStyle(
      //           color: Theme.of(context).colorScheme.secondary,
      //           fontWeight: FontWeight.w700,
      //           fontSize: 12),
      //     ),
      //   ),
      // ));
      strategyCards.add(Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(bottom: 8),
        child: Text(
          'または',
          style: TextStyle(
              color: Theme.of(context).disabledColor,
              fontWeight: FontWeight.w400,
              fontSize: 13),
        ),
      ));
      strategyCards.add(InkWell(
        onTap: () {
          StrategyCreateParams params =
              StrategyCreateParams(onSaved: (InputFormValue _formValue) async {
            try {
              MyLoading.startLoading();
              Map<String, dynamic> data = <String, dynamic>{};
              switch (_formValue.strategyCategory) {
                case StrategyCategory.ifThen:
                  data['type'] = 'if-then';
                  data['if'] = _formValue.getValue('if');
                  data['then'] = _formValue.getValue('then');
                  break;
                case StrategyCategory.twentySec:
                  data['type'] = 'twenty-sec';
                  data['action'] = _formValue.getValue('twenty-sec');
                  break;
                default:
                  return;
              }
              List<int> tagIds = [];
              List<String> newTags = [];
              _formValue.tags.forEach((tag) {
                int? tagId = tag.id;
                if (tagId == null) {
                  newTags.add(tag.name);
                } else {
                  tagIds.add(tagId);
                }
              });
              data['tags'] = tagIds;
              data['new_tags'] = newTags;
              Habit? currentHabit = ref.read(homeProvider.notifier).getHabit();
              if (currentHabit == null) return;
              Habit habit = await StrategyApi.storeStrategy(currentHabit, data);
              ref.read(homeProvider.notifier).setHabit(habit);
              await MyLoading.dismiss();
              ApplicationRoutes.pop(context);
            } catch (e) {
              await MyLoading.dismiss();
              MyErrorDialog.show(e);
            }
          });
          ApplicationRoutes.pushNamed('/strategy/create', params);
        },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  spreadRadius: -3,
                  blurRadius: 10,
                  offset: Offset(0, 0),
                )
              ]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 21),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: Theme.of(context).textTheme.subtitle1?.color,
                ),
              ),
              Expanded(
                child: Text('カスタムのストラテジーを追加',
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        ?.copyWith(fontWeight: FontWeight.w400, fontSize: 13)),
              )
            ],
          ),
        ),
      ));
    }
    return Container(
      child: result == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              height: double.infinity,
              padding: EdgeInsets.only(top: 8, left: 24, right: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: strategyCards,
                ),
              ),
            ),
    );
  }

  Future<void> reload(BuildContext context) async {}

  void showSheet(BuildContext context, WidgetRef ref, Strategy strategy) {
    Habit? currentHabit = ref.read(homeProvider.notifier).getHabit();
    if (currentHabit == null) return;
    bool isUsing = currentHabit.isUsingStrategy(strategy);
    List<BottomSheetItem> items = <BottomSheetItem>[
      isUsing
          ? BottomSheetItem(
              onTap: () async {
                ApplicationRoutes.pop();
                try {
                  MyLoading.startLoading();
                  Habit habit = await StrategyApi.removeStrategies(
                      currentHabit, [strategy.id!]);
                  ref.read(homeProvider.notifier).setHabit(habit);
                  await MyLoading.dismiss();
                } catch (e) {
                  await MyLoading.dismiss();
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
                ApplicationRoutes.pop();
                try {
                  MyLoading.startLoading();
                  Habit habit =
                      await StrategyApi.addStrategy(strategy, currentHabit);
                  ref.read(homeProvider.notifier).setHabit(habit);
                  ref.read(inputFormProvider.notifier).removeStrategy(strategy);
                  MyLoading.dismiss();
                } catch (e) {
                  await MyLoading.dismiss();
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
