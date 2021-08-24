import '../../../library/resolver.dart';
import '../../../model/category.dart';
import '../../../model/habit.dart';
import '../../../model/strategy.dart';
import '../../../network/strategy.dart';
import '../../../provider/auth.dart';
import '../../../provider/home.dart';
import '../../../route/route.dart';
import '../strategy/create.dart';
import '../widgets/app-bar.dart';
import '../widgets/dialog.dart';
import '../widgets/strategy-card.dart';
import '../widgets/text-field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SelectedStrategy {
  List<InputFormValue> createdValues = <InputFormValue>[];
  List<InputFormValue> unselectedCreatedValues = <InputFormValue>[];
  List<Strategy> selectedStrategies = <Strategy>[];

  void addCreatedValue(InputFormValue created) {
    int index = createdValues.indexOf(created);
    if (index < 0) {
      createdValues.add(created);
    } else {
      createdValues[index] = created;
    }
  }

  void removeSelectedFromCreated(InputFormValue created) {
    int index = unselectedCreatedValues.indexOf(created);
    if (index < 0) {
      unselectedCreatedValues.add(created);
    } else {
      unselectedCreatedValues[index] = created;
    }
  }

  void addSelectedFromCreated(InputFormValue created) {
    unselectedCreatedValues.remove(created);
  }

  bool isUnselectedCreated(InputFormValue created) {
    return !(unselectedCreatedValues.indexOf(created) < 0);
  }

  List<InputFormValue> getSelectedCreated() {
    List<InputFormValue> _selected = <InputFormValue>[];
    createdValues.forEach((value) {
      if (!this.isUnselectedCreated(value)) {
        _selected.add(value);
      }
    });
    return _selected;
  }

  void selectStrategy(Strategy strategy) {
    int index = selectedStrategies.indexOf(strategy);
    if (index < 0) {
      selectedStrategies.add(strategy);
    } else {
      selectedStrategies[index] = strategy;
    }
  }

  void removeStrategyFromSelected(Strategy strategy) {
    selectedStrategies.remove(strategy);
  }

  bool isSelected(Strategy strategy) {
    return !(selectedStrategies.indexOf(strategy) < 0);
  }
}

SelectedStrategy _selected;

class SelectStrategyParams {
  Habit habit;
  List<Strategy> recommendStrategies = <Strategy>[];
  List<Strategy> otherStrategies = <Strategy>[];

  SelectStrategyParams(
      {this.habit, this.recommendStrategies, this.otherStrategies});
}

class SelectStrategy extends StatelessWidget {
  final SelectStrategyParams params;

