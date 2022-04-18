import 'dart:async';

import '../../../../model/category.dart';
import '../../../../model/habit.dart';
import '../../../../api/habit.dart';
import '../../../../provider/condition.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import 'check_strategy.dart';
import '../../general/loading.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final Map<CategoryName, String> appBarTitle = <CategoryName, String>{
  CategoryName.cigarette: 'たばこを吸ってしまった',
  CategoryName.alcohol: 'お酒を飲んでしまった',
  CategoryName.sweets: 'お菓子を食べてしまった',
  CategoryName.sns: 'SNSを見てしまった',
  CategoryName.notCategorized: 'やってしまった',
};

class CheckAmount extends StatelessWidget {
  final CheckedValue checkedValue;

  CheckAmount({this.checkedValue});

  @override
  Widget build(BuildContext context) {
    Habit _habit = context.read(homeProvider).getHabit();
    return Scaffold(
      appBar: getMyAppBar(
        context: context,
        titleText: appBarTitle[_habit.category.name],
      ),
      body: InputForm(
        checkedValue: checkedValue,
      ),
    );
  }
}

class InputForm extends StatefulWidget {
  final CheckedValue checkedValue;

  InputForm({@required this.checkedValue});

  @override
  _InputFormState createState() => _InputFormState();
}

class _InputFormState extends State<InputForm> {
  bool savable;
  Function onSave;

  Map<String, String> data;

  @override
  void initState() {
    data = <String, String>{};
    savable = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Habit _habit = context.read(homeProvider).getHabit();
    Widget _form;
    switch (_habit.category.name) {
      case CategoryName.cigarette:
        _form = AmountInputField(
          question: 'たばこを何本吸いましたか',
          unit: '本',
          onChange: (String num) {
            if (num.length > 0) {
              savable = true;
            } else {
              savable = false;
            }
            setState(() {});
            data['number'] = num;
          },
          maxDigit: 1,
        );
        onSave = () {
          return int.parse(data['number']);
        };
        break;
      case CategoryName.alcohol:
        _form = Column(
          children: [
            AmountInputField(
              question: '飲酒量はどのくらいでしたか？',
              unit: 'ml',
              onChange: (String num) {
                savable = false;
                if (data['concentration'] != null) {
                  if (num.length > 0 && data['concentration'].length > 0) {
                    savable = true;
                  }
                }
                setState(() {});
                data['amount'] = num;
              },
              maxDigit: 5,
            ),
            AmountInputField(
              question: 'アルコール濃度は平均でどのくらいでしたか？',
              unit: '%',
              onChange: (String num) {
                savable = false;
                if (data['amount'] != null) {
                  if (num.length > 0 && data['amount'].length > 0) {
                    savable = true;
                  }
                }
                setState(() {});
                data['concentration'] = num;
              },
              maxDigit: 2,
            ),
            Container(
              width: double.infinity,
              alignment: Alignment.topRight,
              child: Builder(
                builder: (context) {
                  String text;
                  if (data['amount'] == null) {
                    text = '飲酒量を入力してください';
                  } else {
                    if (data['concentration'] == null) {
                      text = 'アルコール濃度を入力してください';
                    } else {
                      int alcohol = (int.parse(data['amount']) *
                              int.parse(data['concentration']) *
                              0.01)
                          .toInt();
                      text = '摂取したアルコールは${alcohol}mlです';
                    }
                  }
                  return Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        .copyWith(fontSize: 12),
                  );
                },
              ),
            )
          ],
        );
        onSave = () {
          return (int.parse(data['amount']) *
                  int.parse(data['concentration']) *
                  0.01)
              .toInt();
        };
        break;
      case CategoryName.sweets:
        _form = AmountInputField(
          question: 'お菓子をどのくらいたべましたか？',
          unit: 'kcal',
          onChange: (String num) {
            if (num.length > 0) {
              savable = true;
            } else {
              savable = false;
            }
            setState(() {});
            data['amount'] = num;
          },
          maxDigit: 6,
        );
        onSave = () {
          return int.parse(data['amount']);
        };
        break;
      case CategoryName.sns:
        _form = AmountInputField(
          question: 'SNSをどのくらい使いましたか？',
          unit: '分',
          onChange: (String num) {
            if (num.length > 0) {
              savable = true;
            } else {
              savable = false;
            }
            setState(() {});
            data['minutes'] = num;
          },
          maxDigit: 4,
        );
        onSave = () {
          return int.parse(data['minutes']);
        };
        break;
      default:
        _form = SizedBox(
          height: 0,
        );
    }
    return MyBottomFixedButton(
      enable: savable,
      onTapped: () {
        save(context);
      },
      label: '次へ',
      child: Container(
          color: Theme.of(context).primaryColor,
          height: double.infinity,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: _form,
              ),
            ],
          )),
    );
  }

  Future<void> save(BuildContext ctx) async {
    try {
      MyLoading.startLoading();
      int v = onSave();
      ConditionValueState _value = ctx.read(conditionValueProvider.state);
      Map<String, dynamic> result = await HabitApi.did(
          _value.mental,
          _value.desire.toInt(),
          _value.tags,
          widget.checkedValue.checked,
          v,
          ctx.read(homeProvider.state).habit);
      ctx.read(homeProvider).setHabit(result['habit']);
      await MyLoading.dismiss();
      ApplicationRoutes.popUntil('/home');
      ApplicationRoutes.pushNamed('/did/confirmation', result['log']);
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}

typedef void OnChange(String t);

class AmountInputField extends StatefulWidget {
  final String question;
  final String unit;
  final int maxDigit;
  final OnChange onChange;

  AmountInputField({
    @required this.question,
    @required this.unit,
    @required this.onChange,
    @required this.maxDigit,
  });

  @override
  _AmountInputFieldState createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  String value;

  FocusNode _focusNode;
  TextEditingController _controller;

  @override
  void initState() {
    value = '0';
    _controller = TextEditingController();
    _controller.text = value;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        if (_controller.text == '0') {
          _controller.text = '';
        }
      } else {
        if (_controller.text.length == 0) {
          _controller.text = '0';
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question,
          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 15),
        ),
        MyTextField(
            validate: (String text) {
              return null;
            },
            keyboardType: TextInputType.number,
            inputFormatter: [
              FilteringTextInputFormatter.allow(RegExp(r"[1-9][0-9]*"))
            ],
            suffixText: widget.unit,
            controller: _controller,
            focusNode: _focusNode,
            maxLength: widget.maxDigit,
            onChanged: (String num) {
              widget.onChange(num);
            },
            label: '')
      ],
    );
  }
}
