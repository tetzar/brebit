
import '../../library/resolver.dart';
import 'model.dart';

import 'category.dart';

List<HabitLog> habitLogFromJson(List<dynamic> decodedList) =>
    List<HabitLog>.from(decodedList.cast<Map<String, dynamic>>().map((x) => HabitLog.fromJson(x)));

List<Map> habitLogToJson(List<HabitLog> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

enum HabitLogStateName {
  started,
  finished,
  strategyChanged,
  activate,
  inactivate,
  aimDateUpdated,
  aimDateOvercame,
  did,
  wannaDo,
}

class HabitLog extends Model {
  static Map<HabitLogStateName, int> stateMap = {
    HabitLogStateName.started: 0,
    HabitLogStateName.finished: 1,
    HabitLogStateName.strategyChanged: 2,
    HabitLogStateName.activate: 4,
    HabitLogStateName.inactivate: 5,
    HabitLogStateName.aimDateUpdated: 6,
    HabitLogStateName.aimDateOvercame: 7,
    HabitLogStateName.did: 8,
    HabitLogStateName.wannaDo: 9,
  };

  int id;
  int state;
  Category category;
  Map<String, dynamic> information;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? softDeletedAt;

  HabitLog({
    required this.id,
    required this.state,
    required this.information,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.softDeletedAt,
  });

  factory HabitLog.fromJson(Map<dynamic, dynamic> json) => new HabitLog(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        softDeletedAt: (json["soft_delete_at"] != null)
            ? DateTime.parse(json["soft_deleted_at"]).toLocal()
            : null,
        category: Category.find(json['category_id']),
        id: json["id"],
        state: json["state"],
        information: json["information"].length == 0
            ? new Map<String, dynamic>()
            : json['information'],
      );

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "soft_deleted_at":softDeletedAt?.toIso8601String(),
        "id": id,
        'category_id': category.id,
        "state": state,
        "information": information,
      };

  static HabitLogStateName getStateFromStateId(int id) {
    HabitLogStateName key =
        stateMap.keys.firstWhere((k) => stateMap[k] == id);
    return key;
  }

  bool isState(String stateAsStr) {
    if (stateMap.containsKey(stateAsStr)) {
      if (stateMap[stateAsStr] == state) {
        return true;
      }
    }
    return false;
  }

  HabitLogStateName? getState() {
    return HabitLog.getStateFromStateId(this.state);
  }

  Map<String, dynamic> getBody() {
    Map<String, dynamic> body = this.information;
    return Resolver.getBody(body);
  }

  static List<HabitLog> sortByCreatedAt(List<HabitLog> logs,
      [bool desc = true]) {
    if (desc) {
      logs.sort((a, b) {
        return a.createdAt.isAfter(b.createdAt) ? -1 : 1;
      });
    } else {
      logs.sort((a, b) {
        return a.createdAt.isBefore(b.createdAt) ? -1 : 1;
      });
    }
    return logs;
  }

  static List<List<HabitLog>> collectByDate(List<HabitLog> logs) {
    sortByCreatedAt(logs);
    List<List<HabitLog>> collected = <List<HabitLog>>[];
    DateTime? d;
    List<HabitLog> collection = <HabitLog>[];
    for (HabitLog log in logs) {
      if (d == null) {
        d = log.createdAt;
        collection.add(log);
      } else {
        if (d.year == log.createdAt.year &&
            d.month == log.createdAt.month &&
            d.day == log.createdAt.day) {
          collection.add(log);
        } else {
          collected.add(collection);
          d = log.createdAt;
          collection = <HabitLog>[];
          collection.add(log);
        }
      }
      if (logs.last == log) {
        collected.add(collection);
      }
    }
    return collected;
  }
}
