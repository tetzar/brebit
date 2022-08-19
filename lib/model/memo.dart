import 'model.dart';

// ignore: non_constant_identifier_names
List<Memo> memoFromJson(List<dynamic> decodedList) =>
    List<Memo>.from(decodedList.cast<Map<String, dynamic>>().map((x) => Memo.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> memoToJson(List<Memo> contents) =>
    new List<Map>.from(contents.map((x) => x.toJson()));

class Memo extends Model {
  int id;
  String type;
  String contents;
  int userId;
  DateTime createdAt;
  DateTime updatedAt;

  Memo({
    required this.id,
    required this.type,
    required this.contents,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memo.fromJson(Map<String, dynamic> json) => new Memo(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        id: json["id"],
        type: json["type"],
        contents: json["contents"],
        userId: json["user_id"],
      );

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "id": id,
        "type": type,
        "contents": contents,
        "user_id": userId,
      };
}
