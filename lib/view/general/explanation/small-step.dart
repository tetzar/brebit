
import '../../widgets/app-bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SmallStepExplanation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context
      ),
      body: Container(
        alignment: Alignment.center,
        child: Text(
            'This screen explains small step '
        ),
      ),
    );
  }
}
