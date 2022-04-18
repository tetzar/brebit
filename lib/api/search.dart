
import 'dart:convert';

import '../../library/data-set.dart';
import '../../model/analysis.dart';
import '../../model/strategy.dart';
import '../../model/user.dart';

import 'api.dart';
import 'package:http/http.dart' as http;

class SearchApi {
  static final Map<String, String> postRoutes = {
  };

  static final Map<String, String> getRoutes = {
    'searchResult': '/search/{text}',
  };

  static Future<Map<String, dynamic>> getSearchResult(String text) async {
      Map<String, String> data = {
        'text': text
      };
      http.Response response = await Network.getData(
        Network.routeNormalize(
          getRoutes['searchResult'],
          data
        )
      );
      if (response.statusCode == 201) {
        print(response.body);
        Map<String, dynamic> bodyAsMap = jsonDecode(response.body);
        DataSet.dataSetConvert(bodyAsMap['data_set']);
        List<Strategy> strategies = StrategyFromJson(bodyAsMap['strategies']);
        List<AuthUser> users = AuthUserFromJson(bodyAsMap['users']);
        List<Analysis> analyses = AnalysisFromJson(bodyAsMap['analyses']);
        Map<String, dynamic> result = {
          'strategies': strategies,
          'users': users,
          'analyses': analyses
        };
        return result;
      } else {
        print(response.body);
        throw Exception('error occurred in SearchApi@getSearchResult');
      }

  }

}