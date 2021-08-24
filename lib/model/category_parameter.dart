
// ignore: non_constant_identifier_names
import 'model.dart';

List<CategoryParameter> CategoryParameterFromJson(List<dynamic> list) =>
    new List<CategoryParameter>.from(
        list.cast<Map>().map((x) => CategoryParameter.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> CategoryParameterToJson(List<CategoryParameter> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class CategoryParameter extends Model {
  int id;
  String name;
  Map method;
  String style;

  CategoryParameter({
    this.id,
    this.name,
    this.method,
    this.style,
  });

  factory CategoryParameter.fromJson(Map<String, dynamic> json) =>
      new CategoryParameter(
        id: json["id"],
        method: json['method'],
        name: json["name"],
        style: json["style"],
      );

  Map<String, dynamic> toJson() =>
      {"id": id, "name": name, "style": style, 'method': method};
}
