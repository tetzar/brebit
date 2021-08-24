import '../../../model/tag.dart';
import '../../../provider/condition.dart';
import '../../../route/route.dart';
import '../action/circumstance.dart';
import '../action/widgets/tags.dart' as TagWidgets;
import '../general/loading.dart';
import '../widgets/app-bar.dart';
import '../widgets/back-button.dart';
import '../widgets/dialog.dart';
import '../widgets/text-field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef StrategyCreateCallback = Future<void> Function(InputFormValue);

class StrategyCreateParams {
  StrategyCreateCallback onSaved;

  StrategyCreateParams({@required this.onSaved});
}

final inputProvider = StateNotifierProvider.autoDispose((ref) => InputProvider(false));

class InputProvider extends StateNotifier<bool> {
  InputProvider(bool state) : super(state);

  void set(bool s) {
    if (state != s) {
      state = s;
    }
  }

  bool get() {
    return state;
  }
}

class StrategyCreate extends StatefulWidget {
  final StrategyCreateParams params;

  StrategyCreate({@required this.params});

  @override
  _StrategyCreateState createState() => _StrategyCreateState();
}

class _StrategyCreateState extends State<StrategyCreate> {
  @override
  void initState() {
    context.read(inputProvider).set(false);
    context.read(circumstanceSuggestionProvider).getSuggestions('');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getMyAppBar(
            actions: <Widget>[MyBackButtonX()],
            titleText: 'ストラテジーを作成',
            backButton: AppBarBackButton.none,
            background: AppBarBackground.gray,
            context: context),
        body: MyHookBottomFixedButton(
          label: '保存',
          enable: () {
            return context.read(inputProvider).get();
          },
          onTapped: () async {
            await save(context);
          },
          provider: inputProvider,
          child: Container(
              width: MediaQuery.of(context).size.width, child: StrategyForm()),
        ));
  }

  Future<void> save(BuildContext context) async {
    try {
      MyLoading.startLoading();
      await widget.params.onSaved(
          _formValue
      );
      MyLoading.dismiss();
    } catch (e) {
      await MyLoading.dismiss();
      MyErrorDialog.show(e);
    }
  }
}

enum StrategyCategory { ifThen, twentySec }

class InputFormValue {
  StrategyCategory strategyCategory;
  Map<String, String> data = <String, String>{};
  List<Tag> tags = <Tag>[];

  void setValue(String label, String value) {
    data[label] = value;
  }

  String getValue(String label) {
    if (data.containsKey(label)) {
      return data[label];
    }
    return '';
  }

  void setTag(Tag tag) {
    int index = tags.indexWhere((existingTag) => existingTag.name == tag.name);
    if (index < 0) {
      tags.add(tag);
    } else {
      tags[index] = tag;
    }
  }

  void unsetTag(Tag tag) {
    tags.removeWhere((t) => t.name == tag.name);
  }

  bool savable() {
    switch (strategyCategory) {
      case StrategyCategory.ifThen:
        return getValue('if').length > 0 && getValue('then').length > 0;
        break;
      case StrategyCategory.twentySec:
        return getValue('twenty-sec').length > 0;
        break;
      default:
        return false;
        break;
    }
  }
}

class StrategyForm extends StatefulWidget {
  @override
  _StrategyFormState createState() => _StrategyFormState();
}

InputFormValue _formValue;
// final ScrollController _controller = new ScrollController();

class _StrategyFormState extends State<StrategyForm> {
  StrategyCategory strategyCategory;
  FocusNode node = FocusNode();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    strategyCategory = StrategyCategory.ifThen;
    _formValue = new InputFormValue();
    _formValue.strategyCategory = strategyCategory;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget strategyForm;
    switch (strategyCategory) {
      case StrategyCategory.ifThen:
        strategyForm = IfThenForm();
        break;
      case StrategyCategory.twentySec:
        strategyForm = TwentySecForm();
        break;
      default:
        strategyForm = Container();
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    if (strategyCategory != StrategyCategory.ifThen) {
                      _formValue.strategyCategory = StrategyCategory.ifThen;
                      context.read(inputProvider).set(_formValue.savable());
                      setState(() {
                        strategyCategory = StrategyCategory.ifThen;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8)),
                        color: Theme.of(context).primaryColor),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text('If-Then プランニング',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17)),
                        ),
                        Icon(
                          Icons.check,
                          size: 17,
                          color: _formValue.strategyCategory ==
                              StrategyCategory.ifThen
                              ? Theme.of(context).textTheme.bodyText1.color
                              : Theme.of(context).primaryColor,
                        )
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (strategyCategory != StrategyCategory.twentySec) {
                      _formValue.strategyCategory =
                          StrategyCategory.twentySec;
                      context.read(inputProvider).set(_formValue.savable());
                      setState(() {
                        strategyCategory = StrategyCategory.twentySec;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8)),
                        color: Theme.of(context).primaryColor),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text('20秒ルール',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17)),
                        ),
                        Icon(
                          Icons.check,
                          size: 17,
                          color: _formValue.strategyCategory ==
                              StrategyCategory.twentySec
                              ? Theme.of(context).textTheme.bodyText1.color
                              : Theme.of(context).primaryColor,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  print('jump to strategy explanation page');
                },
                child: Text(
                  'ストラテジーとは？',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).accentColor,
                      decoration: TextDecoration.underline),
                ),
              )),
          strategyForm,
          Tags(),
        ],
      ),
    );
  }
}

