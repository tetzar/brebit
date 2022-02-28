import 'dart:ui';

import 'package:flutter/material.dart';

class CustomTheme {
  static getLinkTextStyle(_context) {
    TextStyle linkTextStyle = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      color: Theme.of(_context).accentColor,
      // decoration: TextDecoration.underline,
    );
    return linkTextStyle;
  }
}
