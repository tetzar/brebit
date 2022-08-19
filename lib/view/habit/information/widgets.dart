import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../route/route.dart';
import '../../widgets/app-bar.dart';

enum InputFormat {
  picker,
  field,
  widget,
}

class InformationFormatter {
  String text = '';

  static InformationFormatter make(String t) {
    return new InformationFormatter()..text = t;
  }

  static InformationFormatter multiple(
      InformationFormatter a, InformationFormatter b) {
    a.text = a.text + ' ' + b.text + ' *';
    return a;
  }

  static InformationFormatter subtract(
      InformationFormatter a, InformationFormatter b) {
    a.text = a.text + ' ' + b.text + ' -';
    return a;
  }

  static InformationFormatter add(
      InformationFormatter a, InformationFormatter b) {
    a.text = a.text + ' ' + b.text + ' +';
    return a;
  }

  static InformationFormatter divide(
      InformationFormatter a, InformationFormatter b) {
    a.text = a.text + ' ' + b.text + ' /';
    return a;
  }

  static InformationFormatter unit(InformationFormatter a, String unit) {
    a.text = '{' + a.text + '}' + unit;
    return a;
  }

  static InformationFormatter join(
      InformationFormatter a, InformationFormatter b) {
    a.text = a.text + b.text;
    return a;
  }

  String format(Map<String, int> data) {
    List<String> foreSplit = this.text.split('{');
    String t = '';
    foreSplit.forEach((split) {
      List<String> backSplit = split.split('}');
      if (backSplit.length == 2) {
        List<double> stack = <double>[];
        for (String? operator in backSplit[0].split(' ')) {
          switch (operator) {
            case '+':
              stack.add(stack.removeLast() + stack.removeLast());
              break;
            case '-':
              double subtract = stack.removeLast();
              stack.add(stack.removeLast() - subtract);
              break;
            case '*':
              stack.add(stack.removeLast() * stack.removeLast());
              break;
            case '/':
              double divide = stack.removeLast();
              stack.add(stack.removeLast() / divide);
              break;
            default:
              bool isNumeric;
              if (operator == null) {
                isNumeric = false;
              } else {
                try {
                  double.parse(operator);
                  isNumeric = true;
                } catch (e) {
                  isNumeric = false;
                }
              }
              if (isNumeric) {
                stack.add(double.parse(operator!));
              } else {
                int? value = data[operator];
                if (value != null) {
                  stack.add(data[operator]!.toDouble());
                }
              }
              break;
          }
        }
        t += stack.removeLast().toInt().toString() + backSplit[1];
      } else {
        t += backSplit[0];
      }
    });
    return t;
  }
}

abstract class InformationItemUnit {
  final String? unit;
  final InputFormat format = InputFormat.field;

  InformationItemUnit({
    this.unit,
  });
}

class PickerInformationItemUnitRoller {
  final int start;
  final int end;
  final int step;
  final String name;
  final String numerator;
  final String? denominator;

  List<int>? _values;

  PickerInformationItemUnitRoller(
      {required this.start,
      required this.end,
      required this.step,
      required this.name,
      required this.numerator,
      this.denominator});

  List<int> getValueList() {
    List<int>? _values = this._values;
    if (_values == null) {
      List<int> list = <int>[];
      int v = start;
      do {
        list.add(v);
        v += step;
      } while (v <= end);
      _values = list;
    }
    return _values;
  }

  int getValue(int index) {
    List<int> _values = this.getValueList();
    return _values[index];
  }
}

class PickerInformationItemUnit extends InformationItemUnit {
  final List<PickerInformationItemUnitRoller> rollers;
  final String? hintText;

  final format = InputFormat.picker;

  PickerInformationItemUnit({
    required this.rollers,
    this.hintText,
  });
}

class FormInformationItemUnit extends InformationItemUnit {
  final int start;
  final int maxDigit;
  final String unit;
  final String title;
  final String name;

  final format = InputFormat.field;

  FormInformationItemUnit(
      {required this.start,
      required this.maxDigit,
      required this.unit,
      required this.name,
      required this.title});
}

class WidgetInformationItemUnit extends InformationItemUnit {
  final int start = 0;
  final Widget child;

  WidgetInformationItemUnit({required this.child});

  final format = InputFormat.widget;
}

class InformationItem {
  final List<InformationItemUnit> units;
  final String title;
  final String appbarTitle;
  final InformationFormatter formatter;

  InformationItem({
    required this.units,
    required this.title,
    required this.appbarTitle,
    required this.formatter,
  });
}

typedef void InformationOnChange(Map<String, int> d);

class InformationItemCards extends ConsumerWidget {
  final List<InformationItem> items;
  final InformationOnChange onChange;

