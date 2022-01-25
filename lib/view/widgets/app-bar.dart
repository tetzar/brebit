import 'back-button.dart';
import 'package:flutter/material.dart';

enum AppBarBackButton {
  x,
  arrow,
  none,
}

enum AppBarBackground { white, gray }

AppBar getMyAppBar(
    {List<Widget> actions,
    String titleText = '',
    AppBarBackButton backButton = AppBarBackButton.arrow,
    Function onBack,
    AppBarBackground background = AppBarBackground.white,
    @required BuildContext context}) {
  if (background == AppBarBackground.white) {
    if (backButton == AppBarBackButton.none) {
      return AppBar(
        title: getMyAppBarTitle(titleText, context),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: actions,
      );
    } else {
      return AppBar(
        title: getMyAppBarTitle(titleText, context),
        centerTitle: true,
        leading: backButton == AppBarBackButton.arrow
            ? MyBackButton(onPressed: onBack,)
            : MyBackButtonX(onPressed: onBack),
        actions: actions,
      );
    }
  } else {
    if (backButton == AppBarBackButton.none) {
      return AppBar(
        title: getMyAppBarTitle(titleText, context),
        backgroundColor: Theme.of(context).backgroundColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: actions,
      );
    } else {
      return AppBar(
        title: getMyAppBarTitle(titleText, context),
        centerTitle: true,
        backgroundColor: Theme.of(context).backgroundColor,
        leading: backButton == AppBarBackButton.arrow
            ? MyBackButton(onPressed: onBack)
            : MyBackButtonX(onPressed: onBack),
        actions: actions,
      );
    }
  }
}

Text getMyAppBarTitle (String titleString, BuildContext context) {
  TextStyle style = Theme.of(context)
      .textTheme
      .bodyText1
      .copyWith(fontSize: 18, fontWeight: FontWeight.w700);
  return Text(titleString, style: style,);
  }
