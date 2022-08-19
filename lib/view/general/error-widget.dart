import 'package:flutter/material.dart';

import '../../route/route.dart';
import '../widgets/app-bar.dart';

class ErrorToHomeWidget extends StatelessWidget {
  const ErrorToHomeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getMyAppBar(
          context: context),
      body: ErrorToHomeContent(),
    );
  }
}

class ErrorToHomeContent extends StatelessWidget {
  const ErrorToHomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("予期せぬエラーが発生しました", style: TextStyle(
              color: Theme.of(context).disabledColor
          ),),
          Container(
              margin: EdgeInsets.only(
                  top: 20
              ),
              child: InkWell(
                onTap: (){
                  ApplicationRoutes.popUntil("/home");
                },
                child: Container(
                  width: 300,
                  height: 56,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                          Radius.circular(28)
                      ),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2
                      )
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "ホームに戻る",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17
                    ),
                  ),
                ),
              )
          )
        ],
      ),
    );
  }
}

