import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../library/data-set.dart';
import '../../model/category.dart';
import '../../model/habit.dart';
import '../../model/strategy.dart';
import '../../model/tag.dart';
import '../../model/user.dart';
import 'api.dart';

class StrategyApi {
  static final Map<String, String> postRoutes = {
    'storeStrategy': '/strategy/store',
    'changeStrategy': '/strategy/change',
    'storeHabitAndGetRecommendStrategies': '/strategy/get-recommend-and-store',
    'getStrategiesFromCondition': '/strategy/from-condition',
    'addStrategy': '/strategy/add',
  };

  static final Map<String, String> getRoutes = {
    'getRecommendStrategies':
        '/strategy/get-recommend-strategy/{categoryId}/{userId}',
  };

  static final Map<String, String> deleteRoutes = {
    'removeStrategy': '/strategy/remove/{habitId}/{strategyIds}',
  };

  static Future<Map<String, List<Strategy>>> getRecommendStrategies(
      Category category) async {
    final http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getRecommendStrategies']!,
            {'categoryId': category.id.toString()}),
        'getRecommendStrategies@StrategyApi');
    Map received = jsonDecode(response.body);
    Map<String, List<Strategy>> result = {};
    result['recommend'] = (received['recommend'].length > 0)
        ? strategyFromJson(received['recommend'])
        : [];
    return result;
  }

  static Future<Map<String, dynamic>> storeHabitAndGetRecommendStrategies(
      Habit habit) async {
    Map<String, dynamic> data = {'habit': habit.toJson()};

    final http.Response response = await Network.postData(
        data,
        postRoutes['storeHabitAndGetRecommendStrategies'],
        "storeHabitAndGetRecommendStrategies@StrategyApi");
    Map received = jsonDecode(response.body);
    Map<String, dynamic> result = {};
    result['habit'] =
        (received['habit'] != null) ? Habit.fromJson(received['habit']) : null;
    result['recommend'] = (received['recommend'].length > 0)
        ? strategyFromJson(received['recommend'])
        : [];
    return result;
  }

  static Future<Habit> storeStrategy(
      Habit habit, Map<String, dynamic> data) async {
    Map<String, dynamic> sendData = {};
    sendData['habit_id'] = habit.id;
    sendData['data'] = data;
    final http.Response response = await Network.postData(
        sendData, postRoutes['storeStrategy'], "storeStrategy@StrategyApi");
    Map<String, dynamic> responseData = jsonDecode(response.body);
    return Habit.fromJson(responseData);
  }

  static Future<Map<String, dynamic>> changeStrategy(
      Map<String, dynamic> data, Habit habit) async {
    Map<String, dynamic> sendData = new Map<String, dynamic>();
    sendData['habit_id'] = habit.id;
    sendData['data'] = data;
    final http.Response response = await Network.postData(
        sendData, postRoutes['changeStrategy'], 'changeStrategy@StrategyApi');
    Map responseData = jsonDecode(response.body);
    DataSet.dataSetConvert(responseData['data_set']);
    return {
      'user': AuthUser.fromJson(responseData['user']),
      'habit': Habit.fromJson(responseData['habit'])
    };
  }

  static Future<List<Strategy>> getRecommendStrategiesFromCondition(
      List<Tag> tags, Map<String, dynamic> mental) async {
    List<int> tagIds = [];
    List<String> newTags = [];
    tags.forEach((tag) {
      int? id = tag.id;
      if (id == null) {
        newTags.add(tag.name);
      } else {
        tagIds.add(id);
      }
    });
    Map<String, dynamic> data = {
      'tags': tagIds,
      'new_tags': newTags,
      'mental': mental
    };
    http.Response response = await Network.postData(
        data,
        postRoutes['getStrategiesFromCondition'],
        'getRecommendStrategiesFromCondition@StrategyApi');
    List<Strategy> recommends = strategyFromJson(jsonDecode(response.body));
    return recommends;
  }

  static Future<Habit> addStrategy(Strategy strategy, Habit habit) async {
    Map<String, dynamic> data = {
      'strategy_id': strategy.id,
      'habit_id': habit.id
    };
    http.Response response = await Network.postData(
        data, postRoutes['addStrategy'], 'addStrategy@StrategyApi');
    return Habit.fromJson(jsonDecode(response.body));
  }

  static Future<Habit> removeStrategies(
      Habit habit, List<int> strategyIds) async {
    String strategyIdsFormatted = '_';
    strategyIds.forEach((id) {
      strategyIdsFormatted += id.toString() + '_';
    });
    Map<String, String> data = {
      'habitId': habit.id.toString(),
      'strategyIds': strategyIdsFormatted
    };
    http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['removeStrategy']!, data),
        'removeStrategies@StrategyApi');
    return Habit.fromJson(jsonDecode(response.body));
  }
}
