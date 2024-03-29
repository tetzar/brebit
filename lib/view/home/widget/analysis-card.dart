import 'dart:async';
import 'dart:typed_data';

import 'package:brebit/view/general/loading.dart';
import 'package:brebit/view/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../api/analysis.dart';
import '../../../../model/analysis.dart';
import '../../../../model/habit.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../../widgets/bottom-sheet.dart';

class AnalysisCard extends ConsumerStatefulWidget {
  final Analysis analysis;
  final Habit habit;

  AnalysisCard(this.analysis, this.habit);

  @override
  _AnalysisCardState createState() => _AnalysisCardState();
}

class _AnalysisCardState extends ConsumerState<AnalysisCard> {
  late Habit habit;

  @override
  void initState() {
    habit = widget.habit;
    Timer.periodic(Duration(minutes: 1), (Timer t) {
      if (this.mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<List<String>> data = widget.analysis.getData(habit);
    TextStyle? _numberStyle = Theme.of(context)
        .textTheme
        .bodyText1
        ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700);
    TextStyle? _unitStyle = Theme.of(context)
        .textTheme
        .subtitle1
        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
    bool _paramRequired = false;
    List<Text> span = <Text>[];
    data.forEach((d) {
      switch (d.length) {
        case 1:
          span.add(Text(d[0], style: _unitStyle));
          break;
        case 2:
          span.add(Text(d[0], style: _numberStyle));
          span.add(Text(d[1], style: _unitStyle));
          if (double.tryParse(d[0]) == null) {
            _paramRequired = true;
          }
          break;
        default:
          String _t = '';
          d.forEach((element) {
            _t += element;
          });
          span.add(Text(_t, style: _unitStyle));
          break;
      }
    });
    return InkWell(
      onTap: () {
        onCardTap(context, widget.analysis);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor,
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 0),
              )
            ]),
        height: 86,
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    margin: EdgeInsets.symmetric(horizontal: 18),
                    child: FutureBuilder(
                      future: widget.analysis.getImage(),
                      builder: (context, snapshot) {
                        return (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData)
                            ? SvgPicture.memory(
                                snapshot.data as Uint8List,
                                semanticsLabel: 'A shark?!',
                                height: 20,
                                width: 20,
                                color:
                                    Theme.of(context).textTheme.subtitle1?.color,
                                placeholderBuilder: (BuildContext context) =>
                                    Container(
                                  color: Colors.transparent,
                                  width: 20,
                                  height: 20,
                                ),
                              )
                            : SizedBox(
                                height: 20,
                                width: 20,
                              );
                      },
                    )),
                Expanded(
                  child: Text(
                    widget.analysis.name,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.subtitle1?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 24,
                  ),
                  _paramRequired
                      ? Text(
                          '情報を入力すると分析を表示できます',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .subtitle1
                                  ?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        )
                      : Row(
                          children: span
                              .map((s) => Container(
                                    margin: EdgeInsets.only(right: 2),
                                    child: s,
                                  ))
                              .toList(),
                        ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void onCardTap(BuildContext context, Analysis analysis) {
    List<BottomSheetItem> items = <BottomSheetItem>[
      BottomSheetItem(
          onTap: () async {
            MyLoading.startLoading();
            try {
              Habit? habit = await AnalysisApi.removeAnalysis(
                  this.habit, analysis);
              MyLoading.dismiss();
              ref.read(homeProvider.notifier).setHabit(habit);
              ApplicationRoutes.pop();
            } catch (e) {
              MyLoading.dismiss();
              MyErrorDialog.show(e);
            }
          },
          child: Text(
            '分析項目を削除',
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
      context: ApplicationRoutes.materialKey.currentContext ?? context,
    );
  }
}