  InformationItemCards({required this.items, required this.onChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(informationValueProvider);
    List<InformationItemCard> cards = <InformationItemCard>[];
    for (InformationItem item in items) {
      cards.add(InformationItemCard(
        item: item,
        onChange: onChange,
      ));
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).primaryColor),
      child: Column(
        children: cards,
      ),
    );
  }
}

class InformationItemCard extends ConsumerStatefulWidget {
  final InformationItem item;
  final InformationOnChange onChange;

  InformationItemCard({required this.item, required this.onChange});

  @override
  _InformationItemCardState createState() => _InformationItemCardState();
}

class _InformationItemCardState extends ConsumerState<InformationItemCard> {
  Map<String, int> selected = {};

  @override
  void initState() {
    selected = <String, int>{};
    for (InformationItemUnit unit in widget.item.units) {
      if (unit.format == InputFormat.picker) {
        PickerInformationItemUnit _unit = unit as PickerInformationItemUnit;
        for (PickerInformationItemUnitRoller roller in _unit.rollers) {
          ref
              .read(informationValueProvider.notifier)
              .setValue(roller.name, roller.start, notify: false);
          selected[roller.name] = 0;
        }
      } else if (unit.format == InputFormat.field) {
        FormInformationItemUnit _unit = unit as FormInformationItemUnit;
        ref
            .read(informationValueProvider.notifier)
            .setValue(_unit.name, _unit.start, notify: false);
        selected[_unit.name] = _unit.start;
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    for (InformationItemUnit unit in widget.item.units) {
      if (unit.format == InputFormat.picker) {
        PickerInformationItemUnit _unit = unit as PickerInformationItemUnit;
        for (PickerInformationItemUnitRoller roller in _unit.rollers) {
          List<int> values = roller.getValueList();
          int? value =
              ref.read(informationValueProvider.notifier).getValue(roller.name);
          if (value != null) {
            int index = values.indexOf(value);
            selected[roller.name] = index;
          }
        }
      } else if (unit.format == InputFormat.field) {
        FormInformationItemUnit _unit = unit as FormInformationItemUnit;
        int? value =
            ref.read(informationValueProvider.notifier).getValue(_unit.name);
        if (value != null) {
          selected[_unit.name] = value;
        }
      }
    }
    String text = widget.item.formatter
        .format(ref.read(informationValueProvider.notifier).getState());
    return InkWell(
      onTap: () {
        showForm(context);
      },
      child: Container(
        height: 72,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.item.title,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      text,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 17),
                    )
                  ],
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icon/forward_arrow.svg',
              height: 18,
            ),
          ],
        ),
      ),
    );
  }

  void showForm(BuildContext context) {
    ApplicationRoutes.push(MaterialPageRoute(
        builder: (context) => InformationInputView(
            item: this.widget.item,
            selected: selected,
            onPop: (Map<String, int> selected) {
              Map<String, int> newValues =
                  ref.read(informationValueProvider.notifier).getState();
              Map<String, int> newSelected = this.selected;
              for (InformationItemUnit unit in widget.item.units) {
                if (unit.format == InputFormat.picker) {
                  PickerInformationItemUnit _unit =
                      unit as PickerInformationItemUnit;
                  for (PickerInformationItemUnitRoller roller
                      in _unit.rollers) {
                    int? v = selected[roller.name];
                    if (v != null) {
                      newValues[roller.name] = roller.getValue(v);
                      newSelected[roller.name] = v;
                    }
                  }
                } else if (unit.format == InputFormat.field) {
                  FormInformationItemUnit _unit =
                      unit as FormInformationItemUnit;

                  int? v = selected[_unit.name];
                  if (v != null) {
                    newValues[_unit.name] = v;
                    newSelected[_unit.name] = v;
                  }
                }
              }
              widget.onChange(newValues);
              ref.read(informationValueProvider.notifier).set(newValues);
              setState(() {
                this.selected = newSelected;
              });
            })));
  }
}

typedef PickerCallback = void Function(Map<String, int>);

class InformationInputView extends ConsumerStatefulWidget {
  final InformationItem item;
  final PickerCallback onPop;
  final Map<String, int> selected;

  InformationInputView({
    required this.item,
    required this.onPop,
    required this.selected,
  });

  @override
  _InformationInputViewState createState() => _InformationInputViewState();
}

class _InformationInputViewState extends ConsumerState<InformationInputView> {
  Map<String, int> selected = {};

