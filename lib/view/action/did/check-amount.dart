import 'dart:async';

import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../api/habit.dart';
import '../../../../model/category.dart';
import '../../../../model/habit.dart';
import '../../../../provider/condition.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../../general/loading.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';
import 'check_strategy.dart';

final Map<CategoryName, String> appBarTitle = <CategoryName, String>{
  CategoryName.cigarette: 'たばこを吸ってしまった',
  CategoryName.alcohol: 'お酒を飲んでしまった',
  CategoryName.sweets: 'お菓子を食べてしまった',
  CategoryName.sns: 'SNSを見てしまった',
  CategoryName.notCategorized: 'やってしまった',
};

class CheckAmount extends ConsumerWidget {
  final CheckedValue checkedValue;

  CheckAmount({required this.checkedValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Habit? _habit = ref.read(homeProvider.notifier).getHabit();
    if (_habit == null) {
      return ErrorToHomeWidget();
    }
    return Scaffold(
      appBar: getMyAppBar(
        context: context,
        titleText: appBarTitle[_habit.category.name]!,
      ),
      body: InputForm(
        checkedValue: checkedValue,
        habit: _habit,
      ),
    );
  }
}

class InputForm extends ConsumerStatefulWidget {
  final CheckedValue checkedValue;
  final Habit habit;

  InputForm({required this.checkedValue, required this.habit});

  @override
  _InputFormState createState() => _InputFormState();
}

class _InputFormState extends ConsumerState<InputForm> {
  bool savable = false;
  int Function() onSave = () {
    return -1;
  };

  Map<String, String> data = {};

  @override
  void initState() {
    data = {};
    savable = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Habit _habit = widget.habit;
    Widget _form;
    switch (_habit.category.name) {
      case CategoryName.cigarette:
        _form = AmountInputField(
          question: 'たばこを何本吸いましたか',
          unit: '本',
          onChange: (String num) {
            savable = num.length > 0;
            setState(() {});
            data['number'] = num;
          },
          maxDigit: 1,
        );
        onSave = () {
          String? number = data['number'];
          if (number == null) return 0;
          return int.parse(number);
        };
        break;
      case CategoryName.alcohol:
        _form = Column(
          children: [
            AmountInputField(
              question: '飲酒量はどのくらいでしたか？',
              unit: 'ml',
              onChange: (String num) {
                String? concentration = data['concentration'];
                savable = concentration != null &&
                    concentration.length > 0 &&
                    num.length > 0;
                setState(() {});
                data['amount'] = num;
              },
              maxDigit: 5,
            ),
            AmountInputField(
              question: 'アルコール濃度は平均でどのくらいでしたか？',
              unit: '%',
              onChange: (String num) {
                String? amount = data['amount'];
                savable = amount != null && amount.length > 0 && num.length > 0;
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
                  String? amount = data['amount'];
                  if (amount == null) {
                    text = '飲酒量を入力してください';
                  } else {
                    String? concentration = data['concentration'];
                    if (concentration == null) {
                      text = 'アルコール濃度を入力してください';
                    } else {
                      int alcohol =
                          (int.parse(amount) * int.parse(concentration) * 0.01)
                              .toInt();
                      text = '摂取したアルコールは${alcohol}mlです';
                    }
                  }
                  return Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        ?.copyWith(fontSize: 12),
                  );
                },
              ),
            )
          ],
        );
        onSave = () {
          String? amount = data['amount'];
          String? concentration = data['concentration'];
          if (amount == null || concentration == null) return 0;
          return (int.parse(amount) * int.parse(concentration) * 0.01).toInt();
        };
        break;
      case CategoryName.sweets:
        _form = AmountInputField(
          question: 'お菓子をどのくらいたべましたか？',
          unit: 'kcal',
          onChange: (String num) {
            savable = num.length > 0;
            setState(() {});
            data['amount'] = num;
          },
          maxDigit: 6,
        );
        onSave = () {
          String? amount = data['amount'];
          if (amount == null) return 0;
          return int.parse(amount);
        };
        break;
      case CategoryName.sns:
        _form = AmountInputField(
          question: 'SNSをどのくらい使いましたか？',
          unit: '分',
          onChange: (String num) {
            savable = num.length > 0;
            setState(() {});
            data['minutes'] = num;
          },
          maxDigit: 4,
        );
        onSave = () {
          String? minutes = data['minutes'];
          if (minutes == null) return 0;
          return int.parse(minutes);
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
        save(ref);
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

  Future<void> save(WidgetRef ref) async {
    try {
      MyLoading.startLoading();
      int v = onSave();
      ConditionValueState _value =
          ref.read(conditionValueProvider.notifier).getState();
      MentalValue? _mental = _value.mental;
      if (_mental == null) return;
      Map<String, dynamic> result = await HabitApi.did(
          _mental,
          _value.desire.toInt(),
          _value.tags,
          widget.checkedValue.checked,
          v,
          widget.habit);
      ref.read(homeProvider.notifier).setHabit(result['habit']);
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
    required this.question,
    required this.unit,
    required this.onChange,
    required this.maxDigit,
  });

  @override
  _AmountInputFieldState createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  String value = '0';

  late FocusNode _focusNode;
  late TextEditingController _controller;

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
          style: Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 15),
        ),
        MyTextField(
            validate: (String? text) {
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
