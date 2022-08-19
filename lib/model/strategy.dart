import '../../library/data-set.dart';
import '../../library/resolver.dart';
import 'category.dart';
import 'model.dart';
import 'user.dart';

// ignore: non_constant_identifier_names
List<Strategy> strategyFromJson(List<dynamic> decodedList) =>
    new List<Strategy>.from(decodedList
        .cast<Map<String, dynamic>>()
        .map((x) => Strategy.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> strategyToJson(List<Strategy> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class Strategy extends Model {
  static List<Strategy> strategyList = <Strategy>[];

  int? id;
  AuthUser? createUser;
  Category category;
  Map<String, dynamic> body;
  int followers;

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? softDeletedAt;

  Strategy({
    this.id,
    this.createUser,
    required this.category,
    required this.body,
    this.followers = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.softDeletedAt,
  }) {
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  factory Strategy.fromJson(Map<String, dynamic> json) {
    if (json.containsKey(('data_set'))) {
      DataSet.dataSetConvert(json['data_set']);
    }
    int strategyIndex = Strategy.strategyList
        .indexWhere((strategy) => strategy.id == json['id']);
    if (strategyIndex < 0) {
      Strategy newStrategy;
      if (json.containsKey('create_user')) {
        newStrategy = new Strategy(
          id: json["id"],
          createUser: json["create_user"] == null
              ? null
              : AuthUser.fromJson(json["create_user"]),
          category: Category.fromJson(json["category"]),
          body: json["body"],
          followers: json['followers'],
          createdAt: DateTime.parse(json["created_at"]).toLocal(),
          updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
          softDeletedAt: (json["soft_delete_at"] != null)
              ? DateTime.parse(json["soft_deleted_at"]).toLocal()
              : null,
        );
      } else {
        newStrategy = new Strategy(
          id: json["id"],
          createUser: AuthUser.find(json["create_user_id"]),
          category: Category.find(json["category_id"]),
          body: json["body"],
          followers: json['followers'],
          createdAt: DateTime.parse(json["created_at"]).toLocal(),
          updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
          softDeletedAt: (json["soft_delete_at"] != null)
              ? DateTime.parse(json["soft_deleted_at"]).toLocal()
              : null,
        );
      }

      Strategy.strategyList.add(newStrategy);
      return strategyList.last;
    } else {
      Strategy newStrategy;
      if (json.containsKey('create_user')) {
        newStrategy = new Strategy(
          id: json["id"],
          createUser: json["create_user"] == null
              ? null
              : AuthUser.fromJson(json["create_user"]),
          category: Category.fromJson(json["category"]),
          body: json["body"],
          followers: json["followers"],
          createdAt: DateTime.parse(json["created_at"]).toLocal(),
          updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
          softDeletedAt: (json["soft_delete_at"] != null)
              ? DateTime.parse(json["soft_deleted_at"]).toLocal()
              : null,
        );
      } else {
        newStrategy = new Strategy(
          id: json["id"],
          createUser: AuthUser.find(json["create_user_id"]),
          category: Category.find(json["category_id"]),
          body: json["body"],
          followers: json["followers"],
          createdAt: DateTime.parse(json["created_at"]).toLocal(),
          updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
          softDeletedAt: (json["soft_delete_at"] != null)
              ? DateTime.parse(json["soft_deleted_at"]).toLocal()
              : null,
        );
      }
      Strategy.strategyList[strategyIndex] = newStrategy;
      return Strategy.strategyList[strategyIndex];
    }
  }

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "soft_deleted_at": softDeletedAt?.toIso8601String(),
        "id": id,
        "category": category.toJson(),
        "create_user": createUser?.toJson(),
        "body": body,
        "followers": followers,
      };

  Map<String, dynamic> getBody() {
    Map<String, dynamic> body = this.body;
    return Resolver.getBody(body);
  }

  Map<String, dynamic> createdToMap() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['create_user'] = this.createUser?.toJson();
    data['category'] = this.category.toJson();
    data['body'] = this.body;
    return data;
  }

  static Strategy? find(int strategyId) {
    int index = Strategy.strategyList
        .indexWhere((strategy) => strategy.id == strategyId);
    if (index < 0) {
      return null;
    } else {
      return Strategy.strategyList[index];
    }
  }

  static List<Strategy> findAll(List strategyIdList) {
    print(strategyIdList.toString());
    List<Strategy> strategyList = <Strategy>[];
    strategyIdList.forEach((strategyId) {
      Strategy? _strategy = find(strategyId);
      if (_strategy != null) {
        strategyList.add(_strategy);
      }
    });
    return strategyList;
  }

  int getFollowers() {
    return followers;
  }
}