  SelectStrategy({@required this.params});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await onPop(context);
        return true;
      },
      child: Scaffold(
        appBar: getMyAppBar(
            context: context,
            background: AppBarBackground.gray,
            titleText: 'ストラテジーを選ぶ',
            onBack: () {
              onPop(context);
            }),
        body: MyBottomFixedButton(
          label: '完了',
          onTapped: () async {
            await save(context);
          },
          enable: true,
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SelectStrategyContent(
                    params: params,
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onPop(BuildContext _ctx) async {
    try {
      Map<String, dynamic> result = await StrategyApi.changeStrategy({
        'selected': [],
        'created': [],
      }, params.habit);
      _ctx.read(homeProvider).setHabit(result['habit']);
      _ctx.read(authProvider).setUser(result['user']);
      ApplicationRoutes.popUntil('/home');
    } catch (e) {
      MyErrorDialog.show(e);
    }
  }

  Future<void> save(BuildContext _ctx) async {
    List<int> selectedStrategyIds = <int>[];
    _selected.selectedStrategies.forEach((strategy) {
      selectedStrategyIds.add(strategy.id);
    });
    List<Map<String, dynamic>> createdData = <Map<String, dynamic>>[];
    _selected.getSelectedCreated().forEach((value) {
      Map<String, dynamic> data = <String, dynamic>{};
      switch (value.strategyCategory) {
        case StrategyCategory.ifThen:
          data['type'] = 'if-then';
          data['if'] = value.getValue('if');
          data['then'] = value.getValue('then');
          break;
        case StrategyCategory.twentySec:
          data['type'] = 'twenty-sec';
          data['action'] = value.getValue('twenty-sec');
          break;
        default:
          return;
          break;
      }
      List<int> tagIds = [];
      List<String> newTags = [];
      value.tags.forEach((tag) {
        if (tag.id == null) {
          newTags.add(tag.name);
        } else {
          tagIds.add(tag.id);
        }
      });
      data['tags'] = tagIds;
      data['new_tags'] = newTags;
      createdData.add(data);
    });
    try {
      Map<String, dynamic> result = await StrategyApi.changeStrategy({
        'selected': selectedStrategyIds,
        'created': createdData,
      }, params.habit);
      _ctx.read(homeProvider).setHabit(result['habit']);
      _ctx.read(authProvider).setUser(result['user']);
      ApplicationRoutes.popUntil('/home');
    } catch (e) {
      MyErrorDialog.show(e);
    }
  }
}

class SelectStrategyContent extends StatefulWidget {
  final SelectStrategyParams params;

  SelectStrategyContent({@required this.params});

  @override
  _SelectStrategyContentState createState() => _SelectStrategyContentState();
}

class _SelectStrategyContentState extends State<SelectStrategyContent> {
  final Map<CategoryName, SvgPicture> icon = <CategoryName, SvgPicture>{
    CategoryName.cigarette: SvgPicture.asset(
      'assets/icon/cigarette.svg',
      height: 20,
    ),
    CategoryName.alcohol: SvgPicture.asset(
      'assets/icon/liquor.svg',
      height: 20,
    ),
    CategoryName.sweets: SvgPicture.asset(
      'assets/icon/sweet.svg',
      height: 20,
    ),
    CategoryName.sns: SvgPicture.asset(
      'assets/icon/sns.svg',
      height: 20,
    ),
    CategoryName.notCategorized: SvgPicture.asset(
      'assets/icon/close.svg',
      height: 20,
    ),
  };

  final Map<CategoryName, String> tag = <CategoryName, String>{
    CategoryName.cigarette: 'たばこを減らす',
    CategoryName.alcohol: 'お酒を控える',
    CategoryName.sweets: 'お菓子を控える',
    CategoryName.sns: 'SNSを控える',
    CategoryName.notCategorized: 'その他',
  };

  @override
  void initState() {
    _selected = new SelectedStrategy();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle _style = Theme.of(context).textTheme.subtitle1;
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'チャレンジ',
            style: _style,
          ),
          Container(
              margin: EdgeInsets.only(top: 8),
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
                      child: icon[widget.params.habit.category.name]),
                  Expanded(
                    child: Text(
                      tag[widget.params.habit.category.name],
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  )
                ],
              )),
          Container(
            margin: EdgeInsets.only(
              top: 16
            ),
            child: Row(
              children: [
                Expanded(
                    child: Container(
                  child: Text(
                    'おすすめ',
                    style: _style,
                  ),
                  alignment: Alignment.centerLeft,
                )),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      child: Text(
                        'ストラテジーとは？',
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Theme.of(context).accentColor),
                      ),
                      onTap: () {
                        print('jump to description');
                      },
                    ),
                  ),
                ),
              ]
            ),
          )
        ]..addAll(widget.params.recommendStrategies
            .map((strategy) => StrategyCard(
          strategy: strategy,
          showFollower: true,
          initialSelected: _selected.isSelected(strategy),
          onSelect: () {
            if (_selected.isSelected(strategy)) {
              _selected.removeStrategyFromSelected(strategy);
              return false;
            } else {
              _selected.selectStrategy(strategy);
              return true;
            }
          },
        ))
            .toList())
          ..add(Container(
            margin: EdgeInsets.only(top: 8),
            child: Text(
              'または',
              style: _style,
            ),
          ))
          ..add(InkWell(
            onTap: () {
              StrategyCreateParams params = StrategyCreateParams(
                  onSaved: (InputFormValue _formValue) async {
                    _selected.addCreatedValue(_formValue);
                    Navigator.pop(context);
                    setState(() {});
                  });
              ApplicationRoutes.pushNamed('/strategy/create', params);
            },
            child: Container(
              margin: EdgeInsets.only(top: 8),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 0),
                    )
                  ]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 21),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: Theme.of(context).textTheme.subtitle1.color,
                    ),
                  ),
                  Expanded(
                    child: Text('カスタムのストラテジーを追加',
                        style: Theme.of(context).textTheme.subtitle1.copyWith(
                            fontWeight: FontWeight.w400, fontSize: 13)),
                  )
                ],
              ),
            ),
          ))
          ..addAll(_selected.createdValues.map((value) {
            Strategy strategy = new Strategy();
            strategy.category = widget.params.habit.category;
            strategy.title = '';
            Map<String, dynamic> data;
            switch (value.strategyCategory) {
              case StrategyCategory.ifThen:
                data = <String, dynamic>{
                  'type': 'if-then',
                  'if': value.getValue('if'),
                  'then': value.getValue('then')
                };
                break;
              case StrategyCategory.twentySec:
                data = <String, dynamic>{
                  'type': 'twenty_sec',
                  'rule': value.getValue('twenty-sec'),
                };
                break;
              default:
                break;
            }
            strategy.body = Resolver.toMap(data);
            strategy.followers = 0;
            return StrategyCard(
              strategy: strategy,
              showFollower: false,
              initialSelected: !_selected.isUnselectedCreated(value),
              onSelect: () {
                if (_selected.isUnselectedCreated(value)) {
                  _selected.addSelectedFromCreated(value);
                  return true;
                } else {
                  _selected.removeSelectedFromCreated(value);
                  return false;
                }
              },
            );
          }).toList())
          ..add(Container(
            margin: EdgeInsets.only(top: 8),
            child: Text(
              'その他',
              style: _style,
            ),
          ))
          ..addAll(
              widget.params.otherStrategies.map((strategy) => StrategyCard(
                strategy: strategy,
                showFollower: true,
                initialSelected: _selected.isSelected(strategy),
                onSelect: () {
                  if (_selected.isSelected(strategy)) {
                    _selected.removeStrategyFromSelected(strategy);
                    return false;
                  } else {
                    _selected.selectStrategy(strategy);
                    return true;
                  }
                },
              )))..add(SizedBox(height: 64,)),
      ),
    );
  }
}
