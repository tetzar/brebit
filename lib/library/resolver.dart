
import 'package:brebit/model/category.dart';
import 'package:brebit/model/habit.dart';
import 'package:brebit/model/habit_log.dart';
import 'package:brebit/model/strategy.dart';
import 'package:brebit/model/trigger.dart';

class Resolver {
  static Map<String, dynamic> getBody(Map<String, dynamic> body){
    Map<String, dynamic> result = new Map<String, dynamic>();
    body.forEach((key, value) {
      String type = value['data_type'];
      dynamic val = value['value'];
      switch(type){
        case 'text':
          result[key] = val;
          break;
        case 'int':
          if (val is String) {
            result[key] = int.parse(val);
          } else if (val is int){
            result[key] = val;
          } else {
            print('unexpected type value was given in Resolver@getBody. key : $key');
            print(val.toString());
          }

          break;
        case 'array(string)':
          List<String> v = <String>[];
          val.forEach((text) {
            v.add(text);
          });
          result[key] = v;
          break;
        case 'array(int)':
          List<int> v = <int>[];
          val.forEach((num) {
            v.add(int.parse(num));
          });
          result[key] = v;
          break;
        case 'array(strategy)':
          List<Strategy> v = <Strategy>[];
          val.forEach((strategyId) {
            v.add(Strategy.find(strategyId));
          });
          result[key] = v;
          break;
        case 'array(unknown)' :
          result[key] = [];
          break;
        case 'habit':
          result[key] = Habit.find(val);
          break;
        case 'trigger':
          result[key] = Trigger.fromJson(val);
          break;
        case 'category':
          result[key] = Category.find(val);
          break;
        case 'habit_log':
          result[key] = HabitLog.fromJson(val);
          break;
      }
    });
    return result;
  }

  static Map<String, dynamic> toMap(Map<String, dynamic> data) {
    Map<String, Map<String, dynamic>> result = new Map<String, Map<String, dynamic>>();
    data.forEach((key, value) {
      Map<String, dynamic> d = new Map<String, dynamic>();
      if(value is int){
        d['data_type'] = 'int';
        d['value'] = value;
      } else {
        if(value is String) {
          d['data_type'] = 'text';
          d['value'] = value;
        } else {
          if(value is List){
            if(value.length > 0){
              if(value.first is int){
                d['data_type'] = 'array(int)';
                d['value'] = value;
              }
              if (value.first is String) {
                d['data_type'] = 'array(text)';
                d['value'] = value;
              }

              if (value.first.runtimeType.toString() == 'Strategy') {
                d['data_type']  = 'array(strategy)';
                List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
                value.forEach((element) {
                  list.add(element.toJson());
                });
                d['value'] = list;
              }
            }else {
              d['data_type'] = 'array(unknown)';
              d['value'] = [];
            }
          } else {
            switch(value.runtimeType.toString()) {
              case 'Habit':
                d['data_type'] = 'habit';
                d['value'] = value.toJson();
                break;
              case 'Trigger':
                d['data_type'] = 'trigger';
                d['value'] = value.toJson();
                break;
              case 'Category':
                d['data_type'] = 'category';
                d['value'] = value.toJson();
                break;
              case 'Memo':
                d['data_type'] = 'memo';
                d['value'] = value.toJson();
                break;
              default:
                return null;
                break;
            }
          }
        }
      }
      result[key] = d;
    });
    return result;
  }
}

