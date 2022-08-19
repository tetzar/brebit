import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/tag.dart';
import '../../../provider/condition.dart';
import '../widgets/back-button.dart';
import 'widgets/tags.dart';

class CircumstanceParams {
  List<Tag> selected;
  Function(List<Tag>) onSaved;

  CircumstanceParams({required this.selected, required this.onSaved});
}

class Circumstance extends ConsumerWidget {
  final CircumstanceParams params;

  Circumstance({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(conditionProvider.notifier).setList(params.selected);
    return Scaffold(
      appBar: AppBar(
        title: Text('状況を追加'),
        centerTitle: true,
        leading: MyBackButtonX(),
        actions: [SaveButton(params: params)],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SelectedTags(),
              SearchForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class SaveButton extends HookConsumerWidget {
  final CircumstanceParams params;

  SaveButton({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(conditionProvider);
    bool savable =
        ref.read(conditionProvider.notifier).hasChanged(params.selected);
    return IconButton(
      icon: Icon(Icons.check,
          color: savable
              ? Theme.of(context).appBarTheme.iconTheme?.color
              : Theme.of(context).disabledColor),
      onPressed: savable
          ? () {
              save(ref, context);
            }
          : null,
    );
  }

  void save(WidgetRef ref, BuildContext ctx) {
    params.onSaved(List.from(ref.read(conditionProvider.notifier).getList()));
    Navigator.pop(ctx);
  }
}

class SelectedTags extends StatefulHookConsumerWidget {
  @override
  _SelectedTagsState createState() => _SelectedTagsState();
}

class _SelectedTagsState extends ConsumerState<SelectedTags> {
  @override
  Widget build(BuildContext context) {
    ref.watch(conditionProvider);
    List<Tag> tags = ref.read(conditionProvider.notifier).getList();
    List<TagCard> tagCards = <TagCard>[];
    tags.forEach((tag) {
      tagCards.add(SimpleTagCard(
        name: tag.name,
        onCancel: () {
          ref.read(conditionProvider.notifier).unsetFromList(tag);
        },
      ));
    });
    return Tags(tags: tagCards);
  }
}

class SearchForm extends StatefulHookConsumerWidget {
  @override
  _SearchFormState createState() => _SearchFormState();
}

class _SearchFormState extends ConsumerState<SearchForm> {
  Timer? _timer;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    _textEditingController = new TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(circumstanceSuggestionProvider);
    ref.watch(conditionProvider);
    List<Tag> tags;
    if (_textEditingController.text.length > 0) {
      tags = ref
          .read(circumstanceSuggestionProvider.notifier)
          .getState()
          .sublist(0);
    } else {
      tags = ref
          .read(circumstanceSuggestionProvider.notifier)
          .recommendations
          .sublist(0);
    }
    tags.removeWhere(
        (tag) => ref.read(conditionProvider.notifier).isSet(tag.name));
    return Container(
      margin: EdgeInsets.only(top: 16),
      child: Column(
        children: [
          TextFormField(
            controller: _textEditingController,
            decoration: InputDecoration(
                hintText: '状況',
                hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).disabledColor)),
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyText1?.color),
            onChanged: (String text) {
              _timer?.cancel();
              _timer = Timer(Duration(milliseconds: 500), () async {
                if (text.length > 0) {
                  await ref
                      .read(circumstanceSuggestionProvider.notifier)
                      .getSuggestions(text);
                } else {
                  ref
                      .read(circumstanceSuggestionProvider.notifier)
                      .setRecommendation();
                }
              });
            },
          ),
          Container(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tags.length,
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    save(context, tags[index]);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 39,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '#' + tags[index].name,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      ?.color),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              tags[index].getHits().toString() + '件',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).disabledColor),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void save(BuildContext ctx, Tag tag) {
    _textEditingController.clear();
    ref.read(conditionProvider.notifier).setToList(tag);
  }
}
