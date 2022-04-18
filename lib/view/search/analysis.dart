import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../api/analysis.dart';
import '../../../model/analysis.dart';
import '../../../model/habit.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../general/loading.dart';
import '../widgets/analysis-card.dart';
import '../widgets/bottom-sheet.dart';
import '../widgets/dialog.dart';
import 'search.dart';

class AnalysisResult extends HookWidget {
  @override
  Widget build(BuildContext context) {
    InputFormProviderState inputFormProviderState =
        useProvider(inputFormProvider.state);
    List<Analysis> result = inputFormProviderState.analyses;
    List<Widget> analysisCards = <Widget>[];
    if (result != null) {
      if (result.length == 0 &&
          context.read(inputFormProvider).word.length > 0) {
        analysisCards.add(Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '申し訳ありません！”${context.read(inputFormProvider).word}”に関する分析はみつかりませんでした。',
            style: Theme.of(context)
                .textTheme
                .bodyText1
                .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
            textAlign: TextAlign.left,
          ),
        ));
      } else {
        result.forEach((analysis) {
          analysisCards.add(InkWell(
              onTap: () {
                onCardTap(context, analysis);
              },
              child: AnalysisCard(
                analysis: analysis,
              )));
        });
      }
      if (result.length < 5) {
        List<Analysis> recommendation =
            context.read(inputFormProvider).recommendation.analyses;
        int recommendationLength = recommendation.length;
        if (recommendationLength > 0) {
          analysisCards.add(Container(
            width: double.infinity,
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(top: 8),
            child: Text(
              'おすすめの分析',
              style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 13),
            ),
          ));
        }
        for (int i = 0; i < min(recommendationLength, 5); i++) {
          Analysis _analysis = recommendation[i];
          analysisCards.add(InkWell(
            onTap: () {
              onCardTap(context, _analysis);
            },
            child: AnalysisCard(
              analysis: recommendation[i],
            ),
          ));
        }
      }
      // analysisCards.add(TextButton(
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
      //         Border.all(color: Theme.of(context).accentColor, width: 1)),
      //     alignment: Alignment.center,
      //     child: Text(
      //       '更新',
      //       style: TextStyle(
      //           color: Theme.of(context).accentColor,
      //           fontWeight: FontWeight.w700,
      //           fontSize: 12),
      //     ),
      //   ),
      // ));
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
                  children: analysisCards,
                ),
              ),
            ),
    );
  }

  void onCardTap(BuildContext context, Analysis analysis) {
    bool isUsing =
        context.read(homeProvider).getHabit().isUsingAnalysis(analysis);
    List<BottomSheetItem> items = <BottomSheetItem>[
      isUsing
          ? BottomSheetItem(
              onTap: () async {
                ApplicationRoutes.pop();
                try {
                  MyLoading.startLoading();
                  Habit habit = await AnalysisApi.removeAnalysis(
                      context.read(homeProvider).getHabit(), analysis);
                  context.read(homeProvider).setHabit(habit);
                  await MyLoading.dismiss();
                } catch (e) {
                  await MyLoading.dismiss();

                  MyErrorDialog.show(e);
                }
              },
              child: Text(
                '分析項目を削除',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ))
          : BottomSheetItem(
              onTap: () async {
                ApplicationRoutes.pop();
                try {
                  MyLoading.startLoading();
                  Habit habit = await AnalysisApi.addAnalysis(
                      context.read(homeProvider).getHabit(), analysis);
                  context.read(homeProvider).setHabit(habit);
                  context.read(inputFormProvider).removeAnalysis(analysis);
                  MyLoading.dismiss();
                } catch (e) {
                  await MyLoading.dismiss();
                  MyErrorDialog.show(e);
                }
              },
              child: Text(
                '分析項目を追加',
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
    );
  }

  Future<void> reload(BuildContext context) async {}
}
