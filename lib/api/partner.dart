import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../model/partner.dart';
import '../../model/user.dart';
import 'api.dart';

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
    final http.Response response = await Network.getData(
        Network.routeNormalize(
            getRoutes['getPartners']!, {'userId': user.id.toString()}),
        "getPartners@PartnerApi");
    return partnerFromJson(jsonDecode(response.body));
  }

  static Future<Map<String, Partner>> requestPartner(AuthUser otherUser) async {
    Map<String, dynamic> data = {'others_id': otherUser.id};
    http.Response response = await Network.postData(
        data, postRoutes['partnerRequest'], "requestPartner@PartnerApi");
    Map<String, dynamic> body = jsonDecode(response.body);
    Map<String, Partner> partners = <String, Partner>{};
    partners['self_relation'] = Partner.fromJson(body['self_relation']);
    partners['other_relation'] = Partner.fromJson(body['other_relation']);
    return partners;
  }

  static Future<void> cancelPartnerRequest(Partner partner) async {
    Map<String, String> data = {'partnerId': partner.id.toString()};
    await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['cancelPartner']!, data),
        "cancelPartnerRequest@PartnerApi");
  }

  static Future<Map<String, Partner>> acceptPartnerRequest(
      Partner partner) async {
    Map<String, dynamic> data = {'partner_id': partner.id};
    http.Response response = await Network.postData(data,
        postRoutes['acceptPartnerRequest'], 'acceptPartnerRequest@PartnerApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    Map<String, Partner> partners = <String, Partner>{};
    partners['self_relation'] = Partner.fromJson(body['self_relation']);
    partners['other_relation'] = Partner.fromJson(body['other_relation']);
    return partners;
  }

  static Future<void> breakOffWithPartner(Partner partner) async {
    Map<String, String> data = {'partnerId': partner.id.toString()};
    await Network.deleteData(
        Network.routeNormalizeDelete(
            deleteRoutes['breakOffWithPartner']!, data),
        'breakOffWithPartner@PartnerApi');
  }

  static Future<Map<String, Partner>> block(AuthUser user) async {
    Map<String, dynamic> data = {'others_id': user.id};
    http.Response response =
        await Network.postData(data, postRoutes['block'], "block@PartnerApi");
    Map<String, dynamic> body = jsonDecode(response.body);
    Map<String, Partner> partners = <String, Partner>{};
    partners['self_relation'] = Partner.fromJson(body['self_relation']);
    partners['other_relation'] = Partner.fromJson(body['other_relation']);
    return partners;
  }

  static Future<void> unblock(AuthUser user) async {
    Map<String, dynamic> data = {'others_id': user.id};
    await Network.postData(data, postRoutes['unblock'], 'unblock@PartnerApi');
  }

  static Future<List<AuthUser>> getPartnerSuggestions(
      [String? condition]) async {
    if (condition == null) {
      http.Response response = await Network.getData(
          Network.routeNormalize(
              getRoutes['partnerSuggestions']!, new Map<String, String>()),
          'getPartnerSuggestions@PartnerApi');

      return authUserFromJson(jsonDecode(response.body));
    } else {
      Map<String, String> data = {'condition': condition};
      http.Response response = await Network.getData(
          Network.routeNormalize(getRoutes['partnerSearch']!, data),
          'getPartnerSuggestions@PartnerApi');
      return authUserFromJson(jsonDecode(response.body));
    }
  }
}
