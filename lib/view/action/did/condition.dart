import 'package:brebit/view/general/error-widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../model/habit.dart';
import '../../../../model/tag.dart';
import '../../../../provider/condition.dart';
import '../../../../provider/home.dart';
import '../../../../route/route.dart';
import '../../widgets/app-bar.dart';
import '../../widgets/text-field.dart';
import '../circumstance.dart';
import '../widgets/slider.dart';
import '../widgets/tags.dart';

class DidActionParam {
  String systemName;
  String appBarTitle;
  String desireMessage;

  DidActionParam({
    required this.systemName,
    required this.appBarTitle,
    required this.desireMessage,
  });
}

class ConditionDid extends ConsumerStatefulWidget {
  @override
  _ConditionDidState createState() => _ConditionDidState();
}

class _ConditionDidState extends ConsumerState<ConditionDid> {
  @override
  void initState() {
    ref.read(circumstanceSuggestionProvider.notifier).getSuggestions('');
    ref.read(conditionValueProvider.notifier).initialize();
    super.initState();
  }

  final List<DidActionParam> params = <DidActionParam>[
    DidActionParam(
        systemName: 'cigarette',
        appBarTitle: 'たばこを吸ってしまった',
        desireMessage: '吸いたい気持ちはどのくらいでしたか？'),
    DidActionParam(
        systemName: 'alcohol',
        appBarTitle: 'お酒を飲んでしまった',
        desireMessage: '飲みたい気持ちはどのくらいでしたか？'),
    DidActionParam(
        systemName: 'sweets',
        appBarTitle: 'お菓子を食べてしまった',
        desireMessage: '食べたい気持ちはどのくらいでしたか？'),
    DidActionParam(
        systemName: 'sns',
        appBarTitle: 'SNSを覗いてしまった',
        desireMessage: 'SNSを見たい気持ちはどのくらいでしたか？'),
  ];

  @override
  Widget build(BuildContext context) {
    Habit? habit = ref.read(homeProvider.notifier).getHabit();
    if (habit == null) return ErrorToHomeWidget();
    DidActionParam param =
        params.firstWhere((p) => p.systemName == habit.category.systemName);
    return Scaffold(
      appBar: getMyAppBar(titleText: param.appBarTitle, context: context),
      body: Container(
        color: Theme.of(context).primaryColor,
        height: double.infinity,
        child: ConditionDidForm(
          param: param,
          habit: habit,
        ),
      ),
    );
  }
}

class ConditionDidForm extends ConsumerWidget {
  final DidActionParam param;
  final Habit habit;

  ConditionDidForm({required this.param, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextStyle style = TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: Theme.of(context).textTheme.bodyText1?.color);
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
                  ?.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
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
      enable: ref.read(conditionValueProvider.notifier).savable,
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
                      ref
                          .read(conditionValueProvider.notifier)
                          .setDesire(value);
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
                            ref
                                .read(conditionValueProvider.notifier)
                                .setMental(selected);
                          }))
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
                  TagCards(tagUpdate: (List<Tag> tags) {
                    tagUpdate(tags, ref);
                  })
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void tagUpdate(List<Tag> tags, WidgetRef ref) {
    ref.read(conditionValueProvider.notifier).setTags(tags);
  }

  Future<void> save(BuildContext ctx) async {
    ApplicationRoutes.pushNamed('/did/strategy/index');
  }
}

class FeelingTiles extends StatefulWidget {
  final List<Widget> list;
  final Function(MentalValue) onChanged;

  FeelingTiles({required this.list, required this.onChanged});

  @override
  _FeelingTilesState createState() => _FeelingTilesState();
}

class _FeelingTilesState extends State<FeelingTiles> {
  @override
  Widget build(BuildContext context) {
    List<Container> lines = <Container>[];
    List<FeelingTile> tiles = [];
    for (int i = 0; i < widget.list.length; i++) {
      switch (i % 4) {
        case 0:
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
          tiles = [];
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

class FeelingTile extends HookConsumerWidget {
  final void Function() onTap;
  final Widget child;
  final MentalValue mental;
  final EdgeInsets margin;

  FeelingTile(
      {required this.onTap,
      required this.child,
      required this.margin,
      required this.mental});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(conditionValueProvider);
    bool selected =
        ref.read(conditionValueProvider.notifier).mentalIs(this.mental);
    return Expanded(
      child: Container(
        margin: margin,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            padding: EdgeInsets.symmetric(horizontal: 8),
            duration: Duration(milliseconds: 200),
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0),
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

class TagCards extends HookConsumerWidget {
  final Function(List<Tag>) tagUpdate;

  TagCards({required this.tagUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextStyle style = TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: Theme.of(context).textTheme.bodyText1?.color);
    ref.watch(conditionValueProvider);
    if (!ref.read(conditionValueProvider.notifier).isTagsSet()) {
      return InkWell(
          onTap: () {
            CircumstanceParams param = CircumstanceParams(
                selected:
                    ref.read(conditionValueProvider.notifier).getState().tags,
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
    ref.read(conditionValueProvider.notifier).getState().tags.forEach((tag) {
      tags.add(SimpleTagCard(
        name: tag.name,
        onCancel: () {
          ref.read(conditionValueProvider.notifier).removeTag(tag);
        },
      ));
    });
    tags.add(AddTagCard(
      onTap: () {
        CircumstanceParams param = CircumstanceParams(
            selected: ref.read(conditionValueProvider.notifier).getState().tags,
            onSaved: tagUpdate);
        ApplicationRoutes.pushNamed('/circumstance', param);
      },
    ));
    return Tags(
      tags: tags,
    );
  }
}
