import '../../../../model/habit.dart';
import '../../../../model/strategy.dart';
import '../../../../model/tag.dart';
import '../../../../api/strategy.dart';
import '../../../../provider/condition.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import 'execute_strategy.dart';
import '../widgets/slider.dart';
import '../widgets/tags.dart';
import '../../general/loading.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/dialog.dart';
import '../../widgets/text-field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../circumstance.dart';

class WannaActionParam {
  String systemName;
  String appBarTitle;
  String desireMessage;

  WannaActionParam({
    @required this.systemName,
    @required this.appBarTitle,
    @required this.desireMessage,
  });
}

class ConditionWanna extends StatefulWidget {
  @override
  _ConditionWannaState createState() => _ConditionWannaState();
}

class _ConditionWannaState extends State<ConditionWanna> {
  @override
  void initState() {
    context.read(circumstanceSuggestionProvider).getSuggestions('');
    context.read(conditionValueProvider).initialize();
    super.initState();
  }

  final List<WannaActionParam> params = <WannaActionParam>[
    WannaActionParam(
        systemName: 'cigarette',
        appBarTitle: 'たばこを吸いたい',
        desireMessage: 'どのくらい吸いたいですか？'),
    WannaActionParam(
        systemName: 'alcohol',
        appBarTitle: 'お酒を飲みたい',
        desireMessage: 'どのくらい飲みたいですか？'),
    WannaActionParam(
        systemName: 'sweets',
        appBarTitle: 'お菓子を食べたい',
        desireMessage: 'どのくらい食べたいですか？'),
    WannaActionParam(
        systemName: 'sns',
        appBarTitle: 'SNSを見たい',
        desireMessage: 'どのくらい見たいですか？'),
  ];

  @override
  Widget build(BuildContext context) {
    Habit habit = context.read(homeProvider).getHabit();
    WannaActionParam param =
        params.firstWhere((p) => p.systemName == habit.category.systemName);
    return Scaffold(
      appBar: getMyAppBar(
        context: context,
        titleText: param.appBarTitle
      ),
      body: Container(
        color: Theme.of(context).primaryColor,
        height: double.infinity,
        child: ConditionDidForm(param: param),
      ),
    );
  }
}

class ConditionDidForm extends StatelessWidget {
  final WannaActionParam param;

  ConditionDidForm({this.param});

  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: Theme.of(context).textTheme.bodyText1.color);
    List<Widget> feelingTiles = <Widget>[];
    MentalValue.mentalValues.forEach((mentalValue) {
      feelingTiles.add(Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mentalValue.name,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w400),
            ),
            SvgPicture.asset(
              mentalValue.picturePath,
              height: 35,
              width: 35,
            )
          ],
        ),
      ));
    });
    return MyHookBottomFixedButton(
      provider: conditionValueProvider,
      enable: context.read(conditionValueProvider).savable,
      label: '次へ',
      onTapped: () async {
        await save(context);
      },
      child: Container(
        padding: EdgeInsets.only(top: 24, left: 24, right: 24),
        child: Column(
          children: [
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    param.desireMessage,
                    style: style,
                  ),
                  MySlider(
                    onChanged: (double value) {
                      context.read(conditionValueProvider).setDesire(value);
                    },
                    min: 0,
                    max: 10,
                    divisions: 10,
                    initialValue: 0,
                  ),
                ],
              ),
            ),
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      top: 16,
                    ),
                    child: Text(
                      'どんな気分ですか？',
                      style: style,
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 8),
                      child: FeelingTiles(
                          list: feelingTiles,
                          onChanged: (MentalValue selected) {
                            context
                                .read(conditionValueProvider)
                                .setMental(selected);
                          }))
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
                  TagCards(tagUpdate: (List<Tag> tags) {
                    tagUpdate(tags, context);
                  })
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void tagUpdate(List<Tag> tags, BuildContext ctx) {
    ctx.read(conditionValueProvider).setTags(tags);
  }

  Future<void> save(BuildContext ctx) async {
    MyLoading.startLoading();
    List<Strategy> recommendedStrategies;
    try {
      recommendedStrategies =
          await StrategyApi.getRecommendStrategiesFromCondition(
              ctx.read(conditionValueProvider.state).tags, {
        'desire': ctx.read(conditionValueProvider.state).desire.toInt(),
        'mental': ctx.read(conditionValueProvider.state).mental.id
      });
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
      return;
    }
    ExecuteStrategyWannaParam params = ExecuteStrategyWannaParam();
    params.recommends = recommendedStrategies;
    await MyLoading.dismiss();
    ApplicationRoutes.pushNamed('/want/strategy/index', params);
  }
}

