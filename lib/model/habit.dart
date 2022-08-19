import 'package:brebit/library/data-set.dart';
import 'package:brebit/model/strategy.dart';
import 'package:brebit/model/user.dart';

import 'analysis.dart';
import 'category.dart';
import 'habit_log.dart';
import 'model.dart';

List<Habit> habitFromJson(List<dynamic> decodedList) =>
    List<Habit>.from(decodedList.cast<Map<String, dynamic>>().map((x) => Habit.fromJson(x)));

List<Map> habitToJson(List<Habit> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class Habit extends Model {
  static List<Habit> habitList = <Habit>[];

  Map<HabitLogStateName, String> logStateMap = {
    HabitLogStateName.started: 'started',
    HabitLogStateName.finished: 'finished',
    HabitLogStateName.strategyChanged: 'strategy_changed',
    HabitLogStateName.activate: 'activate',
    HabitLogStateName.inactivate: 'inactivate',
    HabitLogStateName.aimDateUpdated: 'aimDateUpdated',
    HabitLogStateName.aimDateOvercame: 'aimDateOvercame',
    HabitLogStateName.did: 'did',
    HabitLogStateName.wannaDo: 'wannaDo',
  };

  int id;
  AuthUser user;
  Category category;
  List<HabitLog> habitLogs;
  List<Strategy> strategies;
  List<Analysis> analyses;
  DateTime? aimDate;
  int state;
  int step;
  int limit;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? softDeletedAt;

  static List<int> days = [
    1,
    2,
    3,
    5,
    7,
    10,
    14,
    20,
  ];

  Habit({
    required this.id,
    required this.user,
    required this.category,
    required this.habitLogs,
    required this.strategies,
    required this.analyses,
    required this.state,
    required this.step,
    required this.limit,
    this.aimDate,
    required this.createdAt,
    required this.updatedAt,
    this.softDeletedAt,
  });

  //---------------------------------
  //  creation
  //---------------------------------

  factory Habit.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data_set')) {
      DataSet.dataSetConvert(json['data_set']);
    }
    int habitIndex =
        Habit.habitList.indexWhere((habit) => habit.id == json['id']);
    if (habitIndex < 0) {
      Habit newHabit;
      if (json.containsKey('user')) {
        newHabit = new Habit(
          id: json["id"],
          user: AuthUser.fromJson(json["user"]),
          category: Category.fromJson(json["category"]),
          habitLogs: json["habit_logs"].length > 0 && json['habit_logs'] != '[]'
              ? habitLogFromJson(json["habit_logs"])
              : <HabitLog>[],
          strategies:
              json["strategies"].length > 0 && json['strategies'] != '[]'
                  ? strategyFromJson(json['strategies'])
                  : <Strategy>[],
          analyses: json["analyses"].length > 0 && json['analyses'] != '[]'
              ? analysisFromJson(json['analyses'])
              : <Analysis>[],
          aimDate: (json["aim_date"] != null)
              ? DateTime.parse(json["aim_date"])
              : null,
          state: json["state"],
          step: json['step'],
          limit: json['limit'],
          createdAt: DateTime.parse(json["created_at"]).toLocal(),
          updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
          softDeletedAt: (json["soft_delete_at"] != null)
              ? DateTime.parse(json["soft_delete_at"]).toLocal()
              : null,
        );
      } else {
        newHabit = new Habit(
          id: json["id"],
          user: AuthUser.find(json["user_id"]),
          category: Category.find(json["category_id"]),
          habitLogs: json["habit_logs"].length > 0 && json['habit_logs'] != '[]'
              ? habitLogFromJson(json["habit_logs"])
              : <HabitLog>[],
          strategies:
              json["strategy_ids"].length > 0 && json['strategy_ids'] != '[]'
                  ? Strategy.findAll(json['strategy_ids'])
                  : <Strategy>[],
          analyses: json["analyses"].length > 0 && json['analyses'] != '[]'
              ? analysisFromJson(json['analyses'])
              : <Analysis>[],
          aimDate: (json["aim_date"] != null)
              ? DateTime.parse(json["aim_date"])
              : null,
          state: json["state"],
          step: json['step'],
          limit: json['limit'],
          createdAt: DateTime.parse(json["created_at"]).toLocal(),
          updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
          softDeletedAt: (json["soft_delete_at"] != null)
              ? DateTime.parse(json["soft_deleted_at"]).toLocal()
              : null,
        );
      }
      Habit.habitList.add(newHabit);
      return newHabit;
    } else {
      Habit habit = Habit.habitList[habitIndex];
      if (DateTime.parse(json["updated_at"]).isAfter(habit.updatedAt)) {
        Habit newHabit;
        if (json.containsKey('user')) {
          newHabit = new Habit(
            id: json["id"],
            user: AuthUser.fromJson(json["user"]),
            category: Category.fromJson(json["category"]),
            habitLogs:
                json["habit_logs"].length > 0 && json['habit_logs'] != '[]'
                    ? habitLogFromJson(json["habit_logs"])
                    : <HabitLog>[],
            strategies:
                json["strategies"].length > 0 && json['strategies'] != '[]'
                    ? strategyFromJson(json['strategies'])
                    : <Strategy>[],
            analyses: json["analyses"].length > 0 && json['analyses'] != '[]'
                ? analysisFromJson(json['analyses'])
                : <Analysis>[],
            aimDate: (json["aim_date"] != null)
                ? DateTime.parse(json["aim_date"])
                : null,
            state: json["state"],
            step: json['step'],
            limit: json['limit'],
            createdAt: DateTime.parse(json["created_at"]).toLocal(),
            updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
            softDeletedAt: (json["soft_delete_at"] != null)
                ? DateTime.parse(json["soft_deleted_at"]).toLocal()
                : null,
          );
        } else {
          newHabit = new Habit(
            id: json["id"],
            user: AuthUser.find(json["user_id"]),
            category: Category.find(json["category_id"]),
            habitLogs:
                json["habit_logs"].length > 0 && json['habit_logs'] != '[]'
                    ? habitLogFromJson(json["habit_logs"])
                    : <HabitLog>[],
            strategies:
                json["strategy_ids"].length > 0 && json['strategy_ids'] != '[]'
                    ? Strategy.findAll(json['strategy_ids'])
                    : <Strategy>[],
            analyses: json["analyses"].length > 0 && json['analyses'] != '[]'
                ? analysisFromJson(json['analyses'])
                : <Analysis>[],
            aimDate: (json["aim_date"] != null)
                ? DateTime.parse(json["aim_date"])
                : null,
            state: json["state"],
            step: json['step'],
            limit: json['limit'],
            createdAt: DateTime.parse(json["created_at"]).toLocal(),
            updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
            softDeletedAt: (json["soft_delete_at"] != null)
                ? DateTime.parse(json["soft_deleted_at"]).toLocal()
                : null,
          );
        }
        Habit.habitList[habitIndex] = newHabit;
        return newHabit;
      } else {
        return Habit.habitList[habitIndex];
      }
    }
  }

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "soft_deleted_at":
            softDeletedAt?.toIso8601String(),
        "id": id,
        "category": category.toJson(),
        "user": user.toJson(),
        "state": state,
        "step": step,
        "limit": limit,
        "aim_date": aimDate?.toIso8601String(),
        "habit_logs":
            habitLogs.length > 0 ? habitLogToJson(habitLogs) : <HabitLog>[],
        "strategies": strategies.length > 0
            ? strategyToJson(this.strategies)
            : <Strategy>[],
        "analyses":
            analyses.length > 0 ? analysisToJson(this.analyses) : <Analysis>[],
      };

  static Habit? find(int habitId) {
    int habitIndex = Habit.habitList.indexWhere((habit) => habit.id == habitId);
    if (habitIndex < 0) {
      return null;
    } else {
      return Habit.habitList[habitIndex];
    }
  }

  //---------------------------------
  //  static
  //---------------------------------

  static List<int> getDayList() {
    return Habit.days;
  }

  static int getStepCount() {
    return Habit.days.length;
  }

  //---------------------------------
  //  state
  //---------------------------------

  bool hasStarted() {
    for (HabitLog log in habitLogs) {
      if (log.isState('started')) return true;
    }
    return false;
  }

  bool hasLimit() {
    return this.limit > 0;
  }

  //---------------------------------
  //  log
  //---------------------------------

  List<HabitLog> logSort({String sort = "later"}) {
    List<HabitLog> logs = this.habitLogs;
    if (sort == "earlier") {
      logs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      logs.sort((a, b) => -a.createdAt.compareTo(b.createdAt));
    }
    return logs;
  }

  HabitLog? getLatestLogIn(List<HabitLogStateName> stateList) {
    List<HabitLog> logs = this.logSort();
    for (HabitLog log in logs) {
      if (stateList.contains(log.getState())) {
        return log;
      }
    }
    return null;
  }

  List<HabitLog> getLogsIn(List<HabitLogStateName> stateList) {
    List<HabitLog> logs = <HabitLog>[];
    for (HabitLog log in this.logSort(sort: 'earlier')) {
      if (stateList.contains(log.getState())) {
        logs.add(log);
      }
    }
    return logs;
  }

  List<DateTime> isActiveDayListInMonth(DateTime month) {
    List<HabitLog> logs = this.getLogsIn([
      HabitLogStateName.started,
      HabitLogStateName.activate,
      HabitLogStateName.inactivate,
      HabitLogStateName.finished,
    ]);
    List<DateTime> _inactiveList = <DateTime>[];
    DateTime startTime = logs.first.createdAt;
    DateTime _t = DateTime.parse(
        '${month.year}-${month.month ~/ 10 == 0 ? '0' + month.month.toString() : month.month}-01');
    DateTime today = DateTime.parse(
        "${DateTime.now().year}-${DateTime.now().month ~/ 10 == 0 ? '0' + DateTime.now().month.toString() : DateTime.now().month}-${DateTime.now().day ~/ 10 == 0 ? '0' + DateTime.now().day.toString() : DateTime.now().day} 23:59:59");
    while (_t.month == month.month) {
      DateTime time = DateTime.parse(
          "${_t.year}-${_t.month ~/ 10 == 0 ? '0' + _t.month.toString() : _t.month}-${_t.day ~/ 10 == 0 ? '0' + _t.day.toString() : _t.day} 23:59:59");

      if (time.isBefore(startTime)) {
        _inactiveList.add(_t);
      } else {
        if (time.isAfter(today)) {
          _inactiveList.add(_t);
        } else {
          HabitLog? _log;
          try {
            _log = logs.reversed.firstWhere((log) => log.createdAt.isBefore(time));
          } on StateError {
            _log = null;
          }
          if (_log != null) {
            switch (_log.getState()) {
              case HabitLogStateName.inactivate:
              case HabitLogStateName.finished:
                _inactiveList.add(_t);
                break;
              default:
                break;
            }
          } else {
            _inactiveList.add(_t);
          }
        }
      }
      _t = _t.add(Duration(days: 1));
    }
    return _inactiveList;
  }

  DateTime? getStartTime() {
    HabitLog? _log = this.getLatestLogIn([HabitLogStateName.started]);
    if (_log != null) {
      return _log.createdAt;
    }
    return null;
  }

  //---------------------------------
  //  date
  //---------------------------------

  Duration getStartToAimDate() {
    List<HabitLogStateName> startList = [
      HabitLogStateName.started,
      HabitLogStateName.aimDateUpdated,
      HabitLogStateName.activate,
    ];
    HabitLog? startLog = getLatestLogIn(startList);
    if (startLog == null || this.aimDate == null) {
      return Duration.zero;
    }
    Duration diff = this.aimDate!.difference(startLog.createdAt);
    return diff;
  }

  Duration getStartToNow() {
    List<HabitLogStateName> startList = [
      HabitLogStateName.started,
      HabitLogStateName.aimDateUpdated,
      HabitLogStateName.activate,
    ];
    HabitLog? startLog = getLatestLogIn(startList);
    if (startLog == null) {
      return Duration.zero;
    }
    Duration diff = DateTime.now().difference(startLog.createdAt);
    return diff;
  }

  int getNowStep() {
    return this.step;
  }

  //---------------------------------
  //  strategy
  //---------------------------------
  bool isUsingStrategy(Strategy strategy) {
    if (strategy.id == null) return false;
    if (strategies.length > 0) {
      int index = this
          .strategies
          .indexWhere((myStrategy) => myStrategy.id == strategy.id);
      return index >= 0;
    }
    return false;
  }

  //---------------------------------
  //  analysis
  //---------------------------------
  bool isUsingAnalysis(Analysis analysis) {
    if (analyses.length > 0) {
      int index = this
          .analyses
          .indexWhere((usingAnalysis) => usingAnalysis.id == analysis.id);
      return index >= 0;
    }
    return false;
  }
}
