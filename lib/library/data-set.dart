
import 'package:brebit/model/category.dart';
import 'package:brebit/model/habit.dart';
import 'package:brebit/model/strategy.dart';
import 'package:brebit/model/user.dart';

class DataSet{
  static void dataSetConvert(Map<String, dynamic> dataSet) {
    dataSet.cast<String, List>();
    CategoryFromJson(dataSet['categories'].cast<Map>());
    AuthUserFromJson(dataSet['users'].cast<Map>());
    StrategyFromJson(dataSet['strategies'].cast<Map>());
    HabitFromJson(dataSet['habits'].cast<Map>());
  }
}