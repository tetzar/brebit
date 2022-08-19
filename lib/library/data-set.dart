
import 'package:brebit/model/category.dart';
import 'package:brebit/model/habit.dart';
import 'package:brebit/model/strategy.dart';
import 'package:brebit/model/user.dart';

class DataSet{
  static void dataSetConvert(Map<String, dynamic> dataSet) {
    dataSet.cast<String, List>();
    categoryFromJson(dataSet['categories'].cast<Map>());
    authUserFromJson(dataSet['users'].cast<Map>());
    strategyFromJson(dataSet['strategies'].cast<Map>());
    habitFromJson(dataSet['habits'].cast<Map>());
  }
}