import 'dart:async';

import 'package:brebit/view/general/loading.dart';
import 'package:flutter/material.dart';

import '../../../../api/habit.dart';
import '../../../../model/category.dart';
import '../../../../route/route.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';
import '../select-strategy.dart';
import 'widgets.dart';

class SweetsInformation extends StatefulWidget {
  @override
  _SweetsInformationState createState() => _SweetsInformationState();
}

class _SweetsInformationState extends State<SweetsInformation> {
  final Category _category = Category.findFromCategoryName(CategoryName.sweets);

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
          if (!data.containsKey('amount')) {
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
            titleText: 'お菓子を控える',
            onBack: () {
              if (data['target-amount'] == 0) {
                if (!data.containsKey('amount')) {
                  ApplicationRoutes.pop();
                  return;
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
                              InformationFormatter.make('target-amount'),
                              'kcal/日以内'),
                          title: '目標',
                          units: [
                            FormInformationItemUnit(
                                start: 0,
                                maxDigit: 5,
                                unit: 'kcal',
                                name: 'target-amount',
                                title: '1日あたりの摂取許容量'),
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
                              InformationFormatter.make('amount'), 'kcal/日以内'),
                          title: 'これまで',
                          units: [
                            FormInformationItemUnit(
                                start: 0,
                                maxDigit: 5,
                                unit: 'kcal',
                                name: 'amount',
                                title: '1日あたりの摂取量'),
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
    if (!data.containsKey('target-amount')) {
      return false;
    }
    if (data.containsKey('amount')) {
      if (!(data['amount']! > 0)) {
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
      _data['limit'] = data['target-amount']!.toDouble();
      _data['average'] = data['amount']!.toDouble();
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
