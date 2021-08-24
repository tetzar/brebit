import 'dart:convert';

import '../../model/analysis.dart';
import '../../model/habit.dart';
import 'api.dart';
import 'package:http/http.dart' as http;

class AnalysisApi {

  static final Map<String, String> postRoutes = {
    'addAnalysis': '/analysis/add',
  };

  static final Map<String, String> getRoutes = {
  };

  static final Map<String, String> deleteRoutes = {
    'removeAnalysis': '/analysis/remove/{habitId}/{analysisId}',
  };

  static Future<Habit> addAnalysis(Habit habit, Analysis analysis) async {
    Map<String, dynamic> data = {
      'analysis_id': analysis.id,
      'habit_id': habit.id
    };
    http.Response response = await Network.postData(
        data,
        postRoutes['addAnalysis']
    );
    if (response.statusCode == 201) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('message')) {
        print(body['message']);
        return null;
      }
      return Habit.fromJson(body);
    } else if (response.statusCode == 200) {
      print(jsonDecode(response.body)['message']);
      return null;
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in AnalysisApi@addAnalysis');
    }
  }

  static Future<Habit> removeAnalysis(Habit habit, Analysis analysis) async {
    Map<String, String> data = {
      'analysisId': analysis.id.toString(),
      'habitId': habit.id.toString()
    };
    http.Response response = await Network.deleteData(
      Network.routeNormalizeDelete(deleteRoutes['removeAnalysis'], data)
    );
    if (response.statusCode == 201) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('message')) {
        print(body['message']);
        return null;
      }
      return Habit.fromJson(body);
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in AnalysisApi@addAnalysis');
    }
  }

}