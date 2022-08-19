
import 'package:brebit/model/habit.dart';
import 'package:brebit/view/general/error-widget.dart';

import '../../../../model/habit_log.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../widgets/buttons.dart';
import '../../timeline/create_post.dart';
import '../../widgets/app-bar.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


class EnduredConfirmation extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    if (habit == null) return ErrorToHomeWidget();
    return WillPopScope(
      onWillPop: () async {
        ApplicationRoutes.popUntil('/home');
        return false;
      },
      child: Scaffold(
        appBar: getMyAppBar(
          context: context,
          backButton: AppBarBackButton.none
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
                    args.log = habit
                        .getLatestLogIn([HabitLogStateName.wannaDo]);
                    ApplicationRoutes.popUntil('/home');
                    ApplicationRoutes.pushNamed(
                        '/post/create', args
                    );
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