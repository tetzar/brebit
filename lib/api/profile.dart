import 'dart:convert';
import 'dart:io';

import '../../library/data-set.dart';
import '../../model/post.dart';
import '../../model/habit.dart';
import '../../model/habit_log.dart';
import '../../model/partner.dart';
import '../../model/user.dart';
import 'api.dart';
import 'package:http/http.dart' as http;

class ProfileApi {
  static final Map<String, String> postRoutes = {
    'profileImageSave': '/profile/image/save',
    'profileSave': '/profile/save',
  };

  static final Map<String, String> getRoutes = {
    'getProfile': '/auth/profile/{userId}',
    'getProfilePosts': '/auth/profile-timeline/{userId}',
    'reloadProfilePosts': '/auth/profile-timeline/later/{userId}/{dateTime}',
    'reloadOlderProfilePosts':
        '/auth/profile-timeline/older/{userId}/{dateTime}',
    'customIdAvailable': '/profile/customId/available/{id}',
    'getUserImage': '/user/image/{userId}',
    'getHabitLogs': '/profile/habit/{userId}',
    'logsInAMonth': '/profile/habit/logs/{habitId}/{month}',
  };

  static Future<Map<String, dynamic>?> getProfile(AuthUser user) async {
    Map<String, String> data = {'userId': user.id.toString()};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getProfile']!, data));
    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('message')) {
        print(body['message']);
        return null;
      }
      DataSet.dataSetConvert(body['data_set']);
      Habit _habit = Habit.fromJson(body['habit']);
      List<HabitLog> _logs = HabitLogFromJson(body['logs']);
      List<Post> _posts = Post.sortByCreatedAt(PostFromJson(body['posts']));
      List<Partner> _partners = PartnerFromJson(body['partners']);
      Partner? _partner =
          body['partner'] != null ? Partner.fromJson(body['partner']) : null;
      Map<String, dynamic> result = <String, dynamic>{
        'habit': _habit,
        'logs': _logs,
        'posts': _posts,
        'partners': _partners,
        'partner': _partner
      };
      return result;
    } else {
      print(response.body);
      throw Exception('error occurred in ProfileApi@getProfile');
    }
  }

  static Future<List<Post>?> getProfilePosts(AuthUser user,
      [DateTime? t, bool older = false]) async {
    String route;
    Map<String, String> data;
    if (t == null) {
      route = getRoutes['getProfilePosts']!;
      data = {'userId': user.id.toString()};
    } else {
      if (!older) {
        route = getRoutes['reloadProfilePosts']!;
        data = {'userId': user.id.toString(), 'dateTime': t.toString()};
      } else {
        route = getRoutes['reloadOlderProfilePosts']!;
        data = {'userId': user.id.toString(), 'dateTime': t.toString()};
      }
    }
    final http.Response response =
        await Network.getData(Network.routeNormalize(route, data));
    print(response.body);
    if (response.statusCode == 200) {
      try {
        Map body = jsonDecode(response.body);
        if (body.containsKey('count')) {
          user.postCount = body['count'];
        }
        return Post.sortByCreatedAt(PostFromJson(body['posts']));
      } catch (e) {
        print(e.toString());
        throw e;
      }
    } else if (response.statusCode == 404) {
      print('not found user : get profile user');
      return null;
    } else {
      throw Exception('Failed to get user');
    }
  }

  static Future<String?> saveProfileImage(File imageFile) async {
    List<File> fileList = [imageFile];
    http.Response response = await Network.postDataWithImage(
        {}, fileList, postRoutes['profileImageSave']);
    if (response.statusCode == 201) {
      return jsonDecode(response.body)['image_url'];
    } else if (response.statusCode == 404) {
      print(response.body);
      return null;
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in ProfileApi@saveProfileImage');
    }
  }

  static Future<bool> customIdAvailable(String text) async {
    Map<String, String> data = {'id': text};
    http.Response response = await Network.getWithoutToken(
        Network.routeNormalize(getRoutes['customIdAvailable']!, data));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['available'];
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in ProfileApi@customIdAvailable');
    }
  }

  static Future<AuthUser> saveProfile(Map<String, dynamic> data,
      {File? imageFile}) async {
    http.Response response;
    Map<String, String> stringData = <String, String>{
      'data': jsonEncode(data)
    };
    if (imageFile != null) {
      response = await Network.postDataWithImage(
          stringData, [imageFile], postRoutes['profileSave']);
    } else {
      response = await Network.postData(stringData, postRoutes['profileSave']);
    }
    if (response.statusCode == 201) {
      print(response.body);
      return AuthUser.fromJson(jsonDecode(response.body));
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in ProfileApi@saveProfile');
    }
  }

  static Future<Map<String, dynamic>?> getHabitLogs(AuthUser user) async {
    Map<String, String> data = <String, String>{'userId': user.id.toString()};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getHabitLogs']!, data));
    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('message')) {
        print(body['message']);
        return null;
      } else {
        Map<String, dynamic> result = <String, dynamic>{};
        DataSet.dataSetConvert(body['data_set']);
        result['hasMore'] = body['has_more'];
        result['logs'] = HabitLogFromJson(body['logs']);
        return result;
      }
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in ProfileApi@getHabit');
    }
  }

  static Future<List<HabitLog>?> getLogsInAMonth(
      Habit habit, DateTime month) async {
    Map<String, String> data = {
      'habitId': habit.id.toString(),
      'month': month.toString()
    };
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['logsInAMonth']!, data));
    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('message')) {
        print(body['message']);
        return null;
      }
      DataSet.dataSetConvert(body['data_set']);
      return HabitLogFromJson(body['logs']);
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in ProfileApi@getLogsInAMonth');
    }
  }
}
