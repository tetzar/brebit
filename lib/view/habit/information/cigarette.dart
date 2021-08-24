import '../../../../model/category.dart';
import '../../../../network/habit.dart';
import '../../../../route/route.dart';
import 'widgets.dart';
import '../select-strategy.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';
import 'package:flutter/material.dart';

class CigaretteInformation extends StatefulWidget {
  @override
  _CigaretteInformationState createState() => _CigaretteInformationState();
}

class _CigaretteInformationState extends State<CigaretteInformation> {
  final Category _category = Category.findWhereNameIs('cigarette');

  Map<String, int> data = <String, int>{'target': 0};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (data['target'] == 0) {
          if (!data.containsKey('amount') &&
              !data.containsKey('number') &&
              !data.containsKey('number-per-box') &&
              !data.containsKey('price') &&
              !data.containsKey('nicotine-integer') &&
              !data.containsKey('nicotine-decimal') &&
              !data.containsKey('history-year') &&
              !data.containsKey('history-month')
          ) {
            return true;
          }
        }
        showDialog(
            context: context,
            builder: (context) => MyDialog(
                title: SizedBox(height: 0,),
                body: Text('戻りますか？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 17
                  ),),
                actionText: '戻る',
                action: () {
                  Navigator.pop(context);
                  ApplicationRoutes.popUntil('/startHabit');
                })
        );
        return false;
      },
      child: Scaffold(
        appBar: getMyAppBar(
          context: context,
          backButton: AppBarBackButton.arrow,
          background: AppBarBackground.gray,
          titleText: 'たばこを減らす',
            onBack: () {
              if (data['target'] == 0) {
                if (!data.containsKey('amount') &&
                    !data.containsKey('number') &&
                    !data.containsKey('number-per-box') &&
                    !data.containsKey('price') &&
                    !data.containsKey('nicotine-integer') &&
                    !data.containsKey('nicotine-decimal') &&
                    !data.containsKey('history-year') &&
                    !data.containsKey('history-month')
                ) {
                  ApplicationRoutes.pop();
                  return;
                }
              }
              showDialog(
                  context: context,
                  builder: (context) => MyDialog(
                      title: SizedBox(height: 0,),
                      body: Text('戻りますか？',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).disabledColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 17
                        ),),
                      actionText: '戻る',
                      action: () {
                        Navigator.pop(context);
                        ApplicationRoutes.popUntil('/startHabit');
                      })
              );
            }
        ),
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
                            formatter: InformationFormatter.unit(
                                InformationFormatter.make('target'), '本/日以内'),
                            title: '目標',
                            units: [
                              PickerInformationItemUnit(
                                rollers: [
                                  PickerInformationItemUnitRoller(
                                    name: 'target',
                                    start: 0,
                                    end: 10,
                                    step: 1,
                                    numerator: '本',
                                    denominator: '1日あたり',
                                  )
                                ],
                              )
                            ]),
                      ],
                      onChange: (newValue) {
                        newValue.forEach((key, value) {
                          data[key] = value;
                        });
                        setState(() {});
                      },
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        'これまで',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                    ),
                    InformationItemCards(
                      onChange: (newValue) {
                        newValue.forEach((key, value) {
                          data[key] = value;
                        });
                        setState(() {});
                      },
                      items: [
                        InformationItem(
                            title: '本数',
                            appbarTitle: '本数',
                            formatter: InformationFormatter.unit(
                                InformationFormatter.make('number'), '本/日'),
                            units: [
                              PickerInformationItemUnit(
                                rollers: [
                                  PickerInformationItemUnitRoller(
                                    name: 'number',
                                    start: 0,
                                    end: 100,
                                    step: 1,
                                    numerator: '本',
                                    denominator: '1日あたり',
                                  )
                                ],
                              )
                            ]),
                        InformationItem(
                          units: [
                            FormInformationItemUnit(
                              start: 0,
                              maxDigit: 4,
                              unit: '円',
                              name: 'price',
                              title: '一箱あたりの価格',
                            ),
                            FormInformationItemUnit(
                              start: 20,
                              maxDigit: 2,
                              unit: '本',
                              name: 'number-per-box',
                              title: '一箱あたりの本数',
                            )
                          ],
                          title: '価格',
                          formatter: InformationFormatter.unit(
                              InformationFormatter.make('price'), '円/箱'),
                          appbarTitle: '価格',
                        ),
                        InformationItem(
                          formatter: InformationFormatter.join(
                              InformationFormatter.unit(
                                  InformationFormatter.make('nicotine-integer'),
                                  '.'),
                              InformationFormatter.unit(
                                  InformationFormatter.make('nicotine-decimal'),
                                  'mg')),
                          appbarTitle: 'ニコチン量',
                          units: [
                            PickerInformationItemUnit(
                              rollers: [
                                PickerInformationItemUnitRoller(
                                    start: 0,
                                    end: 2,
                                    step: 1,
                                    numerator: '.',
                                    name: 'nicotine-integer'),
                                PickerInformationItemUnitRoller(
                                    start: 0,
                                    end: 9,
                                    step: 1,
                                    numerator: 'mg',
                                    name: 'nicotine-decimal')
                              ],
                              hintText: '普段吸っている銘柄のニコチン量',
                            ),
                          ],
                          title: 'ニコチン量',
                        ),
                        InformationItem(
                            appbarTitle: '喫煙歴',
                            title: '喫煙歴',
                            formatter: InformationFormatter.join(
                                InformationFormatter.unit(
                                  InformationFormatter.make('history-year'),
                                  '年',
                                ),
                                InformationFormatter.unit(
                                    InformationFormatter.make('history-month'),
                                    'ヶ月')),
                            units: [
                              PickerInformationItemUnit(rollers: [
                                PickerInformationItemUnitRoller(
                                    start: 0,
                                    end: 80,
                                    step: 1,
                                    numerator: '年',
                                    name: 'history-year'),
                                PickerInformationItemUnitRoller(
                                    start: 0,
                                    end: 11,
                                    step: 1,
                                    numerator: 'ヶ月',
                                    name: 'history-month'),
                              ])
                            ])
                      ],
                    )
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
    if (!data.containsKey('target')) {
      return false;
    }
    if (data.containsKey('number')) {
      if (!(data['number'] > 0.0)) {
        return false;
      }
    } else {
      return false;
    }
    if (data.containsKey('price')) {
      if (!(data['price'] > 0.0)) {
        return false;
      }
    } else {
      return false;
    }
    if (data.containsKey('number-per-box')) {
      if (!(data['number-per-box'] > 0.0)) {
        return false;
      }
    } else {
      return false;
    }
    if (data.containsKey('nicotine-integer') &&
        data.containsKey('nicotine-decimal')) {
      if (!(data['nicotine-integer'] > 0.0) &&
          !(data['nicotine-decimal'] > 0.0)) {
        return false;
      }
    } else {
      return false;
    }
    if (data.containsKey('history-year') && data.containsKey('history-month')) {
      if (!(data['history-year'] > 0.0) && !(data['history-month'] > 0.0)) {
        return false;
      }
    } else {
      return false;
    }
    return true;
  }

  Future<void> save(BuildContext ctx) async {
    if (savable()) {
      Map<String, dynamic> _data = <String, dynamic>{};
      _data['average'] = data['number'];
      _data['history'] =
          (data['history-year'] * 12 + data['history-month']);
      _data['nicotine'] =
          data['nicotine-integer'] + data['nicotine-decimal'] * 0.1;
      _data['limit'] = data['target'] > 0 ? data['target'] : null;
      _data['number-per-box'] = data['number-per-box'];
      _data['price'] = data['price'];
      _data['price-unit'] = 'JPY';
      Map<String, dynamic> result =
          await HabitApi.saveInformation(_category, _data);
      SelectStrategyParams params = new SelectStrategyParams(
          recommendStrategies: result['strategies']['recommend'],
          habit: result['habit'],
          otherStrategies: result['strategies']['others']);
      ApplicationRoutes.pushNamed('/strategy/select', params);
    }
  }
}
