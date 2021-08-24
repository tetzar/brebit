
import '../../widgets/app-bar.dart';
import 'package:flutter/material.dart';

class StrategyExplanation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context
      ),
      body: Container(
        alignment: Alignment.center,
        child: Text(
            'This screen explains strategy '
        ),
      ),
    );
  }
}
