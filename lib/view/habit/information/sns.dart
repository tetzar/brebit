import 'dart:async';

import 'package:brebit/view/general/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../api/habit.dart';
import '../../../../model/category.dart';
import '../../../../route/route.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';
import '../select-strategy.dart';
import 'widgets.dart';

class SNSInformation extends StatefulWidget {
  @override
  _SNSInformationState createState() => _SNSInformationState();
}

class _SNSInformationState extends State<SNSInformation> {
  final Category _category = Category.findWhereNameIs('sns');

  Map<String, int> data = <String, int>{'target-minutes': 0, 'target-hours': 0};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (data['target-minutes'] == 0 && data['target-hours'] == 0) {
          if (!data.containsKey('minutes') && !data.containsKey('hours')) {
            return true;
          }
        }
        showDialog(
            context: context,
            builder: (context) => MyDialog(
                title: SizedBox(
                  height: 0,
                ),
                body: Text(
                  '戻りますか？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 17),
                ),
                actionText: '戻る',
                action: () {
                  Navigator.pop(context);
                  ApplicationRoutes.popUntil('/startHabit');
                }));
        return false;
      },
      child: Scaffold(
        appBar: getMyAppBar(
            context: context,
            backButton: AppBarBackButton.arrow,
            background: AppBarBackground.gray,
            titleText: 'SNSを控える',
            onBack: () {
              if (data['target-minutes'] == 0 && data['target-hours'] == 0) {
                if (!data.containsKey('minutes') &&
                    !data.containsKey('hours')) {
                  ApplicationRoutes.pop();
                  return true;
                }
              }
              showDialog(
                  context: context,
                  builder: (context) => MyDialog(
                      title: SizedBox(
                        height: 0,
                      ),
                      body: Text(
                        '戻りますか？',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).disabledColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 17),
                      ),
                      actionText: '戻る',
                      action: () {
                        Navigator.pop(context);
                        ApplicationRoutes.popUntil('/startHabit');
                      }));
            }),
        body: MyBottomFixedButton(
          enable: savable(),
          onTapped: () async {
            await save(context);
          },
          label: '次へ',
          child: Container(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(top: 16, left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InformationItemCards(
                      items: [
                        InformationItem(
                          appbarTitle: '目標',
                          formatter: InformationFormatter.join(
                              InformationFormatter.unit(
                                  InformationFormatter.make('target-hours'),
                                  '時間'),
                              InformationFormatter.unit(
                                  InformationFormatter.make('target-minutes'),
                                  '分')),
                          title: '目標',
                          units: [
                            PickerInformationItemUnit(
                                hintText: '1日あたりのSNS許容利用時間',
                                rollers: [
                                  PickerInformationItemUnitRoller(
                                    start: 0,
                                    end: 23,
                                    step: 1,
                                    name: 'target-hours',
                                    numerator: '時間',
                                  ),
                                  PickerInformationItemUnitRoller(
                                    start: 0,
                                    end: 59,
                                    step: 1,
                                    name: 'target-minutes',
                                    numerator: '分',
                                  ),
                                ]),
                          ],
                        ),
                      ],
                      onChange: (newValue) {
                        newValue.forEach((key, value) {
                          data[key] = value;
                        });
                        setState(() {});
                      },
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    InformationItemCards(
                      items: [
                        InformationItem(
                          appbarTitle: 'これまで',
                          formatter: InformationFormatter.join(
                              InformationFormatter.unit(
                                  InformationFormatter.make('hours'), '時間'),
                              InformationFormatter.unit(
                                  InformationFormatter.make('minutes'), '分')),
                          title: 'これまで',
                          units: [
                            PickerInformationItemUnit(
                                hintText: '1日あたりのSNS利用時間',
                                rollers: [
                                  PickerInformationItemUnitRoller(
                                    start: 0,
                                    end: 23,
                                    step: 1,
                                    name: 'hours',
                                    numerator: '時間',
                                  ),
                                  PickerInformationItemUnitRoller(
                                    start: 0,
                                    end: 59,
                                    step: 1,
                                    name: 'minutes',
                                    numerator: '分',
                                  ),
                                ]),
                          ],
                        ),
                      ],
                      onChange: (newValue) {
                        newValue.forEach((key, value) {
                          data[key] = value;
                        });
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool savable() {
    if (!data.containsKey('target-hours')) {
      return false;
    }
    if (!data.containsKey('target-minutes')) {
      return false;
    }
    if (data.containsKey('hours') && data.containsKey('minutes')) {
      if (!(data['hours'] > 0.0) && !(data['minutes'] > 0.0)) {
        return false;
      }
    } else {
      return false;
    }
    return true;
  }

  Future<void> save(BuildContext ctx) async {
    if (savable()) {
      Map<String, double> _data = <String, double>{};
      _data['limit'] =
          (data['target-hours'] * 60 + data['target-minutes']).toDouble();
      _data['average'] = (data['hours'] * 60 + data['minutes']).toDouble();
      MyLoading.startLoading();
      try {
        Map<String, dynamic> result =
            await HabitApi.saveInformation(_category, _data);
        SelectStrategyParams params = new SelectStrategyParams(
            recommendStrategies: result['strategies']['recommend'],
            habit: result['habit'],
            otherStrategies: result['strategies']['others']);
        await MyLoading.dismiss();
        ApplicationRoutes.pushNamed('/strategy/select', params);
      } catch (e) {
        await MyLoading.dismiss();
        MyErrorDialog.show(e);
      }
    }
  }
}
