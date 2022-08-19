
// ignore: non_constant_identifier_names
import 'model.dart';

List<CategoryParameter> categoryParameterFromJson(List<dynamic> list) =>
    new List<CategoryParameter>.from(
        list.cast<Map<String, dynamic>>().map((x) => CategoryParameter.fromJson(x)));

List<Map> categoryParameterToJson(List<CategoryParameter> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class CategoryParameter extends Model {
  int id;
  String name;
  Map<String, dynamic> data;
  String style;

  CategoryParameter({
    required this.id,
    required this.name,
    required this.data,
    required this.style,
  });

  factory CategoryParameter.fromJson(Map<String, dynamic> json) =>
      new CategoryParameter(
        id: json["id"],
        data: json['data'],
        name: json["name"],
        style: json["style"],
      );

  Map<String, dynamic> toJson() =>
      {"id": id, "name": name, "style": style, 'data': data};
}
