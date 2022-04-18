import 'dart:convert';

import '../../model/analysis.dart';
import '../../model/habit.dart';
import 'api.dart';
import 'package:http/http.dart' as http;

class SystemApi {
  static final Map<String, String> postRoutes = {};

  static final Map<String, String> getRoutes = {
    'getLatestApplicationVersion': '/system/version/latest'
  };

  static final Map<String, String> deleteRoutes = {};

  static Future<String> getLatestVersion() async {
    http.Response response =
        await Network.getData(getRoutes['getLatestApplicationVersion']);
    Network.hasErrorMessage(response, 'getLatestVersion@SystemApi');
    return jsonDecode(response.body)['version'];
  }
}
