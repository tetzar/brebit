import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../network/profile.dart';

class MyTextField extends StatefulWidget {
  final Function(String text) validate;
  final Function(String text) onSaved;
  final Function(String text) onChanged;
  final Function(String text) onFieldSubmitted;
  final Function(String text) onHintValidate;
  final hintText;
  final AutovalidateMode autoValidateMode;
  final String label;
  final String initialValue;
  final String suffixText;
  final String prefixText;
  final List<TextInputFormatter> inputFormatter;
  final TextInputType keyboardType;
  final int maxLength;
  final int maxLines;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputAction textInputAction;

  MyTextField(
      {@required this.validate,
      this.hintText,
      this.onHintValidate,
      this.suffixText,
      this.prefixText,
      this.onSaved,
      this.onFieldSubmitted,
      this.autoValidateMode,
      this.initialValue,
      @required this.label,
      this.inputFormatter,
      this.maxLength,
      this.maxLines,
      this.controller,
      this.focusNode,
      this.textInputAction,
      this.keyboardType = TextInputType.text,
      this.onChanged});

  @override
  _MyTextFieldState createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  StreamController<List<String>> _streamController;

  @override
  void initState() {
    _streamController = new StreamController<List<String>>();
    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.label,
                    style: Theme.of(context).inputDecorationTheme.labelStyle,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<String>>(
                      stream: _streamController.stream,
                      builder: (context, snapshot) {
                        List<String> messages = snapshot.data ?? [null, null];
                        if (messages.length == 0) {
                          messages = [null, null];
                        } else if (messages.length == 1) {
                          messages..add(null);
                        }
                        String _errorMessage = messages[0];
                        String _hintMessage = messages[1];
                        Widget child;
                        if (_hintMessage != null) {
                          child = Text(
                            _hintMessage,
                            style: Theme.of(context).inputDecorationTheme.errorStyle.copyWith(color: Theme.of(context).accentColor),
                          );
                        }
                        if (_errorMessage != null) {
                          child = Text(
                            _errorMessage,
                            style: Theme.of(context).inputDecorationTheme.errorStyle,
                          );
                        }
                        return AnimatedOpacity(
                          opacity: (_errorMessage == null && _hintMessage == null) ? 0 : 1,
                          duration: Duration(milliseconds: 250),
                          child: Container(alignment: Alignment.centerRight, child: child),
                        );
                      }),
                )
              ],
            ),
          ),
          TextFormField(
            focusNode: widget.focusNode,
            textInputAction: widget.textInputAction,
            controller: widget.controller,
            onFieldSubmitted: widget.onFieldSubmitted,
            initialValue: widget.initialValue,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatter,
            style: TextStyle(color: Theme.of(context).textTheme.bodyText1.color, fontWeight: FontWeight.w400, fontSize: 14),
            autovalidateMode: widget.autoValidateMode,
            onSaved: widget.onSaved,
            onChanged: widget.onChanged,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            scrollPadding: EdgeInsets.all(MyBottomFixedButton.buttonHeight + 20),
            decoration: InputDecoration(
                errorStyle: TextStyle(height: 0),
                suffixText: widget.suffixText,
                suffixStyle: TextStyle(color: Theme.of(context).disabledColor, fontWeight: FontWeight.w700, fontSize: 14),
                isDense: true,
                prefixIcon: widget.prefixText != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text(
                          widget.prefixText,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.subtitle1.copyWith(fontSize: 14),
                        ),
                      )
                    : null,
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                counter: SizedBox(
                  height: 0,
                ),
                hintText: widget.hintText,
                hintStyle: TextStyle(color: Theme.of(context).disabledColor, fontSize: 14, fontWeight: FontWeight.w400)),
            validator: (String text) {
              String errorMessage = widget.validate(text);
              String hintMessage;
              if (widget.onHintValidate != null) {
                hintMessage = widget.onHintValidate(text);
              }
              List<String> messageList = [errorMessage, hintMessage];
              _streamController.sink.add(messageList);
              if (errorMessage == null) {
                return null;
              }
              return '';
            },
          )
        ],
      ),
    );
  }
}

class MyPasswordField extends StatefulWidget {
  final Function(String text) validate;
  final Function(String text) onSaved;
  final Function(String text) onChanged;
  final Function(String text) onFieldSubmitted;
  final TextInputAction textInputAction;
  final FocusNode focusNode;
  final String label;

  MyPasswordField({@required this.validate, this.onSaved, this.onChanged, this.onFieldSubmitted, this.textInputAction, this.label, this.focusNode});

