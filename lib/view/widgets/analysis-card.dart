
import 'dart:typed_data';

import '../../../model/analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AnalysisCard extends StatelessWidget {

  final Analysis analysis;
  AnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 16
      ),
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius:
          BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              spreadRadius: -3,
              blurRadius: 10,
              offset: Offset(0, 0),
            )
          ]),
      height: 56,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: 18
            ),
            child: FutureBuilder(
              future: analysis.getImage(),
              builder: (context, snapshot) {
                return (snapshot.connectionState == ConnectionState.done && snapshot.hasData) ? SvgPicture.memory(
                  snapshot.data as Uint8List,
                  semanticsLabel: 'A shark?!',
                  height: 20,
                  width: 20,
                  color: Theme.of(context).textTheme.subtitle1?.color,
                  placeholderBuilder: (BuildContext context) => Container(
                    color: Colors.transparent,
                    width: 20,
                    height: 20,
                  ),
                ) : SizedBox(
                  height: 20,
                  width: 20,
                );
              },
            )
          ),
          Expanded(
            child: Text(
              analysis.name,
              style: TextStyle(
                color: Theme.of(context).textTheme.subtitle1?.color,
                fontSize: 13,
                fontWeight: FontWeight.w400
              ),
            ),
          )
        ],
      ),
    );
  }
}
