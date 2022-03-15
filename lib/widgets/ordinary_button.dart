import 'dart:async';

import 'package:flutter/material.dart';

enum ButtonType { primary, secondary }

typedef OrdinaryButtonCallback = Future<void> Function();

class ButtonState {
  final bool enable;
  ButtonState(this.enable);
}

class OrdinaryButtonSupplier {
  final ButtonType type;
  final String label;
  final OrdinaryButtonCallback onPressed;
  final bool enabled;
  final ThemeData theme;

  StreamController<ButtonState> streamController;
  StreamController<String> labelStreamController;

  OrdinaryButtonSupplier(
      {@required this.type,
      @required this.label,
      @required this.onPressed,
      this.enabled = true,
      @required this.theme}) {
    streamController = StreamController();
    streamController.add(ButtonState(enabled));
    labelStreamController = StreamController();
    labelStreamController.add(this.label);
    _enabled = enabled;
    widget = OrdinaryButton(
      type: type,
      labelStream: labelStreamController.stream,
      onPressed: onPressed,
      closeStream: close,
      stream: streamController.stream,
      theme: theme,
      enabled: _enabled,
    );
  }

  bool _enabled;

  bool get isEnabled => _enabled;

  void close() {
    streamController.close();
    labelStreamController.close();
  }

  void changeLabelText(String t) {
    labelStreamController.add(t);
  }

  void enable(BuildContext context) {
    _enabled = true;
    streamController.add(ButtonState(_enabled));
  }

  void disable(BuildContext context) {
    _enabled = false;
    streamController.add(ButtonState(_enabled));
  }

  OrdinaryButton widget;
}

class OrdinaryButton extends StatefulWidget {
  final ButtonType type;
  final Stream labelStream;
  final OrdinaryButtonCallback onPressed;
  final bool enabled;
  final Stream<ButtonState> stream;
  final Function closeStream;
  final ThemeData theme;

  const OrdinaryButton(
      {@required this.type,
      @required this.labelStream,
      @required this.enabled,
      @required this.onPressed,
      @required this.stream,
      @required this.closeStream,
      @required this.theme,
      Key key})
      : super(key: key);

  @override
  _OrdinaryButtonState createState() => _OrdinaryButtonState();
}

class _OrdinaryButtonState extends State<OrdinaryButton>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<Color> _bgColorAnimation;
  Animation<Color> _textColorAnimation;

  Color _bgEnableColor;
  Color _bgDisableColor;
  Color _textEnableColor;
  Color _textDisableColor;

  bool enabled;

  @override
  void didUpdateWidget(covariant OrdinaryButton oldWidget) {
    widget.stream.listen((event) {
      this.enabled = event.enable;
      if (mounted) {
        startAnimation(this.enabled);
      }
    });
    super.didUpdateWidget(oldWidget);
  }
  @override
  void initState() {
    _bgEnableColor = getEnabledBGColor();
    _bgDisableColor = getDisabledBGColor();
    _textEnableColor = getEnabledTextColor();
    _textDisableColor = getDisabledTextColor();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    CurveTween(curve: Curves.easeInOutQuart).animate(_animationController);
    _bgColorAnimation = ColorTween(begin: _bgDisableColor, end: _bgEnableColor)
        .animate(_animationController);
    _textColorAnimation =
        ColorTween(begin: _textDisableColor, end: _textEnableColor)
            .animate(_animationController);
    enabled = widget.enabled;
    if (enabled) {
      _animationController.value = 1.0;
    } else {
      _animationController.value = 0.0;
    }
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.closeStream();
    super.dispose();
  }

  void startAnimation(bool enabled) {
    if (enabled) {
      _animationController.forward(from: _animationController.value);
    } else {
      _animationController.reverse(from: _animationController.value);
    }
  }

  Color getDisabledBGColor() {
    return widget.theme.disabledColor;
  }

  Color getEnabledBGColor() {
    return widget.theme.accentColor;
  }

  Color getDisabledTextColor() {
    return widget.theme.primaryColor;
  }

  Color getEnabledTextColor() {
    return widget.theme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _bgColorAnimation,
        builder: (context, snapshot) {
          return InkWell(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            onTap: () async {
              if (enabled) await widget.onPressed();
            },
            child: Container(
                width: 300,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                  color: _bgColorAnimation.value,
                ),
                alignment: Alignment.center,
                child: StreamBuilder<String>(
                  stream: widget.labelStream,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _textColorAnimation.value,
                      ),
                    );
                  }
                )),
          );
        });
  }
}