  @override
  _MyPasswordFieldState createState() => _MyPasswordFieldState();
}

class _MyPasswordFieldState extends State<MyPasswordField> {
  StreamController<String> _streamController;

  bool hidden;

  @override
  void initState() {
    hidden = true;
    _streamController = new StreamController<String>();
    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.label ?? 'パスワード',
                    style: Theme.of(context).inputDecorationTheme.labelStyle,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<String>(
                      stream: _streamController.stream,
                      builder: (context, snapshot) {
                        String _errorMessage = snapshot.data;
                        return AnimatedOpacity(
                          opacity: _errorMessage == null ? 0 : 1,
                          duration: Duration(milliseconds: 250),
                          child: Container(
                            alignment: Alignment.centerRight,
                            child: _errorMessage == null
                                ? null
                                : Text(
                                    _errorMessage,
                                    style: Theme.of(context).inputDecorationTheme.errorStyle,
                                  ),
                          ),
                        );
                      }),
                )
              ],
            ),
          ),
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              TextFormField(
                style: TextStyle(color: Theme.of(context).textTheme.bodyText1.color, fontWeight: FontWeight.w400, fontSize: 14),
                scrollPadding: EdgeInsets.all(MyBottomFixedButton.buttonHeight + 20),
                focusNode: widget.focusNode,
                onSaved: widget.onSaved,
                onFieldSubmitted: widget.onFieldSubmitted,
                onChanged: widget.onChanged,
                obscureText: hidden,
                obscuringCharacter: '●',
                textInputAction: widget.textInputAction,
                decoration: InputDecoration(
                    errorStyle: TextStyle(height: 0),
                    suffixStyle: TextStyle(color: Theme.of(context).disabledColor, fontWeight: FontWeight.w700, fontSize: 14),
                    isDense: true,
                    counter: SizedBox(
                      height: 0,
                    ),
                    hintText: '●●●●●●',
                    hintStyle: TextStyle(color: Theme.of(context).disabledColor, fontSize: 14, fontWeight: FontWeight.w400)),
                validator: (String text) {
                  String message = widget.validate(text);
                  _streamController.sink.add(message);
                  if (message == null) {
                    return null;
                  }
                  return '';
                },
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    hidden = !hidden;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 16, bottom: 8),
                  child: Icon(
                    hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: hidden ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyText1.color,
                    size: 24,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class MyBottomFixedButton extends StatelessWidget {
  final Widget child;
  final bool enable;
  final Function onTapped;
  final String label;

  static final buttonHeight = 64.0;

  MyBottomFixedButton({
    @required this.child,
    @required this.label,
    this.onTapped,
    @required this.enable,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            SizedBox(
              height: buttonHeight,
            )
          ],
        )),
        Align(
          alignment: Alignment.bottomCenter,
          child: InkWell(
            onTap: enable ? onTapped : null,
            child: Container(
              height: buttonHeight,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              color: enable ? Theme.of(context).accentColor : Theme.of(context).disabledColor,
              child: Text(
                label,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).buttonTheme.colorScheme.primary),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class MyHookBottomFixedButton extends StatefulHookWidget {
  final Widget child;
  final Function enable;
  final Function onTapped;
  final String label;
  final AutoDisposeStateNotifierProvider provider;

  MyHookBottomFixedButton({@required this.child, @required this.label, this.onTapped, @required this.enable, @required this.provider});

  @override
  _MyHookBottomFixedButtonState createState() => _MyHookBottomFixedButtonState();
}

class _MyHookBottomFixedButtonState extends State<MyHookBottomFixedButton> {
  static final buttonHeight = 64.0;
  StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.child,
            SizedBox(
              height: buttonHeight,
            )
          ],
        )),
        HookBuilder(builder: (BuildContext context) {
          useProvider(widget.provider.state);
          bool t = widget.enable();
          return Align(
            alignment: Alignment.bottomCenter,
            child: InkWell(
              onTap: t ? widget.onTapped : null,
              child: Container(
                height: buttonHeight + MediaQuery.of(context).viewPadding.bottom,
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.topCenter,
                color: t ? Theme.of(context).accentColor : Theme.of(context).disabledColor,
                child: Container(
                  height: buttonHeight,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Text(
                    widget.label,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).buttonTheme.colorScheme.primary),
                  ),
                ),
              ),
            ),
          );
        })
      ],
    );
  }
}

class MyHookFlexibleLabelBottomFixedButton extends StatefulHookWidget {
  final Widget child;
  final Function enable;
  final Function onTapped;
  final Function labelChange;
  final AutoDisposeStateNotifierProvider provider;