  @override
  void initState() {
    selected = widget.selected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = <Widget>[];
    for (InformationItemUnit unit in widget.item.units) {
      if (unit.format == InputFormat.picker) {
        PickerInformationItemUnit _unit = unit as PickerInformationItemUnit;
        List<Widget> pickerWidgets = <Widget>[];
        for (PickerInformationItemUnitRoller roller in _unit.rollers) {
          List<int> _values = roller.getValueList();
          List<Widget> optionWidgets = <Widget>[];
          for (int _value in _values) {
            optionWidgets.add(Center(
              child: Text(_value.toString()),
            ));
          }

          pickerWidgets.add(Expanded(
              child: CupertinoPicker(
                  itemExtent: 40,
                  onSelectedItemChanged: (int i) {
                    selected[roller.name] = i;
                    ref
                        .read(informationValueProvider.notifier)
                        .setValue(roller.name, roller.getValue(i));
                  },
                  scrollController: FixedExtentScrollController(
                      initialItem: widget.selected[roller.name]!),
                  magnification: 1.1,
                  children: optionWidgets)));
          pickerWidgets.add(
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 24),
              height: 40,
              child: Text(
                roller.numerator,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(fontSize: 17),
              ),
            ),
          );
          if (roller.denominator != null) {
            pickerWidgets.add(Expanded(
              child: Container(
                alignment: Alignment.center,
                height: 40,
                child: Text(
                  roller.denominator!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(fontSize: 17),
                ),
              ),
            ));
          }
        }
        if (_unit.hintText != null) {
          widgets.add(Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Text(
              _unit.hintText!,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ));
        }
        widgets.add(Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).primaryColor),
          height: 216,
          child: Center(
            child: Row(
              children: pickerWidgets,
            ),
          ),
        ));
      } else if (unit.format == InputFormat.field) {
        FormInformationItemUnit _unit = unit as FormInformationItemUnit;
        widgets.add(InformationTextField(
            unit: _unit,
            initialValue: ref
                .read(informationValueProvider.notifier)
                .getState()[_unit.name]!,
            onChange: (String text) {
              if (text.length == 0) {
                selected[_unit.name] = 0;
              } else {
                selected[_unit.name] = int.parse(text);
              }
              ref
                  .read(informationValueProvider.notifier)
                  .setValue(_unit.name, int.parse(text));
            }));
      } else {
        WidgetInformationItemUnit _unit = unit as WidgetInformationItemUnit;
        widgets.add(_unit.child);
      }
    }

    return WillPopScope(
      onWillPop: () async {
        widget.onPop(this.selected);
        return true;
      },
      child: Scaffold(
        appBar: getMyAppBar(
            context: context,
            titleText: widget.item.title,
            background: AppBarBackground.gray,
            onBack: () {
              widget.onPop(this.selected);
              Navigator.pop(context);
            }),
        body: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(top: 16, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            ),
          ),
        ),
      ),
    );
  }
}

final informationValueProvider = StateNotifierProvider.autoDispose(
    (ref) => InformationValueProvider(<String, int>{}));

class InformationValueProvider extends StateNotifier<Map<String, int>> {
  InformationValueProvider(Map<String, int> state) : super(state);

  void setValue(String key, int value, {bool notify = true}) {
    state[key] = value;
    if (notify) {
      state = state;
    }
  }

  void set(Map<String, int> data) {
    state = data;
  }

  int? getValue(String key) {
    if (state.containsKey(key)) {
      return state[key];
    } else {
      return null;
    }
  }

  Map<String, int> getState() {
    return state;
  }
}

class InformationTextField extends StatefulWidget {
  final FormInformationItemUnit unit;
  final int initialValue;
  final Function onChange;

  InformationTextField({
    required this.unit,
    required this.initialValue,
    required this.onChange,
  });

  @override
  _InformationTextFieldState createState() => _InformationTextFieldState();
}

class _InformationTextFieldState extends State<InformationTextField> {
  late TextEditingController _controller;
  late FocusNode _node;

  @override
  void initState() {
    _controller = new TextEditingController();
    _controller.text = widget.initialValue.toString();
    _node = new FocusNode();
    _node.addListener(() {
      if (_node.hasFocus) {
        if (_controller.text == '0') {
          _controller.text = '';
        }
      } else {
        if (_controller.text.length == 0) {
          _controller.text = 0.toString();
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = <Widget>[];
    columnChildren.add(
        Text(widget.unit.title, style: Theme.of(context).textTheme.subtitle1));
    columnChildren.add(Container(
      margin: EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          TextFormField(
            focusNode: _node,
            controller: _controller,
            decoration: InputDecoration(
                fillColor: Theme.of(context).primaryColor,
                suffixText: widget.unit.unit,
                suffixStyle: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
                counter: SizedBox(
                  height: 0,
                )),
            style: Theme.of(context)
                .textTheme
                .bodyText1
                ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
            keyboardType: TextInputType.number,
            maxLength: widget.unit.maxDigit,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(
                r'^[1-9][0-9]*|0$',
              ))
            ],
            onChanged: (String text) {
              if (text.length > 0) {
                widget.onChange(text);
              } else {
                widget.onChange('0');
              }
            },
          ),
        ],
      ),
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnChildren,
    );
  }
}
