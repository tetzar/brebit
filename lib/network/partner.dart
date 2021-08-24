
import 'dart:convert';

import '../../model/partner.dart';
import '../../model/user.dart';
import 'api.dart';
import 'package:http/http.dart' as http;

class PartnerApi {
  static final Map<String, String> postRoutes = {
    'partnerRequest': '/partner/request',
    'acceptPartnerRequest': '/partner/accept',
    'block': '/partner/block',
    'unblock': '/partner/unblock',
  };

  static final Map<String, String> getRoutes = {
    'getPartners': '/auth/get-partners/{userId}',
    'partnerSuggestions': '/partner/suggestions',
    'partnerSearch': '/partner/search/{condition}',
  };

  static final Map<String, String> deleteRoutes = {
    'cancelPartner': '/partner/cancel/{partnerId}',
    'breakOffWithPartner': '/partner/break/{partnerId}',
  };

  static Future<List<Partner>> getPartners(AuthUser user) async {
    final http.Response response = await Network.getData(Network.routeNormalize(
        getRoutes['getPartners'], {'userId': user.id.toString()}));
    if (response.statusCode == 200) {
      return PartnerFromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      print('not found user : get profile user');
      return null;
    } else {
      throw Exception('Failed to get user');
    }
  }

  static Future<Map<String, Partner>> requestPartner(AuthUser otherUser) async {
    Map<String, dynamic> data = {'others_id': otherUser.id};
    http.Response response =
        await Network.postData(data, postRoutes['partnerRequest']);
    if (response.statusCode == 201) {
      Map<String, dynamic> body = jsonDecode(response.body);
      Map<String, Partner> partners = <String, Partner>{};
      partners['self_relation'] = Partner.fromJson(body['self_relation']);
      partners['other_relation'] = Partner.fromJson(body['other_relation']);
      return partners;
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in PartnerApi@requestPartner');
    }
  }

  static Future<void> cancelPartnerRequest(Partner partner) async {
    Map<String, String> data = {'partnerId': partner.id.toString()};
    http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['cancelPartner'], data));
    if (response.statusCode != 200) {
      print(response.body);
      throw Exception(
          'unexpected error occurred in PartnerApi@getRecommendStrategiesFromCondition');
    }
  }

  static Future<Map<String, Partner>> acceptPartnerRequest(Partner partner) async {
    Map<String, dynamic> data = {'partner_id': partner.id};
    http.Response response =
        await Network.postData(data, postRoutes['acceptPartnerRequest']);
    if (response.statusCode == 201) {
      Map<String, dynamic> body = jsonDecode(response.body);
      Map<String, Partner> partners = <String, Partner>{};
      partners['self_relation'] = Partner.fromJson(body['self_relation']);
      partners['other_relation'] = Partner.fromJson(body['other_relation']);
      return partners;
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in PartnerApi@acceptPartnerRequest');
    }
  }

  static Future<void> breakOffWithPartner(Partner partner) async {
    Map<String, String> data = {'partnerId': partner.id.toString()};
    http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(
            deleteRoutes['breakOffWithPartner'], data));
    if (response.statusCode != 200) {
      print(response.body);
      throw Exception(
          'unexpected error occurred in PartnerApi@breakOffWithPartner');
    }
  }

  static Future<Map<String, Partner>> block(AuthUser user) async {
    Map<String, dynamic> data = {
      'others_id': user.id
    };
    http.Response response = await Network.postData(
        data,
        postRoutes['block']
    );
    if (response.statusCode == 201) {
      Map<String, dynamic> body = jsonDecode(response.body);
      Map<String, Partner> partners = <String, Partner>{};
      partners['self_relation'] = Partner.fromJson(body['self_relation']);
      partners['other_relation'] = Partner.fromJson(body['other_relation']);
      return partners;
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in PartnerApi@requestPartner');
    }
  }

  static Future<void> unblock(AuthUser user) async {
    Map<String, dynamic> data = {
      'others_id': user.id
    };
    http.Response response = await Network.postData(
        data,
        postRoutes['unblock']
    );
    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('unexpected error occurred in PartnerApi@requestPartner');
    }
  }

  static Future<List<AuthUser>> getPartnerSuggestions(
      [String condition]) async {
    if (condition == null) {
      http.Response response = await Network.getData(Network.routeNormalize(
          getRoutes['partnerSuggestions'], new Map<String, String>()));
      if (response.statusCode == 200) {
        return AuthUserFromJson(jsonDecode(response.body));
      } else {
        print(response.body);
        throw Exception(
            'unexpected error occurred in PartnerApi@getPartnerSuggestions');
      }
    } else {
      Map<String, String> data = {'condition': condition};
      http.Response response = await Network.getData(
          Network.routeNormalize(getRoutes['partnerSearch'], data));
      if (response.statusCode == 200) {
        return AuthUserFromJson(jsonDecode(response.body));
      } else {
        print(response.body);
        throw Exception(
            'unexpected error occurred in PartnerApi@getPartnerSuggestions');
      }
    }
  }
}
