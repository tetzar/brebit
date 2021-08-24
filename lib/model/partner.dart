import '../../library/data-set.dart';
import 'model.dart';
import 'user.dart';

// ignore: non_constant_identifier_names
List<Partner> PartnerFromJson(List<dynamic> decodedList) =>
    List<Partner>.from(decodedList.cast<Map>().map((x) => Partner.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> PartnerToJson(List<Partner> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

enum PartnerState {
  notRelated,
  request,
  requested,
  partner,
  block,
  blocked,
}

class Partner extends Model {

  static Map<String, int> stateList = {
    'request': 0,
    'requested': 1,
    'partner': 2,
    'block': 3,
    'blocked': 4,
  };

  static Map<PartnerState, int> stateToNumber = {
    PartnerState.request: 0,
    PartnerState.requested: 1,
    PartnerState.partner: 2,
    PartnerState.block: 3,
    PartnerState.blocked: 4,
    PartnerState.notRelated: -1,
  };

  int id;
  AuthUser user;
  int state;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime softDeletedAt;

  Partner(
      {this.id,
      this.user,
      this.state,
      this.createdAt,
      this.updatedAt,
      this.softDeletedAt});

  factory Partner.fromJson(Map<String, dynamic> json){
    if (json.containsKey('data_set')) {
      DataSet.dataSetConvert(json['data_set']);
    }
    if (json.containsKey('user')) {
      return new Partner(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        id: json["id"],
        user: AuthUser.fromJson(json['user']),
        state: json["state"],
      );
    }
    return new Partner(
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        id: json["id"],
        user: AuthUser.find(json['user_id']),
        state: json["state"],
      );}

  Map<String, dynamic> toJson() => {
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "id": id,
    "user": user.toJson(),
    "state": state,
  };

  static getStateId(PartnerState state) {
    if (Partner.stateToNumber.containsKey(state)) {
      return Partner.stateToNumber[state];
    } else {
      return -1;
    }
  }

  bool stateIs(PartnerState state) {
    if (Partner.stateToNumber.containsKey(state)) {
      return this.state == stateToNumber[state];
    } else {
      return false;
    }
  }

  PartnerState getState() {
    PartnerState _state = stateToNumber.keys.firstWhere(
        (key) => stateToNumber[key] == this.state
    );
    return _state;
  }
}
