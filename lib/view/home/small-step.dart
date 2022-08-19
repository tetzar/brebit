import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/habit.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../widgets/app-bar.dart';
import '../widgets/back-button.dart';

class SmallStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    if (habit == null) {
      return ErrorToHomeWidget();
    }
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          titleText: '',
          backButton: AppBarBackButton.none,
          background: AppBarBackground.gray,
          actions: [MyBackButtonX()]),
      body: SmallStepContent(
        habit: habit,
      ),
    );
  }
}

class SmallStepContent extends StatelessWidget {
  final Habit habit;

  SmallStepContent({required this.habit});

  @override
  Widget build(BuildContext context) {
    Habit _habit = this.habit;
    int _nowStep = _habit.getNowStep();
    int _allSteps = Habit.getStepCount();
    int _aimDays = _habit.getStartToAimDate().inDays;
    int _remainingDays = _aimDays - _habit.getStartToNow().inDays;
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: Theme.of(context).backgroundColor,
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '現在のスモールステップ',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      margin: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).primaryColorLight),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (_nowStep + 1).toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                ?.copyWith(fontSize: 36),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            '/$_allSteps',
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                ?.copyWith(
                                    fontSize: 17, fontWeight: FontWeight.w700),
                          )
                        ],
                      )),
                  RichText(
                      text: TextSpan(
                          text: '目標日数：',
                          style:
                              Theme.of(context).textTheme.subtitle1?.copyWith(
                                    fontSize: 13,
                                  ),
                          children: [
                        TextSpan(
                            text: _aimDays.toString(),
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    ?.color,
                                fontWeight: FontWeight.w700))
                      ]))
                ],
              ),
            ),
            Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                padding: EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      text: 'あと',
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
                      children: [
                        TextSpan(
                            text: _remainingDays.toString(),
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: '日で次のスモールステップです。\nこの調子で頑張りましょう！'),
                      ]),
                )),
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'スモールステップと日数',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          text: 'ステップが上がると\nより多くの日数が必要になります',
                          style: Theme.of(context).textTheme.subtitle1,
                          children: [
                            TextSpan(
                                text: '\nさらに詳しく',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    ApplicationRoutes.pushNamed(
                                        '/explanation/small-step');
                                  },
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    decoration: TextDecoration.underline))
                          ])),
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    width: double.infinity,
                    child: SvgPicture.asset(
                      _nowStep + 1 < 9
                          ? 'assets/steps/step${_nowStep + 1}.svg'
                          : 'assets/steps/step8plus.svg',
                      fit: BoxFit.contain,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
