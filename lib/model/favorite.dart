
// ignore: non_constant_identifier_names
import 'package:brebit/library/data-set.dart';
import 'package:brebit/model/user.dart';

import 'model.dart';

List<Favorite> FavoriteFromJson(List<dynamic> decodedList) =>
    List<Favorite>.from(decodedList.cast<Map>().map((x) => Favorite.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> FavoriteToJson(List<Favorite> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class Favorite extends Model {
  int id;
  AuthUser user;
  int type;

  Favorite({
    this.id,
    this.user,
    this.type,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data_set')) {
      DataSet.dataSetConvert(json['data_set']);
    }
    if (json.containsKey(('user'))) {
      return new Favorite(
        id: json["id"],
        user: AuthUser.fromJson(json["user"]),
        type: json["type"],
      );
    }
    return new Favorite(
      id: json["id"],
      user: AuthUser.find(json["user_id"]),
      type: json["type"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "user": user.toJson(),
        "type": type,
      };
}
