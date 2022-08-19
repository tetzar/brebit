import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../library/data-set.dart';
import '../../model/analysis.dart';
import '../../model/strategy.dart';
import '../../model/user.dart';
import 'api.dart';

class SearchApi {
  static final Map<String, String> postRoutes = {};

  static final Map<String, String> getRoutes = {
    'searchResult': '/search/{text}',
  };

  static Future<Map<String, dynamic>> getSearchResult(String text) async {
    Map<String, String> data = {'text': text};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['searchResult']!, data),
        'getSearchResult@SearchApi');
    Map<String, dynamic> bodyAsMap = jsonDecode(response.body);
    DataSet.dataSetConvert(bodyAsMap['data_set']);
    List<Strategy> strategies = strategyFromJson(bodyAsMap['strategies']);
    List<AuthUser> users = authUserFromJson(bodyAsMap['users']);
    List<Analysis> analyses = analysisFromJson(bodyAsMap['analyses']);
    Map<String, dynamic> result = {
      'strategies': strategies,
      'users': users,
      'analyses': analyses
    };
    return result;
  }
}
