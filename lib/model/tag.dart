
import 'model.dart';

// ignore: non_constant_identifier_names
List<Tag> TagFromJson(List<dynamic> decodedList) =>
    new List<Tag>.from(decodedList.cast<Map<String, dynamic>>().map((x) => Tag.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> TagToJson(List<Tag> contents) =>
    new List<Map<String, dynamic>>.from(contents.map((x) => x.toJson()));

class Tag extends Model {
  int? id;
  String name;
  int? hits;
  DateTime? createdAt;
  DateTime? updatedAt;

  Tag({this.id, required this.name, this.hits});

  factory Tag.fromJson(Map<String, dynamic> json) => new Tag(
      id: json["id"],
      name: json["name"],
      hits: json['hits'] != null ? json['hits'] : null);

  Map<String, dynamic> toJson() => {"id": id, "name": name, 'hits': hits};

  int getHits() {
    return this.hits ?? 0;
  }
}
