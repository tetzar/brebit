import 'dart:math';
import 'package:brebit/library/data-set.dart';
import 'package:brebit/model/user.dart';
import 'package:brebit/network/api.dart';
import 'package:flutter/material.dart';
import 'package:time_machine/time_machine.dart';

import 'category.dart';
import 'category_parameter.dart';
import 'habit.dart';
import 'habit_log.dart';
import 'model.dart';

// ignore: non_constant_identifier_names
List<Analysis> AnalysisFromJson(List<dynamic> list) =>
    new List<Analysis>.from(list.cast<Map>().map((x) => Analysis.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> AnalysisToJson(List<Analysis> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class Analysis extends Model {
  static List<String> dataIds = [
    'history_minutes',
    'history_hours',
    'history_days',
    'history_month',
    'history_years',
    'history_total_years',
    'history_total_month',
    'history_total_days',
    'history_total_hours',
    'history_total_minutes',
    'habit_active_minutes',
    'habit_active_hours',
    'habit_active_days',
    'habit_active_total_minutes',
    'habit_active_total_hours',
    'habit_active_total_days',
  ];

  int id;
  Category category;
  String name;
  List<dynamic> calculateMethod;
  List<CategoryParameter> params;
  String imageUrl;
  DateTime createdAt;
  DateTime updatedAt;

  Analysis({
    @required this.id,
    @required this.category,
    @required this.name,
    @required this.calculateMethod,
    this.params,
    @required this.imageUrl,
    @required this.createdAt,
    @required this.updatedAt,
  });

  factory Analysis.fromJson(Map<String, dynamic> json) {
    if (json.containsKey(('data_set'))) {
      DataSet.dataSetConvert(json['data_set']);
    }
    return new Analysis(
      id: json["id"],
      category: json.containsKey('category')
          ? Category.fromJson(json['category'])
          : Category.find(json["category_id"]),
      name: json['name'],
      params: json['params'] != null
          ? CategoryParameterFromJson(json['params'])
          : null,
      calculateMethod: json['method'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json["created_at"]).toLocal(),
      updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "category": this.category.toJson(),
        "method": this.calculateMethod,
        "params": CategoryParameterToJson(this.params),
        'name': this.name,
        'image_url': this.imageUrl,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
      };

  String getImageUrl() {
    if (this.imageUrl != null) {
      return Network.url + this.imageUrl;
    } else {
      return null;
    }
  }

  List<List<String>> getData(AuthUser user, Habit habit) {
    List<List<String>> result = <List<String>>[];
    for (Map<String, dynamic> method_data in this.calculateMethod) {
      if (method_data['method'] != null) {
        List<double> data = <double>[];
        List<String> unit = <String>[];
        List<String> operators = method_data['method'].split(' ');
        for (String operator in operators) {
          switch (operator) {
            case '+':
              data.add(data.removeLast() + data.removeLast());
              break;
            case '-':
              double sub = data.removeLast();
              data.add(data.removeLast() + sub);
              break;
            case '*':
              data.add(data.removeLast() * data.removeLast());
              break;
            case '/':
              double div = data.removeLast();
              data.add(data.removeLast() / div);
              break;
            case '%':
              double sub = data.removeLast();
              data.add(data.removeLast() % sub);
              break;
            case '~/':
              double sub = data.removeLast();
              data.add((data.removeLast() ~/ sub).toDouble());
              break;
            default:
              double v = Analysis.getTimeDependentData(operator, user, habit);
              if (v == null) {
                unit.add(operator);
                v = 1;
              }
              data.add(v);
              break;
          }
        }
        bool ignore = false;
        if (unit.isEmpty) {
          if (method_data['ignorable'] && !(data.last > 0)) {
            ignore = true;
          }
          if (method_data.containsKey('min-digit')) {
            if (method_data['min-digit'] < 0) {
              unit.add(
                  data.removeLast().toStringAsFixed(-method_data['min-digit']));
            } else if (method_data['min-digit'] > 0) {
              unit.add(
                  ((data.removeLast() % pow(10, method_data['min-digit'])) *
                          pow(10, method_data['min-digit']))
                      .toString());
            } else {
              unit.add(data.removeLast().toInt().toString());
            }
          } else {
            unit.add(data.removeLast().toInt().toString());
          }
        }
        unit.add(method_data['unit']);
        if (!ignore) {
          result.add(unit);
        }
      } else {
        if (!method_data['ignorable']) {
          result.add(<String>['', method_data['unit']]);
        }
      }
    }
    return result;
  }

  static double getTimeDependentData(String name, AuthUser user, Habit habit) {
    if (double.tryParse(name) != null) {
      return double.parse(name);
    }
    if (Analysis.dataIds.contains(name)) {
      switch (name) {
        case 'history_minutes':
          int minutes = DateTime.now().difference(user.createdAt).inMinutes;
          return (minutes % 60).toDouble();
          break;
        case 'history_hours':
          int hours = DateTime.now().difference(user.createdAt).inHours;
          return (hours % 24).toDouble();
          break;
        case 'history_days':
          LocalDate today = LocalDate.today();
          LocalDate createdAt = LocalDate.dateTime(user.createdAt);
          Period diff = today.periodSince(createdAt);
          return diff.days.toDouble();
          break;
        case 'history_month':
          LocalDate today = LocalDate.today();
          LocalDate createdAt = LocalDate.dateTime(user.createdAt);
          Period diff = today.periodSince(createdAt);
          return diff.months.toDouble();
          break;
        case 'history_years':
          LocalDate today = LocalDate.today();
          LocalDate createdAt = LocalDate.dateTime(user.createdAt);
          Period diff = today.periodSince(createdAt);
          return diff.years.toDouble();
          break;
        case 'history_total_years':
          LocalDate today = LocalDate.today();
          LocalDate createdAt = LocalDate.dateTime(user.createdAt);
          Period diff = today.periodSince(createdAt);
          return diff.years.toDouble();
          break;
        case 'history_total_month':
          LocalDate today = LocalDate.today();
          LocalDate createdAt = LocalDate.dateTime(user.createdAt);
          Period diff = today.periodSince(createdAt);
          return (diff.years * 12 + diff.months).toDouble();
          break;
        case 'history_total_days':
          int hours = DateTime.now().difference(user.createdAt).inHours;
          return (hours ~/ 24).toDouble();
          break;
        case 'history_total_hours':
          int hours = DateTime.now().difference(user.createdAt).inHours;
          return hours.toDouble();
          break;
        case 'history_total_minutes':
          int minutes = DateTime.now().difference(user.createdAt).inMinutes;
          return minutes.toDouble();
          break;
        case 'habit_active_minutes':
          List<HabitLog> logs = habit.logSort(sort: 'earlier');
          int totalMinutes = 0;
          DateTime pivotDate;
          for (HabitLog log in logs) {
            if (pivotDate == null) {
              pivotDate = log.createdAt;
            } else if (logs.last == log) {
              totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
              if (log.getState() != HabitLogStateName.inactivate) {
                totalMinutes +=
                    DateTime.now().difference(log.createdAt).inMinutes;
              }
            } else {
              switch (log.getState()) {
                case HabitLogStateName.started:
                case HabitLogStateName.activate:
                  pivotDate = log.createdAt;
                  break;
                case HabitLogStateName.finished:
                case HabitLogStateName.inactivate:
                  totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
                  break;
                default:
                  break;
              }
            }
          }
          return (totalMinutes % 60).toDouble();
          break;
        case 'habit_active_hours':
          List<HabitLog> logs = habit.logSort(sort: 'earlier');
          int totalMinutes = 0;
          DateTime pivotDate;
          for (HabitLog log in logs) {
            if (pivotDate == null) {
              pivotDate = log.createdAt;
            } else if (logs.last == log) {
              totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
              if (log.getState() != HabitLogStateName.inactivate) {
                totalMinutes +=
                    DateTime.now().difference(log.createdAt).inMinutes;
              }
            } else {
              switch (log.getState()) {
                case HabitLogStateName.started:
                case HabitLogStateName.activate:
                  pivotDate = log.createdAt;
                  break;
                case HabitLogStateName.finished:
                case HabitLogStateName.inactivate:
                  totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
                  break;
                default:
                  break;
              }
            }
          }
          return ((totalMinutes ~/ 60) % 24).toDouble();
          break;
        case 'habit_active_days':
          List<HabitLog> logs = habit.logSort(sort: 'earlier');
          int totalMinutes = 0;
          DateTime pivotDate;
          for (HabitLog log in logs) {
            if (pivotDate == null) {
              pivotDate = log.createdAt;
            } else if (logs.last == log) {
              totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
              if (log.getState() != HabitLogStateName.inactivate) {
                totalMinutes +=
                    DateTime.now().difference(log.createdAt).inMinutes;
              }
            } else {
              switch (log.getState()) {
                case HabitLogStateName.started:
                case HabitLogStateName.activate:
                  pivotDate = log.createdAt;
                  break;
                case HabitLogStateName.finished:
                case HabitLogStateName.inactivate:
                  totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
                  break;
                default:
                  break;
              }
            }
          }
          return ((totalMinutes ~/ 1440) % 365).toDouble();
          break;
        case 'habit_active_total_minutes':
          List<HabitLog> logs = habit.logSort(sort: 'earlier');
          int totalMinutes = 0;
          DateTime pivotDate;
          for (HabitLog log in logs) {
            if (pivotDate == null) {
              pivotDate = log.createdAt;
            } else if (logs.last == log) {
              totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
              if (log.getState() != HabitLogStateName.inactivate) {
                totalMinutes +=
                    DateTime.now().difference(log.createdAt).inMinutes;
              }
            } else {
              switch (log.getState()) {
                case HabitLogStateName.started:
                case HabitLogStateName.activate:
                  pivotDate = log.createdAt;
                  break;
                case HabitLogStateName.finished:
                case HabitLogStateName.inactivate:
                  totalMinutes += pivotDate.difference(log.createdAt).inMinutes;
                  break;
                default:
                  break;
              }
            }
          }
          return totalMinutes.toDouble();
          break;
        case 'habit_active_total_hours':
          List<HabitLog> logs = habit.logSort(sort: 'earlier');
          int totalMinutes = 0;
          DateTime pivotDate;
          for (HabitLog log in logs) {
            if (pivotDate == null) {
              pivotDate = log.createdAt;
            } else if (logs.last == log) {
              totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
              if (log.getState() != HabitLogStateName.inactivate) {
                totalMinutes +=
                    DateTime.now().difference(log.createdAt).inMinutes;
              }
            } else {
              switch (log.getState()) {
                case HabitLogStateName.started:
                case HabitLogStateName.activate:
                  pivotDate = log.createdAt;
                  break;
                case HabitLogStateName.finished:
                case HabitLogStateName.inactivate:
                  totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
                  break;
                default:
                  break;
              }
            }
          }
          return (totalMinutes ~/ 60).toDouble();
          break;
        case 'habit_active_total_minutes':
          List<HabitLog> logs = habit.logSort(sort: 'earlier');
          int totalMinutes = 0;
          DateTime pivotDate;
          for (HabitLog log in logs) {
            if (pivotDate == null) {
              pivotDate = log.createdAt;
            } else if (logs.last == log) {
              totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
              if (log.getState() != HabitLogStateName.inactivate) {
                totalMinutes +=
                    DateTime.now().difference(log.createdAt).inMinutes;
              }
            } else {
              switch (log.getState()) {
                case HabitLogStateName.started:
                case HabitLogStateName.activate:
                  pivotDate = log.createdAt;
                  break;
                case HabitLogStateName.finished:
                case HabitLogStateName.inactivate:
                  totalMinutes += log.createdAt.difference(pivotDate).inMinutes;
                  break;
                default:
                  break;
              }
            }
          }
          return (totalMinutes ~/ 1440).toDouble();
          break;
        default:
          return null;
      }
    }
    return null;
  }
}
