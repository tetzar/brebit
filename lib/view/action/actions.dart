import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/habit.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../widgets/back-button.dart';

class HabitActionParams {
  String systemName;
  String wantToDoText;
  String didText;
  String enduredText;

  HabitActionParams({
    required this.systemName,
    required this.wantToDoText,
    required this.didText,
    required this.enduredText,
  });
}

class HabitActions extends ConsumerWidget {
  final List<HabitActionParams> params = <HabitActionParams>[
    HabitActionParams(
      systemName: 'cigarette',
      wantToDoText: 'たばこを吸いたい',
      didText: 'たばこを吸ってしまった',
      enduredText: '吸いたい気持ちを抑えた',
    ),
    HabitActionParams(
      systemName: 'alcohol',
      wantToDoText: 'お酒を飲みたい',
      didText: 'お酒を飲んでしまった',
      enduredText: '飲みたい気持ちを抑えた',
    ),
    HabitActionParams(
      systemName: 'sweets',
      wantToDoText: 'お菓子を食べたい',
      didText: 'お菓子を食べてしまった',
      enduredText: '食べたい気持ちを抑えた',
    ),
    HabitActionParams(
      systemName: 'sns',
      wantToDoText: 'SNSを見たい',
      didText: 'SNSを見てしまった',
      enduredText: 'SNSを見たい気持ちを抑えた',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    if (habit == null) return ErrorToHomeWidget();
    HabitActionParams param = params.firstWhere((param) {
      return param.systemName == habit.category.systemName;
    });
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [MyBackButtonX()],
          backgroundColor: Theme.of(context).backgroundColor,
        ),
        body: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            children: [
              ActionBox(
                picturePath: 'assets/icon/wanna_do.svg',
                title: param.wantToDoText,
                onTap: () {
                  ApplicationRoutes.pushNamed('/want/condition');
                },
              ),
              ActionBox(
                picturePath: 'assets/icon/did.svg',
                title: param.didText,
                onTap: () {
                  ApplicationRoutes.pushNamed('/did/condition');
                },
              ),
              ActionBox(
                picturePath: 'assets/icon/endured.svg',
                title: param.enduredText,
                onTap: () {
                  ApplicationRoutes.pushNamed('/endured/condition');
                },
              )
            ],
          ),
        ));
  }
}

class ActionBox extends StatelessWidget {
  final String title;
  final void Function() onTap;
  final String picturePath;

  ActionBox({
    required this.title,
    required this.onTap,
    required this.picturePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(6)),
              color: Theme.of(context).primaryColor),
          child: Row(
            children: [
              Container(
                child: SvgPicture.asset(
                  picturePath,
                  height: 40,
                  width: 40,
                ),
                margin: EdgeInsets.only(right: 16),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1?.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 17),
                  ),
                ),
              ),
              Container(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