class FeelingTiles extends StatefulWidget {
  final List<Widget> list;
  final Function(MentalValue) onChanged;

  FeelingTiles({@required this.list, @required this.onChanged});

  @override
  _FeelingTilesState createState() => _FeelingTilesState();
}

class _FeelingTilesState extends State<FeelingTiles> {
  @override
  Widget build(BuildContext context) {
    List<Container> lines = <Container>[];
    List<FeelingTile> tiles;
    for (int i = 0; i < widget.list.length; i++) {
      switch (i % 4) {
        case 0:
          tiles = <FeelingTile>[];
          tiles.add(FeelingTile(
            onTap: () {
              select(MentalValue.mentalValues[i]);
            },
            mental: MentalValue.mentalValues[i],
            child: widget.list[i],
            margin: EdgeInsets.only(right: 4),
          ));
          break;
        case 3:
          tiles.add(FeelingTile(
            onTap: () {
              select(MentalValue.mentalValues[i]);
            },
            child: widget.list[i],
            margin: EdgeInsets.only(left: 4),
            mental: MentalValue.mentalValues[i],
          ));
          lines.add(Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              children: tiles,
            ),
          ));
          break;
        default:
          tiles.add(FeelingTile(
            onTap: () {
              select(MentalValue.mentalValues[i]);
            },
            mental: MentalValue.mentalValues[i],
            child: widget.list[i],
            margin: EdgeInsets.symmetric(horizontal: 4),
          ));
          break;
      }
    }
    if (tiles.length < 4) {
      lines.add(Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Row(
          children: tiles,
        ),
      ));
    }
    return Column(
      children: lines,
    );
  }

  void select(MentalValue selectedItem) {
    widget.onChanged(selectedItem);
  }
}

class FeelingTile extends HookWidget {
  final Function onTap;
  final Widget child;
  final MentalValue mental;
  final EdgeInsets margin;

  FeelingTile(
      {@required this.onTap,
      @required this.child,
      this.margin,
      @required this.mental});

  @override
  Widget build(BuildContext context) {
    useProvider(conditionValueProvider.state);
    bool selected = context.read(conditionValueProvider).mentalIs(this.mental);
    return Expanded(
      child: Container(
        margin: margin,
        child: InkWell(
          onTap: () {
            onTap();
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                border: Border.all(
                    color: selected
                        ? Theme.of(context).accentColor
                        : Theme.of(context).accentColor.withOpacity(0),
                    width: 2),
                color: Theme.of(context).primaryColorLight),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

class TagCards extends HookWidget {
  final Function(List<Tag>) tagUpdate;

  TagCards({@required this.tagUpdate});

  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: Theme.of(context).textTheme.bodyText1.color);
    useProvider(conditionValueProvider.state);
    if (!context.read(conditionValueProvider).isTagsSet()) {
      return InkWell(
          onTap: () {
            CircumstanceParams param = CircumstanceParams(
                selected: context.read(conditionValueProvider.state).tags,
                onSaved: (List<Tag> tags) {
                  tagUpdate(tags);
                });
            ApplicationRoutes.pushNamed('/circumstance', param);
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '状況を追加',
                      style: style,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      child: Icon(
                        Icons.arrow_forward_ios_outlined,
                        size: 15,
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.49, horizontal: 11.87),
                    ),
                  ),
                )
              ],
            ),
          ));
    }
    List<TagCard> tags = <TagCard>[];
    context.read(conditionValueProvider.state).tags.forEach((tag) {
      tags.add(SimpleTagCard(
        name: tag.name,
        onCancel: () {
          context.read(conditionValueProvider).removeTag(tag);
        },
      ));
    });
    tags.add(AddTagCard(
      onTap: () {
        CircumstanceParams param = CircumstanceParams(
            selected: context.read(conditionValueProvider.state).tags,
            onSaved: tagUpdate);
        ApplicationRoutes.pushNamed('/circumstance', param);
      },
    ));
    return Tags(
      tags: tags,
    );
  }
}
