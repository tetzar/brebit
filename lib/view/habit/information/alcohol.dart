import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/category.dart';
import '../../../../network/habit.dart';
import '../../../../route/route.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';
import '../select-strategy.dart';
import 'widgets.dart';

class AlcoholInformation extends StatefulWidget {
  @override
  _AlcoholInformationState createState() => _AlcoholInformationState();
}

class _AlcoholInformationState extends State<AlcoholInformation> {
  final Category _category = Category.findWhereNameIs('alcohol');

  Map<String, int> data = <String, int>{'target-amount': 0};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (data['target-amount'] == 0) {
          if (!data.containsKey('amount') &&
              !data.containsKey('concentration') &&
              !data.containsKey('per-week') &&
              !data.containsKey('price')) {
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
        return false;
      },
      child: Scaffold(
        appBar: getMyAppBar(
            context: context,
            backButton: AppBarBackButton.arrow,
            background: AppBarBackground.gray,
            titleText: 'お酒を控える',
            onBack: () {
              if (data['target-amount'] == 0) {
                if (!data.containsKey('amount') &&
                    !data.containsKey('concentration') &&
                    !data.containsKey('target-concentration') &&
                    !data.containsKey('per-week') &&
                    !data.containsKey('price')) {
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
                          formatter: InformationFormatter.unit(
                              InformationFormatter.multiple(
                                  InformationFormatter.make('target-amount'),
                                  InformationFormatter.divide(
                                      InformationFormatter.make(
                                          'target-concentration'),
                                      InformationFormatter.make('100'))),
                              'ml/日以内'),
                          title: '目標',
                          units: [
                            FormInformationItemUnit(
                                start: 0,
                                maxDigit: 5,
                                unit: 'ml',
                                name: 'target-amount',
                                title: '1日あたりの飲酒の許容量'),
                            FormInformationItemUnit(
                                start: 0,
                                maxDigit: 2,
                                unit: '%',
                                name: 'target-concentration',
                                title: '普段飲むアルコール濃度'),
                            WidgetInformationItemUnit(
                                child: Container(
                              width: double.infinity,
                              alignment: Alignment.topRight,
                              margin: EdgeInsets.only(top: 8),
                              child: HookBuilder(
                                builder: (context) {
                                  useProvider(informationValueProvider.state);
                                  int amount = context
                                      .read(informationValueProvider)
                                      .getValue('target-amount');
                                  int concentration = context
                                      .read(informationValueProvider)
                                      .getValue('target-concentration');
                                  TextStyle _style = Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      .copyWith(fontSize: 12);
                                  if (amount == null) {
                                    return Text(
                                      '飲酒の許容量を入力してください。',
                                      style: _style,
                                    );
                                  }
                                  if (concentration == null) {
                                    return Text(
                                      'アルコール濃度を入力してください',
                                      style: _style,
                                    );
                                  }
                                  if (concentration > 0) {
                                    int alcohol =
                                        (amount * concentration * 0.01).toInt();
                                    return Text(
                                      '目標のアルコール摂取量は${alcohol}mlです',
                                      style: _style,
                                    );
                                  }
                                  return Text(
                                    'アルコール濃度を入力してください',
                                    style: _style,
                                  );
                                },
                              ),
                            ))
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
                          formatter: InformationFormatter.unit(
                              InformationFormatter.multiple(
                                  InformationFormatter.make('amount'),
                                  InformationFormatter.divide(
                                      InformationFormatter.make(
                                          'concentration'),
                                      InformationFormatter.make('100'))),
                              'ml/日以内'),
                          title: 'これまで',
                          units: [
                            FormInformationItemUnit(
                                start: 0,
                                maxDigit: 5,
                                unit: 'ml',
                                name: 'amount',
                                title: '1日あたりの飲酒量'),
                            FormInformationItemUnit(
                                start: 0,
                                maxDigit: 2,
                                unit: '%',
                                name: 'concentration',
                                title: '普段飲むアルコール濃度'),
                            WidgetInformationItemUnit(
                                child: Container(
                              width: double.infinity,
                              alignment: Alignment.topRight,
                              margin: EdgeInsets.only(top: 8),
                              child: HookBuilder(
                                builder: (context) {
                                  useProvider(informationValueProvider.state);
                                  int amount = context
                                      .read(informationValueProvider)
                                      .getValue('amount');
                                  int concentration = context
                                      .read(informationValueProvider)
                                      .getValue('concentration');
                                  TextStyle _style = Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      .copyWith(fontSize: 12);
                                  if (amount == null) {
                                    return Text(
                                      '飲酒の許容量を入力してください。',
                                      style: _style,
                                    );
                                  }
                                  if (amount > 0) {
                                    if (concentration == null) {
                                      return Text(
                                        'アルコール濃度を入力してください',
                                        style: _style,
                                      );
                                    }
                                    if (concentration > 0) {
                                      int alcohol =
                                          (amount * concentration * 0.01)
                                              .toInt();
                                      return Text(
                                        'アルコール摂取量は${alcohol}mlでした',
                                        style: _style,
                                      );
                                    }
                                    return Text(
                                      'アルコール濃度を入力してください',
                                      style: _style,
                                    );
                                  }
                                  return Text(
                                    '飲酒の許容量を入力してください。',
                                    style: _style,
                                  );
                                },
                              ),
                            )),
                            PickerInformationItemUnit(rollers: [
                              PickerInformationItemUnitRoller(
                                start: 0,
                                end: 7,
                                step: 1,
                                name: 'per-week',
                                numerator: '日',
                              ),
                            ], hintText: '一週間にお酒を飲む日数')
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
    return data.containsKey('target-amount') &&
        data.containsKey('concentration') &&
        data['concentration'] > 0 &&
        data.containsKey('target-concentration') &&
        data.containsKey('amount') &&
        data['amount'] > 0 &&
        data.containsKey('per-week') &&
        data['per-week'] > 0;
  }

  Future<void> save(BuildContext ctx) async {
    if (savable()) {
      Map<String, double> _data = <String, double>{};
      _data['target-amount'] = data['target-amount'].toDouble();
      _data['average-amount'] = data['amount'].toDouble();
      _data['limit'] =
          (data['target-amount'] * data['target-concentration']).toDouble();
      _data['average'] = (data['amount'] * data['concentration']).toDouble();
      _data['concentration'] = data['concentration'].toDouble();
      _data['target-concentration'] = data['target-concentration'].toDouble();
      _data['days-per-week'] = data['per-week'].toDouble();
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
