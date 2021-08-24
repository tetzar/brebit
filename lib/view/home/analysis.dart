import '../../../model/analysis.dart';
import '../../../provider/home.dart';
import '../search/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'navigation.dart';
import 'widget/analysis-card.dart';

class AnalysisScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

class AnalysisContent extends HookWidget {
  @override
  Widget build(BuildContext context) {
    useProvider(homeProvider.state);
    List<Analysis> analyses = context.read(homeProvider).getHabit().analyses;
    List<Widget> columnChildren =
        analyses.map((analysis) => AnalysisCard(analysis)).toList();
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
              Home.navKey.currentState.push(
                  MaterialPageRoute(
                      builder: (context) => Search(
                        args: 'analysis',
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
                    '分析項目を追加',
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
    );
  }
}
