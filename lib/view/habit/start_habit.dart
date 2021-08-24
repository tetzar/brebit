import '../../../model/category.dart';
import '../../../model/habit.dart';
import '../../../provider/auth.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../widgets/app-bar.dart';
import '../widgets/back-button.dart';
import '../widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StartHabit extends StatefulWidget {
  @override
  _StartHabitState createState() => _StartHabitState();
}

class _StartHabitState extends State<StartHabit> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context,
          background: AppBarBackground.gray,
          backButton: AppBarBackButton.none,
          titleText: '新しいチャレンジ',
          actions: <Widget>[MyBackButtonX()]),
      body: HabitCards(),
    );
  }
}

class HabitCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = <Widget>[
      Container(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          '登録が多いチャレンジ',
          style: Theme.of(context).textTheme.subtitle1,
        ),
      ),
      HabitTab(
        tag: 'たばこを減らす',
        icon: SvgPicture.asset(
          'assets/icon/cigarette.svg',
          height: 20,
        ),
        onPressed: () {
          if (!context
              .read(authProvider.state)
              .user
              .isUnStartedCategory(CategoryName.cigarette)) {
            showRestartDialog(context, CategoryName.cigarette, 'たばこを減らす');
          } else {
            ApplicationRoutes.pushNamed('/category/cigarette');
          }
        },
      ),
      SizedBox(
        height: 16,
      ),
      HabitTab(
        tag: 'お酒を控える',
        icon: SvgPicture.asset(
          'assets/icon/liquor.svg',
          height: 20,
        ),
        onPressed: () {
          if (!context
              .read(authProvider.state)
              .user
              .isUnStartedCategory(CategoryName.alcohol)) {
            showRestartDialog(context, CategoryName.alcohol, 'お酒を控える');
          } else {
            ApplicationRoutes.pushNamed('/category/alcohol');
          }
        },
      ),
      Container(
        margin: EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          'その他',
          style: Theme.of(context).textTheme.subtitle1,
        ),
      ),
      HabitTab(
        tag: 'お菓子を控える',
        icon: SvgPicture.asset(
          'assets/icon/sweet.svg',
          height: 20,
        ),
        onPressed: () {
          if (!context
              .read(authProvider.state)
              .user
              .isUnStartedCategory(CategoryName.sweets)) {
            showRestartDialog(context, CategoryName.sweets, 'お酒を控える');
          } else {
            ApplicationRoutes.pushNamed('/category/sweets');
          }
        },
      ),
      SizedBox(
        height: 16,
      ),
      HabitTab(
        tag: 'SNSを控える',
        icon: SvgPicture.asset(
          'assets/icon/sns.svg',
          height: 20,
        ),
        onPressed: () {
          if (!context
              .read(authProvider.state)
              .user
              .isUnStartedCategory(CategoryName.sns)) {
            showRestartDialog(context, CategoryName.sns, 'お酒を控える');
          } else {
            ApplicationRoutes.pushNamed('/category/sns');
          }
        },
      ),
    ];
    return Container(
        child: SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(top: 16, right: 24, left: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        ),
      ),
    ));
  }

  void showRestartDialog(
      BuildContext context, CategoryName categoryName, String categoryTitle) {
    showDialog(
        context: ApplicationRoutes.materialKey.currentContext,
        builder: (_) {
          return MyDialog(
              title: Text('“$categoryTitle”は一時停止中です。\n再開しますか？',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
              body: SizedBox(
                height: 0,
              ),
              actionText: '再開する',
              action: () async {
                Habit _habit =
                    await context.read(authProvider).restartHabit(categoryName);
                await context.read(homeProvider).restart(_habit);
                ApplicationRoutes.pop();
                ApplicationRoutes.pop();
              });
        });
  }
}

class HabitTab extends StatelessWidget {
  final Widget icon;
  final String tag;
  final Function onPressed;

  HabitTab({@required this.icon, @required this.tag, @required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 19),
                  alignment: Alignment.center,
                  child: icon),
              Expanded(
                child: Text(
                  tag,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              )
            ],
          )),
    );
  }
}
