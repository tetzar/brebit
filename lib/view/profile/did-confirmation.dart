// ApplicationRoute /did/confirmation

import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/category.dart';
import '../../../model/habit.dart';
import '../../../model/habit_log.dart';
import '../../../model/tag.dart';
import '../../../model/trigger.dart';
import '../../../provider/condition.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../action/widgets/tags.dart';
import '../widgets/app-bar.dart';
import '../widgets/strategy-card.dart';

class DidConfirmation extends StatelessWidget {
  final HabitLog log;

  DidConfirmation({required this.log});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
        context: context,
        titleText: '',
      ),
      body: DidConfirmationBody(log: log),
    );
  }
}

class DidConfirmationBody extends ConsumerStatefulWidget {
  final HabitLog log;

  DidConfirmationBody({required this.log});

  @override
  _DidConfirmationBodyState createState() => _DidConfirmationBodyState();
}

class _DidConfirmationBodyState extends ConsumerState<DidConfirmationBody> {
  final Map<CategoryName, String> subjectList = {
    CategoryName.cigarette: '喫煙の記録',
    CategoryName.alcohol: '飲酒の記録',
    CategoryName.sweets: 'お菓子を食べた記録',
    CategoryName.sns: 'SNS使用の記録',
  };

  final Map<CategoryName, String> amountName = {
    CategoryName.cigarette: '摂取量',
    CategoryName.alcohol: '摂取量',
    CategoryName.sweets: '摂取量',
    CategoryName.sns: '使用量',
  };

  final Map<CategoryName, String> unit = {
    CategoryName.cigarette: '本',
    CategoryName.alcohol: 'ml',
    CategoryName.sweets: 'kcal',
    CategoryName.sns: '分',
  };

  late Habit _habit;

  @override
  Widget build(BuildContext context) {
    Habit? _habit = ref.read(homeProvider.notifier).getHabit();
    if (_habit == null) {
      return ErrorToHomeContent();
    }
    this._habit = _habit;
    HabitLog log = widget.log;
    Map<String, dynamic> body = log.getBody();
    DateTime dateTime = log.createdAt;
    String dateTimeFormatted = dateTime.year.toString() +
        '/' +
        dateTime.month.toString().toString() +
        '/' +
        dateTime.day.toString() +
        ' ' +
        dateTime.hour.toString() +
        ':' +
        dateTime.minute.toString() +
        ':' +
        dateTime.second.toString();
    List<TagCard> tagCards = <TagCard>[];
    Trigger trigger = body['trigger'];
    List<Tag> tags = trigger.tags;
    tags.forEach((tag) {
      tagCards.add(SimpleTagCard(onCancel: null, name: '#' + tag.name));
    });
    List<StrategyCard> strategyCards = <StrategyCard>[];
    trigger.body['strategies'].forEach((strategy) {
      strategyCards.add(StrategyCard(strategy: strategy));
    });
    return Container(
        height: double.infinity,
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.only(top: 16, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subjectList[_habit.category.name]!,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: Theme.of(context).textTheme.bodyText1?.color),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                dateTimeFormatted,
                style: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 8),
              child: Tags(
                tags: tagCards,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '気分：',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).textTheme.bodyText1?.color),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        MentalValue.find(trigger.body['mental']).name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyText1?.color),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '欲求度：',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).textTheme.bodyText1?.color),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        trigger.body['desire'].toString(),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyText1?.color),
                      ),
                    ),
                  )
                ],
              ),
            ),
            body['amount'] != null
                ? Container(
                    margin: EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${amountName[_habit.category.name]}：',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      ?.color),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: RichText(
                              text: TextSpan(
                                  text: body['amount'].toString(),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyText1
                                          ?.color),
                                  children: [
                                    TextSpan(
                                      text: unit[_habit.category.name],
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              Theme.of(context).disabledColor),
                                    )
                                  ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 0,
                  ),
            Column(
              children: strategyCards,
            )
          ],
        ));
  }

  void restart() async {
    ApplicationRoutes.popUntil(ModalRoute.withName('/home'));
  }
}
