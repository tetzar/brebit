
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyBackButton extends StatelessWidget {

  final Function onPressed;

  MyBackButton({
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed == null ? () {
        Navigator.of(context).pop();
      } : onPressed,
      icon: SvgPicture.asset(
        'assets/icon/back.svg',
        height: 32,
          width: 32,
      )
    );
  }
}

class MyBackButtonX extends StatelessWidget {

  final Function onPressed;

  MyBackButtonX({
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.close),
      onPressed: onPressed == null ? () {
        Navigator.of(context).pop();
      } : onPressed,
    );
  }
}

