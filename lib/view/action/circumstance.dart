import 'dart:async';

import '../../../model/tag.dart';
import '../../../provider/condition.dart';
import 'widgets/tags.dart';
import '../widgets/back-button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CircumstanceParams {
  List<Tag> selected;
  Function(List<Tag>) onSaved;

  CircumstanceParams({@required this.selected, @required this.onSaved});
}

class Circumstance extends StatelessWidget {
  final CircumstanceParams params;

  Circumstance({@required this.params});

  @override
  Widget build(BuildContext context) {
    context.read(conditionProvider).setList(params.selected);
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

class SaveButton extends HookWidget {
  final CircumstanceParams params;

  SaveButton({@required this.params});

  @override
  Widget build(BuildContext context) {
    useProvider(conditionProvider.state);
    bool savable = context.read(conditionProvider).hasChanged(params.selected);
    return IconButton(
      icon: Icon(Icons.check,
          color: savable
              ? Theme.of(context).appBarTheme.iconTheme.color
              : Theme.of(context).disabledColor),
      onPressed: savable
          ? () {
        save(context);
      } : null,
    );
  }

  void save(BuildContext ctx) {
    params.onSaved(List.from(ctx.read(conditionProvider).getList()));
    Navigator.pop(ctx);
  }
}

class SelectedTags extends StatefulHookWidget {
  @override
  _SelectedTagsState createState() => _SelectedTagsState();
}

class _SelectedTagsState extends State<SelectedTags> {
  @override
  Widget build(BuildContext context) {
    List<Tag> tags = useProvider(conditionProvider.state);
    List<TagCard> tagCards = <TagCard>[];
    tags.forEach((tag) {
      tagCards.add(SimpleTagCard(
        name: tag.name,
        onCancel: () {
          context.read(conditionProvider).unsetFromList(tag);
        },
      ));
    });
    return Tags(tags: tagCards);
  }
}

class SearchForm extends StatefulHookWidget {
  @override
  _SearchFormState createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  Timer _timer;
  TextEditingController _textEditingController;
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
    useProvider(circumstanceSuggestionProvider.state);
    useProvider(conditionProvider.state);
    List<Tag> tags;
    if (_textEditingController.text.length > 0) {
      tags = context.read(circumstanceSuggestionProvider.state).sublist(0);
    } else {
      tags = context.read(circumstanceSuggestionProvider).recommendations.sublist(0);
    }
    tags.removeWhere((tag) =>
    context.read(conditionProvider).isSet(tag.name)
    );
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
                color: Theme.of(context).textTheme.bodyText1.color),
            onChanged: (String text) {
              _timer?.cancel();
              _timer = Timer(Duration(milliseconds: 500), () async {
                if (text.length > 0) {
                  await context
                      .read(circumstanceSuggestionProvider)
                      .getSuggestions(text);
                } else {
                  context
                      .read(circumstanceSuggestionProvider)
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
                                      .color),
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
    ctx.read(conditionProvider).setToList(tag);
  }
}
