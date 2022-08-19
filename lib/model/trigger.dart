import '../../library/data-set.dart';
import '../../library/resolver.dart';
import 'habit.dart';
import 'model.dart';
import 'tag.dart';

List<Trigger> triggerFromJson(List<dynamic> decodedList) =>
    new List<Trigger>.from(decodedList
        .cast<Map<String, dynamic>>()
        .map((x) => Trigger.fromJson(x)));

List<Map> triggerToJson(List<Trigger> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class Trigger extends Model {
  int id;
  Map<String, dynamic> body;
  int state;
  List<Tag> tags;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? softDeletedAt;

  Trigger({
    required this.id,
    required this.body,
    required this.state,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.softDeletedAt,
  });

  factory Trigger.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data_set')) {
      DataSet.dataSetConvert(json['data_set']);
    }
    if (json.containsKey('habit')) {
      return Trigger(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        softDeletedAt: json["soft_deleted_at"] == null
            ? null
            : DateTime.parse(json["soft_deleted_at"]).toLocal(),
        id: json["id"],
        body: json["body"].length == 0
            ? new Map<String, dynamic>()
            : Resolver.getBody(json['body']),
        tags: json['tags'].length > 0 ? TagFromJson(json['tags']) : <Tag>[],
        state: json["state"],
      );
    }
    return Trigger(
      createdAt: DateTime.parse(json["created_at"]).toLocal(),
      updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
      softDeletedAt: json["soft_deleted_at"] == null
          ? null
          : DateTime.parse(json["soft_deleted_at"]).toLocal(),
      id: json["id"],
      body: json["body"].length == 0
          ? {}
          : Resolver.getBody(json['body']),
      tags: json['tags'].length > 0 ? TagFromJson(json['tags']) : <Tag>[],
      state: json["state"],
    );
  }

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "soft_deleted_at":softDeletedAt?.toIso8601String(),
        "id": id,
        "body": body,
        "state": state,
        'tags': TagToJson(tags)
      };
}
