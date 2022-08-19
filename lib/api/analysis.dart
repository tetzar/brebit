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
        postRoutes['addAnalysis'],
        "addAnalysis@AnalysisApi"
    );
    Map<String, dynamic> body = jsonDecode(response.body);
    return Habit.fromJson(body);
  }

  static Future<Habit> removeAnalysis(Habit habit, Analysis analysis) async {
    Map<String, String> data = {
      'analysisId': analysis.id.toString(),
      'habitId': habit.id.toString()
    };
    http.Response response = await Network.deleteData(
      Network.routeNormalizeDelete(deleteRoutes['removeAnalysis']!, data)
          ,"removeAnalysis@AnalysisApi"
    );
    Map<String, dynamic> body = jsonDecode(response.body);
    return Habit.fromJson(body);
  }

}