import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';

class SystemApi {
  static final Map<String, String> postRoutes = {};

  static final Map<String, String> getRoutes = {
    'getLatestApplicationVersion': '/system/version/latest'
  };

  static final Map<String, String> deleteRoutes = {};

  static Future<String> getLatestVersion() async {
    http.Response response = await Network.getData(
        getRoutes['getLatestApplicationVersion'], 'getLatestVersion@SystemApi');
    return jsonDecode(response.body)['version'];
  }
}