class IfThenForm extends StatefulWidget {
  @override
  _IfThenFormState createState() => _IfThenFormState();
}

class _IfThenFormState extends State<IfThenForm> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FocusScope(
        child: Column(
          children: [
            StrategyInputField(
              label: 'If',
              hintText: '条件',
              onChanged: (String text) {
                _formValue.setValue('if', text);
                context.read(inputProvider).set(_formValue.savable());
              },
              inputAction: TextInputAction.next,
              initialValue: _formValue.getValue('if'),
            ),
            StrategyInputField(
              label: 'Then',
              hintText: '行動',
              onChanged: (String text) {
                _formValue.setValue('then', text);
                context.read(inputProvider).set(_formValue.savable());
              },
              inputAction: TextInputAction.done,
              initialValue: _formValue.getValue('if'),
            )
          ],
        ),
      ),
    );
  }
}

class TwentySecForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StrategyInputField(
        label: '行動を20秒増やすためのルール',
        hintText: '行動',
        onChanged: (String text) {
          _formValue.setValue('twenty-sec', text);
          context.read(inputProvider).set(_formValue.savable());
        },
        inputAction: TextInputAction.done,
        initialValue: _formValue.getValue('twenty-sec'),
      ),
    );
  }
}

class StrategyInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final String initialValue;
  final List<TextInputFormatter> inputFormatter;
  final AutovalidateMode autoValidateMode;
  final Function onSaved;
  final Function onChanged;
  final FocusNode focusNode;
  final Function editComplete;
  final ScrollController scrollController;
  final TextInputAction inputAction;

  StrategyInputField(
      {@required this.label,
      @required this.hintText,
      this.onChanged,
      this.inputAction = TextInputAction.none,
      this.onSaved,
      this.initialValue,
      this.autoValidateMode,
      this.inputFormatter,
      this.focusNode,
      this.editComplete,
      this.scrollController});

  @override
  _StrategyInputFieldState createState() => _StrategyInputFieldState();
}

class _StrategyInputFieldState extends State<StrategyInputField> {
  TextEditingController _textEditingController;

  final double inputAreaPosition = 150;

  @override
  void initState() {
    _textEditingController = TextEditingController.fromValue(TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.fromPosition(
            TextPosition(offset: widget.initialValue.length))));
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // _textController.
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(top: 24, bottom: 8),
            child: Text(widget.label,
                style: Theme.of(context).textTheme.subtitle1),
          ),
          Container(
            height: 52,
            // child: FocusScope(
            child: Focus(
              // onFocusChange: (bool focused) {
              //   if (focused) {
              //     _controller.animateTo(inputAreaPosition,
              //         duration: Duration(milliseconds: 200),
              //         curve: Curves.easeIn);
              //   }
              // },
              child: TextField(
                  controller: _textEditingController,
                  focusNode: widget.focusNode,
                  // scrollController: widget.scrollController,
                  textInputAction: widget.inputAction,
                  // inputFormatters: widget.inputFormatter,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 17),
                  // onEditingComplete: widget.editComplete,
                  onChanged: (String text) {
                    // _controller.animateTo(inputAreaPosition,
                    //     duration: Duration(milliseconds: 200),
                    //     curve: Curves.easeIn);
                    if (widget.onChanged != null) {
                      widget.onChanged(text);
                    }
                  },
                  decoration: InputDecoration(
                      errorStyle: TextStyle(height: 0),
                      fillColor: Theme.of(context).primaryColor,
                      hintText: widget.hintText,
                      hintStyle: Theme.of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 17),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent)))),
            ),
          ),
          // )
        ],
      ),
    );
  }
}

class Tags extends StatefulWidget {
  @override
  _TagsState createState() => _TagsState();
}

class _TagsState extends State<Tags> {
  List<Tag> tags;

  @override
  void initState() {
    tags = _formValue.tags;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (tags.length == 0) {
      return Container(
        margin: EdgeInsets.only(top: 41),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                selectTag(context);
              },
              child: Container(
                height: 52,
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).primaryColor),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '状況を追加',
                        style: Theme.of(context).textTheme.bodyText1.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    )
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 8),
              child: Text(
                'どんな状況で使えるか登録すると、他のユーザーにあなたのストラテジーが表示されやすくなります。',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            )
          ],
        ),
      );
    }
    List<TagWidgets.TagCard> tagCards = <TagWidgets.TagCard>[];
    tags.forEach((tag) {
      tagCards.add(TagWidgets.SimpleTagCard(
        name: tag.name,
        onCancel: () {
          _formValue.unsetTag(tag);
          setState(() {
            tags = _formValue.tags;
          });
        },
      ));
    });
    tagCards.add(TagWidgets.AddTagCard(
      onTap: () {
        selectTag(context);
      },
    ));
    return Container(
      margin: EdgeInsets.only(top: 40),
      child: TagWidgets.Tags(
        tags: tagCards,
      ),
    );
  }

  void selectTag(BuildContext context) {
    final FocusScopeNode currentScope = FocusScope.of(context);
    if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
      FocusManager.instance.primaryFocus.unfocus();
    }
    CircumstanceParams params = new CircumstanceParams(
        selected: tags,
        onSaved: (List<Tag> selectedTags) {
          _formValue.tags = selectedTags;
          setState(() {
            tags = selectedTags;
          });
        });
    ApplicationRoutes.pushNamed('/circumstance', params);
  }
}
