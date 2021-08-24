import 'model.dart';

// ignore: non_constant_identifier_names
List<Information> InformationFromJson(List<dynamic> decodedList) => new List<Information>.from(
    decodedList.cast<Map>().map((x) => Information.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> InformationToJson(List<Information> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class Information extends Model {
  int id;
  int userId;
  int categoryId;
  String data;
  int classNum;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime softDeletedAt;

  Information({
    this.id,
    this.userId,
    this.data,
    this.categoryId,
    this.classNum,
    this.createdAt,
    this.updatedAt,
    this.softDeletedAt,
  });

  factory Information.fromJson(Map<String, dynamic> json) => new Information(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        softDeletedAt: json['soft_delete_at'] == null
            ? null
            : DateTime.parse(json["soft_delete_at"]).toLocal(),
        id: json["id"],
        userId: json["user_id"],
        data: json["data"],
        categoryId: json["category_id"],
        classNum: json["class_num"],
      );

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "soft_delete_at": softDeletedAt.toIso8601String(),
        "id": id,
        "user_id": userId,
        "data": data,
        "category_id": categoryId,
        "class_num": classNum,
      };
}
