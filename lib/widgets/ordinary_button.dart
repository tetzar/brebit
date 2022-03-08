import 'package:flutter/material.dart';

import '../../styles/styles.dart';

enum ButtonType {
  Primary,
  Secondary,
  Off,
}

class OrdinaryButton extends StatelessWidget {
  final String text;
  final Function onPressed;
  final double ;


  const OrdinaryButton(this.text, final onPressed, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