  MyHookFlexibleLabelBottomFixedButton({@required this.child, @required this.labelChange, this.onTapped, @required this.enable, @required this.provider});

  @override
  _MyHookFlexibleLabelBottomFixedButtonState createState() => _MyHookFlexibleLabelBottomFixedButtonState();
}

class _MyHookFlexibleLabelBottomFixedButtonState extends State<MyHookFlexibleLabelBottomFixedButton> {
  static final buttonHeight = 64.0;
  StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.child,
            SizedBox(
              height: buttonHeight,
            )
          ],
        )),
        HookBuilder(builder: (BuildContext context) {
          useProvider(widget.provider.state);
          bool t = widget.enable();
          String label = widget.labelChange();
          return Align(
            alignment: Alignment.bottomCenter,
            child: InkWell(
              onTap: t ? widget.onTapped : null,
              child: Container(
                height: buttonHeight + MediaQuery.of(context).viewPadding.bottom,
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.topCenter,
                color: t ? Theme.of(context).accentColor : Theme.of(context).disabledColor,
                child: Container(
                  height: buttonHeight,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).buttonTheme.colorScheme.primary),
                  ),
                ),
              ),
            ),
          );
        })
      ],
    );
  }
}

enum CustomIdFieldState { unchanged, loading, allowed, denied, empty }

typedef void OnUserNameValidate(String t);

typedef Future<void> OnUserNameSaved(String t);

typedef void OnUserNameStateChange(CustomIdFieldState s);

class MyUserNameField extends StatefulWidget {
  final OnUserNameValidate onValidate;
  final OnUserNameSaved onSaved;
  final Function(String text) onFieldSubmitted;
  final OnUserNameStateChange onStateChange;
  final String initialValue;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final bool initialCheck;

  MyUserNameField({
    this.onValidate,
    this.onSaved,
    this.onFieldSubmitted,
    this.focusNode,
    this.initialValue,
    this.onStateChange,
    this.textInputAction,
    this.initialCheck = false,
  });

  @override
  _MyUserNameFieldState createState() => _MyUserNameFieldState();
}

class _MyUserNameFieldState extends State<MyUserNameField> {
  String customId;
  int stack;
  CustomIdFieldState state;

  bool firstBuild;

  @override
  void initState() {
    stack = 0;
    this.customId = widget.initialCheck ? '' : widget.initialValue;
    this.state = CustomIdFieldState.empty;
    firstBuild = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (firstBuild && widget.initialCheck && widget.initialValue.length > 0) {
        firstBuild = false;
        onChange(widget.initialValue);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MyTextField(
      validate: (String text) {
        String error = getError();
        widget.onValidate(error);
        return error;
      },
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.name,
      hintText: 'UserName',
      prefixText: '@',
      onChanged: (String text) async {
        await onChange(text);
      },
      label: 'ユーザーネーム',
      initialValue: widget.initialValue,
      onSaved: (text) async {
        await widget.onSaved(text);
      },
      inputFormatter: [FilteringTextInputFormatter.allow(RegExp(r"^[a-zA-Z0-9_]+$"))],
    );
  }

  void changeState(CustomIdFieldState s) {
    setState(() {
      this.state = s;
    });
    widget.onStateChange(s);
  }

  Future<void> onChange(String text) async {
    changeState(CustomIdFieldState.loading);
    stack++;
    await Future.delayed(Duration(milliseconds: 500));
    stack--;
    if (stack == 0) {
      if (text.length == 0) {
        changeState(CustomIdFieldState.empty);
      } else {
        CustomIdFieldState res = await checkAvailability(text, widget.initialCheck ? '' : widget.initialValue);
        if (res != null) {
          changeState(res);
        }
      }
    }
  }

  Future<CustomIdFieldState> checkAvailability(String input, String initialValue) async {
    if (initialValue == input && !widget.initialCheck) {
      this.customId = input;
      return CustomIdFieldState.unchanged;
    } else {
      if (this.customId != input) {
        bool value = await ProfileApi.customIdAvailable(input);
        this.customId = input;
        if (value) {
          return CustomIdFieldState.allowed;
        } else {
          return CustomIdFieldState.denied;
        }
      } else {
        return null;
      }
    }
  }

  String getError() {
    switch (this.state) {
      case CustomIdFieldState.denied:
        return '既に使用されています';
        break;
      case CustomIdFieldState.empty:
        return 'ユーザーネームを入力してください';
        break;
      default:
        return null;
    }
  }
}
