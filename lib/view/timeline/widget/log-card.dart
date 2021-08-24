import '../../../../model/category.dart';
import '../../../../model/habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogCard extends StatelessWidget {

  final HabitLog log;

  LogCard({@required this.log});

  @override
  Widget build(BuildContext context) {
    if (log != null) {
      Map<String, dynamic> body = log.getBody();
      String logCardBody = '';
      LogStyle style;
      switch(HabitLog.getStateFromStateId(log.state)) {
        case HabitLogStateName.strategyChanged:
          style = LogStyle.strategyUpdated;
          logCardBody = 'マイルールを変更しました';
          break;
        case HabitLogStateName.aimdateOvercame:
          style = LogStyle.achieved;
          if (body.containsKey('aim_date')) {
            logCardBody = '${body['aim_date']}日';
          }
          break;
        case HabitLogStateName.wannaDo:
          logCardBody = '欲求を回避しました';
          style = LogStyle.endured;
          break;
        default:
          style = null;
          break;
      }
      return LogCardTile(logStyle: style, categoryName: log.category.name, body: logCardBody);
    }
    return Container(
      width: 0,
        height: 0,
    );
  }
}

enum LogStyle {
  achieved,
  endured,
  strategyUpdated,
}

Map<LogStyle, String> iconName = {
  LogStyle.achieved: 'assets/icon/updated.svg',
  LogStyle.endured: 'assets/icon/achieved.svg',
  LogStyle.strategyUpdated: 'assets/icon/changed.svg'
};

Map<CategoryName, String> categoryNameList = {
  CategoryName.cigarette: 'たばこ',
  CategoryName.alcohol: 'お酒',
  CategoryName.sweets: 'お菓子',
  CategoryName.sns: 'SNS',
  CategoryName.notCategorized: '??'
};

class LogCardTile extends StatelessWidget {
  final LogStyle logStyle;
  final CategoryName categoryName;
  final String body;

  LogCardTile(
      {@required this.logStyle, @required this.categoryName, @required this.body});

  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (iconName.containsKey(logStyle)) {
      icon = SvgPicture.asset(
        iconName[logStyle],
        width: 14,
        height: 14,
        color: Theme.of(context).accentColor,
      );
    }

    List<Widget> rowChildren = <Widget>[];
    if (icon != null) {
      rowChildren.add(icon);
    }

    rowChildren.add(
      Expanded(
        child: Container(
          margin: EdgeInsets.only(left: 6),
          child: Text(
            body,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
      )
    );

    String _categoryName = '';
    if (categoryNameList.containsKey(categoryName)) {
      _categoryName = categoryNameList[categoryName];
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme
              .of(context)
              .primaryColorLight
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _categoryName,
            style: Theme
                .of(context)
                .textTheme
                .bodyText1
                .copyWith(
                fontWeight: FontWeight.w700
            ),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rowChildren,
          )
        ],
      ),
    );
  }
}
