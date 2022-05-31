// package:brebit/view/register.dart

import 'package:brebit/provider/confetti.dart';
import 'package:brebit/view/home/navigation.dart';
import 'package:brebit/view/home/widget/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/habit.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import 'analysis.dart';
import 'widget/activity.dart';
import 'widget/home-slider.dart';
import 'widget/progress.dart';
import 'widget/rules.dart';

class HomeContent extends StatefulHookWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  Confetti confetti;

  @override
  void initState() {
    _tabController = new TabController(length: 3, vsync: this);
    _tabController.animation.addListener(() {
      context.read(tabProvider).set(_tabController.animation.value);
    });
    context.read(homeTabProvider).setListener((int s) {
      if (s == 0) {
        _tabController.animateTo(0);
      }
    });
    _tabController.index = context.read(tabProvider.state).round();
    confetti =  Confetti();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    useProvider(homeProvider.state);
    Habit habit = context.read(homeProvider).getHabit();
    bool smallMediaQuery = MediaQuery.of(context).size.height < 600;
    if (habit == null) {
      return Container(
        height: double.infinity,
        color: Theme.of(context).primaryColor,
        width: double.infinity,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(top: smallMediaQuery ? 24 : 60),
                child: Text(
                  'Brebitへようこそ！\nやめたい習慣を\n登録しましょう',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                  ),
                ),
              ),
              SizedBox(
                height: smallMediaQuery ? 196 : 256,
              ),
              Container(
                margin: EdgeInsets.only(bottom: smallMediaQuery ? 20 : 48),
                child: InkWell(
                  onTap: () {
                    bool hasHabit =
                        context.read(homeProvider).getHabit() != null;
                    if (!hasHabit) {
                      ApplicationRoutes.pushNamed('/startHabit');
                    }
                  },
                  child: Container(
                    width: 300,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                      color: Theme.of(context).accentColor,
                    ),
                    child: Center(
                      child: Text(
                        'チャレンジをはじめる',
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 17),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: Column(
          children: [
            HomeTabBarContent(tabController: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Progress(
                    onAimDateUpdated: onAimDateUpdated,
                  ),
                  AnalysisScreen(),
                  HomeActivity(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onAimDateUpdated(BuildContext context) {
    context.read(confettiProvider).play();
  }
}

class Progress extends StatelessWidget {
  final Function onAimDateUpdated;

  Progress({@required this.onAimDateUpdated});

  @override
  Widget build(BuildContext context) {
    int nowStep = getNowStep(context);
    int maxStep = getMaxStep();
    return Container(
      width: MediaQuery.of(context).size.width,
      child: CustomScrollView(slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: 24),
                color: Theme.of(context).primaryColor,
                child: Column(
                  children: [
                    ProgressCircle(
                       onAimDateUpdated:onAimDateUpdated
                    ),
                    InkWell(
                      onTap: () {
                        ApplicationRoutes.pushNamed('/home/small-step');
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 5),
                        color: Theme.of(context).primaryColor,
                        width: MediaQuery.of(context).size.width,
                        height: 52,
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                    text: 'スモールステップ',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .color,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: (nowStep + 1).toString() +
                                              '/' +
                                              maxStep.toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700))
                                    ]),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Theme.of(context).disabledColor,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                  child: Container(
                      margin: EdgeInsets.only(top: 8), child: MyRules())),
            ],
          ),
        )
      ]),
    );
  }

  int getNowStep(BuildContext ctx) {
    return ctx.read(homeProvider).getHabit().getNowStep();
  }

  int getMaxStep() {
    return Habit.getStepCount();
  }
}
