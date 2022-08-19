import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../api/habit.dart';
import '../../../../model/habit.dart';
import '../../../../model/habit_log.dart';
import '../../../../provider/condition.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../timeline/create_post.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../did/check_strategy.dart';
import '../widgets/buttons.dart';

class WantConfirmationArguments {
  CheckedValue checkedValue;

  WantConfirmationArguments(this.checkedValue);
}

class WantConfirmationText {
  String categoryName;
  String message;

  WantConfirmationText({required this.categoryName, required this.message});

  static List<WantConfirmationText> textList = <WantConfirmationText>[
    WantConfirmationText(categoryName: 'cigarette', message: 'たばこの欲求'),
    WantConfirmationText(categoryName: 'alcohol', message: 'お酒の欲求'),
    WantConfirmationText(categoryName: 'sweets', message: 'お菓子の欲求'),
    WantConfirmationText(categoryName: 'sns', message: 'SNSの欲求'),
  ];

  static WantConfirmationText find(String categoryName) {
    return textList.firstWhere((elem) => elem.categoryName == categoryName);
  }
}

class WantConfirmation extends ConsumerWidget {
  final WantConfirmationArguments args;

  WantConfirmation({required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Habit? _habit = ref.read(homeProvider.notifier).getHabit();
    if (_habit == null) return ErrorToHomeWidget();
    return WillPopScope(
      onWillPop: () async {
        ApplicationRoutes.popUntil('/home');
        return false;
      },
      child: Scaffold(
        appBar: getMyAppBar(context: context, titleText: ''),
        body: Container(
          height: double.infinity,
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.only(top: 64),
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Text(
                WantConfirmationText.find(_habit.category.systemName).message +
                    '\n抑えられましたか？',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyText1?.color),
              ),
              Container(
                  margin: EdgeInsets.only(top: 40),
                  child: MyTwoChoiceButton(
                      firstLabel: '抑えられた',
                      onFirstTapped: () async {
                        await suppressed(ref, _habit);
                      },
                      secondLabel: '抑えられなかった',
                      onSecondTapped: () async {
                        await did(ref, _habit);
                      })),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> suppressed(WidgetRef ref, Habit currentHabit) async {
    try {
      MyLoading.startLoading();
      MentalValue? mentalValue =
          ref.read(conditionValueProvider.notifier).getMental();
      if (mentalValue != null) {
        Habit habit = await HabitApi.suppressedWant(
            args.checkedValue.checked,
            ref.read(conditionValueProvider.notifier).getTags(),
            mentalValue,
            ref.read(conditionValueProvider.notifier).getDesire().toInt(),
            currentHabit);
        ref.read(homeProvider.notifier).setHabit(habit);
      }
      await MyLoading.dismiss();
      ApplicationRoutes.push(MaterialPageRoute(
          builder: (BuildContext context) => WantSuppressed(
                habit: currentHabit,
              )));
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }

  Future<void> did(WidgetRef ref, Habit currentHabit) async {
    if (currentHabit.hasLimit()) {
      ApplicationRoutes.pushNamed('/did/used-amount', args.checkedValue);
    } else {
      try {
        MyLoading.startLoading();
        MentalValue? mentalValue =
            ref.read(conditionValueProvider.notifier).getMental();
        if (mentalValue != null) {
          Map<String, dynamic> result = await HabitApi.didFromWant(
              args.checkedValue.checked,
              ref.read(conditionValueProvider.notifier).getTags(),
              mentalValue,
              ref.read(conditionValueProvider.notifier).getDesire().toInt(),
              currentHabit);
          ref.read(homeProvider.notifier).setHabit(result['habit']);
          ApplicationRoutes.pushNamed('/did/confirmation', result['log']);
        }
        await MyLoading.dismiss();
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }
}

class WantSuppressed extends StatelessWidget {
  final Habit habit;

  WantSuppressed({required this.habit});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ApplicationRoutes.popUntil('/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
        ),
        body: Container(
          color: Theme.of(context).primaryColor,
          width: MediaQuery.of(context).size.width,
          height: double.infinity,
          padding: EdgeInsets.only(top: 64),
          child: Column(
            children: [
              Text(
                'おめでとうございます！',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyText1?.color),
              ),
              Container(
                margin: EdgeInsets.only(top: 24),
                child: Text(
                  'ぜひポストしてみんなと共有しましょう',
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyText1?.color),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 40),
                child: MyTwoChoiceButton(
                  firstLabel: 'ポストする',
                  onFirstTapped: () async {
                    CreatePostArguments args = new CreatePostArguments();
                    args.log =
                        habit.getLatestLogIn([HabitLogStateName.wannaDo]);
                    ApplicationRoutes.popUntil('/home');
                    ApplicationRoutes.pushNamed('/post/create', args);
                  },
                  secondLabel: '今はしない',
                  onSecondTapped: () async {
                    ApplicationRoutes.popUntil('/home');
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
