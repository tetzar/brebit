
import '../../library/resolver.dart';
import 'model.dart';

import 'category.dart';

// ignore: non_constant_identifier_names
List<HabitLog> HabitLogFromJson(List<dynamic> decodedList) =>
    List<HabitLog>.from(decodedList.cast<Map>().map((x) => HabitLog.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> HabitLogToJson(List<HabitLog> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

enum HabitLogStateName {
  started,
  finished,
  strategyChanged,
  activate,
  inactivate,
  aimdateUpdated,
  aimdateOvercame,
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
    HabitLogStateName.aimdateUpdated: 6,
    HabitLogStateName.aimdateOvercame: 7,
    HabitLogStateName.did: 8,
    HabitLogStateName.wannaDo: 9,
  };

  int id;
  int state;
  Category category;
  Map<String, dynamic> information;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime softDeletedAt;

  HabitLog({
    this.id,
    this.state,
    this.information,
    this.category,
    this.createdAt,
    this.updatedAt,
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
        "soft_deleted_at":
            (softDeletedAt == null) ? null : softDeletedAt.toIso8601String(),
        "id": id,
        'category_id': category.id,
        "state": state,
        "information": information,
      };

  static HabitLogStateName getStateFromStateId(int id) {
    if (id == null) {
      return null;
    }
    HabitLogStateName key =
        stateMap.keys.firstWhere((k) => stateMap[k] == id, orElse: () => null);
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

  HabitLogStateName getState() {
    return HabitLog.getStateFromStateId(this.state);
  }

  Map<String, dynamic> getBody() {
    Map<String, dynamic> body = this.information;
    return Resolver.getBody(body);
  }

  static List<HabitLog> sortByCreatedAt(List<HabitLog> logs,
      [bool desc = true]) {
    if (logs == null) return <HabitLog>[];
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
    DateTime d;
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
