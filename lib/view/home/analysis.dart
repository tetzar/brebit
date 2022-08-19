import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/analysis.dart';
import '../../../provider/home.dart';
import '../../model/habit.dart';
import '../search/search.dart';
import 'navigation.dart';
import 'widget/analysis-card.dart';

class AnalysisScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    if (habit == null)
      return Container(
        height: double.infinity,
        child: Center(
          child: Text(
            "習慣を読み込めませんでした",
            style:
                TextStyle(color: Theme.of(context).disabledColor, fontSize: 24),
          ),
        ),
      );
    return Container(
      height: double.infinity,
      color: Theme.of(context).primaryColor,
      child: SingleChildScrollView(
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            width: MediaQuery.of(context).size.width,
            child: AnalysisContent()),
      ),
    );
  }
}

class AnalysisContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeProvider);
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    List<Widget> columnChildren = [];
    if (habit != null) {
      List<Analysis> analyses = habit.analyses;
      columnChildren =
          analyses.map((analysis) => AnalysisCard(analysis, habit)).toList();
    }
    return Column(
      children: [
        Column(
          children: columnChildren,
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          alignment: Alignment.center,
          child: InkWell(
            onTap: () {
              Home.push(MaterialPageRoute(
                  builder: (context) => Search(
                        args: 'analysis',
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
                    '分析項目を追加',
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
    );
  }
}
