import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../library/data-set.dart';
import '../../model/category.dart';
import '../../model/habit.dart';
import '../../model/habit_log.dart';
import '../../model/strategy.dart';
import '../../model/tag.dart';
import '../../model/user.dart';
import '../provider/condition.dart';
import 'api.dart';

class HabitApi {
  static final Map<String, String> postRoutes = {
    'aimDateUpdate': '/habit/aim-date/update',
    'saveInformation': '/habit/information/store',
    'suppressedWant': '/trigger/want/suppressed',
    'didFromWant': '/trigger/want/did',
    'did': '/trigger/did',
    'endured': '/trigger/endured',
    'suspend': '/habit/suspend',
    'restart': '/habit/restart',
  };

  static final Map<String, String> getRoutes = {
    'getHomeData': '/home/{analysis-version}',
    'getConditionSuggestions': '/trigger/condition/suggestions/{text}',
  };

  static Future<Map<String, dynamic>> getHomeData(
      {String? analysisVersion}) async {
    if (analysisVersion == null) {
      analysisVersion = '0';
    }
    Map<String, String> data = {'analysis-version': analysisVersion};
    final http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getHomeData']!, data),
        'getHomeDate@HabitApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    return <String, dynamic>{
      'habit': body['habit'] == null ? null : Habit.fromJson(body['habit']),
      'analysisVersion': body['analysis_version'],
      'notificationCount': body['notification_count'],
    };
  }

  static Future<Map<String, dynamic>> saveInformation(
      Category category, Map<String, dynamic> data) async {
    Map<String, dynamic> sendData = {
      'category_name': category.systemName,
      'data': data,
    };

    final http.Response response = await Network.postData(
        sendData, postRoutes['saveInformation'], 'saveInformation@HabitApi');
    Map received = jsonDecode(response.body);
    DataSet.dataSetConvert(received['data_set']);
    Map<String, List<Strategy>> result = {};
    Habit habit = Habit.fromJson(received['habit']);
    result['recommend'] = (received['recommend'].length > 0)
        ? strategyFromJson(received['recommend'])
        : [];
    result['others'] = (received['others'].length > 0)
        ? strategyFromJson(received['others'])
        : [];
    return {
      'success': true,
      'strategies': result,
      'habit': habit,
    };
  }

  static Future<Habit> updateAimDate(Habit habit, int days) async {
    Map<String, dynamic> data = {'days': days, 'habit_id': habit.id};
    http.Response response = await Network.postData(
        data, postRoutes['aimDateUpdate'], 'updateAimDate@HabitApi');
    return Habit.fromJson(jsonDecode(response.body)['habit']);
  }

  static Future<Map<String, dynamic>> getConditionSuggestions(
      String text) async {
    Map<String, String> data = {'text': '_' + text};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getConditionSuggestions']!, data),
        'getConditionSuggestions@HabitApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    List<Tag> recommendedTags = TagFromJson(body['tags']);
    Tag? inputTag;
    if (body['hit'] != null) {
      inputTag = Tag.fromJson(body['hit']);
    } else if (text.isNotEmpty) {
      inputTag = Tag(name: text);
    }
    return {'tags': recommendedTags, 'hit': inputTag};
  }

  static Future<Habit> suppressedWant(
      List<int> usedStrategyIds,
      List<Tag> conditionTags,
      MentalValue mental,
      int desire,
      Habit habit) async {
    List<int> tagIds = [];
    List<String> newTags = [];
    conditionTags.forEach((tag) {
      int? id = tag.id;
      if (id == null) {
        newTags.add(tag.name);
      } else {
        tagIds.add(id);
      }
    });
    Map<String, dynamic> data = {
      'habit_id': habit.id,
      'mental': mental.id,
      'tags': tagIds,
      'desire': desire,
      'new_tags': newTags,
      'strategies': usedStrategyIds
    };
    http.Response response = await Network.postData(
        data, postRoutes['suppressedWant'], 'suppressedWant@HabitApi');
    return Habit.fromJson(jsonDecode(response.body));
  }

  static Future<Map<String, dynamic>> didFromWant(
      List<int> usedStrategyIds,
      List<Tag> conditionTags,
      MentalValue mental,
      int desire,
      Habit habit) async {
    List<int> tagIds = [];
    List<String> newTags = [];
    conditionTags.forEach((tag) {
      int? id = tag.id;
      if (id == null) {
        newTags.add(tag.name);
      } else {
        tagIds.add(id);
      }
    });
    Map<String, dynamic> data = {
      'habit_id': habit.id,
      'mental': mental.id,
      'desire': desire,
      'tags': tagIds,
      'new_tags': newTags,
      'strategies': usedStrategyIds
    };

    http.Response response = await Network.postData(
        data, postRoutes['didFromWant'], 'didFromWant@HabitApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    Map<String, dynamic> result = <String, dynamic>{};
    result['habit'] = Habit.fromJson(body['habit']);
    result['log'] = HabitLog.fromJson(body['did_log']);
    return result;
  }

  static Future<Map<String, dynamic>> did(
      MentalValue mental,
      int desire,
      List<Tag> conditionTags,
      List<int> usedStrategyIds,
      int amount,
      Habit habit) async {
    List<int> tagIds = [];
    List<String> newTags = [];
    conditionTags.forEach((tag) {
      if (tag.id == null) {
        newTags.add(tag.name);
      } else {
        tagIds.add(tag.id!);
      }
    });
    Map<String, dynamic> data = {
      'habit_id': habit.id,
      'mental': mental.id,
      'desire': desire,
      'tags': tagIds,
      'amount': amount,
      'new_tags': newTags,
      'strategies': usedStrategyIds
    };

    http.Response response =
        await Network.postData(data, postRoutes['did'], 'did@HabitApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    Map<String, dynamic> result = <String, dynamic>{};
    result['habit'] = Habit.fromJson(body['habit']);
    result['log'] = HabitLog.fromJson(body['did_log']);
    return result;
  }

  static Future<Habit> endured(
      List<int> usedStrategyIds,
      List<Tag> conditionTags,
      MentalValue mental,
      int desired,
      Habit habit) async {
    List<int> tagIds = [];
    List<String> newTags = [];
    conditionTags.forEach((tag) {
      int? id = tag.id;
      if (id == null) {
        newTags.add(tag.name);
      } else {
        tagIds.add(id);
      }
    });
    Map<String, dynamic> data = {
      'habit_id': habit.id,
      'mental': mental.id,
      'desire': desired,
      'tags': tagIds,
      'new_tags': newTags,
      'strategies': usedStrategyIds
    };

    http.Response response =
        await Network.postData(data, postRoutes['endured'], 'endured@HabitApi');
    return Habit.fromJson(jsonDecode(response.body));
  }

  static Future<Map<String, dynamic>> suspend(CategoryName categoryName) async {
    Category _category = Category.findFromCategoryName(categoryName);
    Map<String, dynamic> data = {'category_id': _category.id};
    http.Response response =
        await Network.postData(data, postRoutes['suspend'], 'suspend@HabitApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    DataSet.dataSetConvert(body['data_set']);
    Map<String, dynamic> result = <String, dynamic>{};
    result['habit'] = Habit.fromJson(body['habit']);
    result['user'] = AuthUser.fromJson(body['user']);
    return result;
  }

  static Future<Map<String, dynamic>> restart(CategoryName categoryName) async {
    Category? _category = Category.findFromCategoryName(categoryName);
    Map<String, dynamic> data = {'category_id': _category.id};
    http.Response response =
        await Network.postData(data, postRoutes['restart'], 'restart@HabitApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    DataSet.dataSetConvert(body['data_set']);
    Map<String, dynamic> result = <String, dynamic>{};
    result['habit'] = Habit.fromJson(body['habit']);
    result['user'] = AuthUser.fromJson(body['user']);
    return result;
  }
}
