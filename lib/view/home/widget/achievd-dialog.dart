import 'dart:async';

import 'package:brebit/view/widgets/dialog.dart';
import 'package:emojis/emojis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/habit.dart';
import '../../../../provider/home.dart';

class AchievedDialog {
  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (isShowing) {
      return;
    }
    int toAimMin =
        context.read(homeProvider.state).habit.getStartToAimDate().inMinutes;
    int toAimDay = (toAimMin / 1440).round();
    if (toAimDay > 0) {
      int next;
      List<int> days = Habit.getDayList();
      int step = context.read(homeProvider).getHabit().getNowStep();
      next = days.firstWhere((d) => d > toAimDay);
      if (next == null) {
        next = days.last;
      }
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'スモールステップ${step + 1}を\n達成しました${Emojis.partyPopper}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyText1.copyWith(
                              fontWeight: FontWeight.w700, fontSize: 20),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 16),
                          child: SvgPicture.asset(
                            'assets/steps/step${(step + 2 > 8) ? '8plus' : (step + 2)}.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          '次の目標は$next日です',
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        Material(
                          child: InkWell(
                            onTap: () async {
                              try {
                                await context
                                    .read(homeProvider)
                                    .updateAimDate(next);
                                Navigator.pop(context);
                              } catch (e) {
                                MyErrorDialog.show(e);
                              }
                            },
                            child: Container(
                              height: 56,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  color: Theme.of(context).accentColor),
                              alignment: Alignment.center,
                              child: Text(
                                '目標日数を更新する',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
    }
  }
}
