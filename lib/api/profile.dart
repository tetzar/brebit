import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../library/data-set.dart';
import '../../model/habit.dart';
import '../../model/habit_log.dart';
import '../../model/partner.dart';
import '../../model/post.dart';
import '../../model/user.dart';
import 'api.dart';

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
    'randomCustomId': '/profile/customId/random',
    'getUserImage': '/user/image/{userId}',
    'getHabitLogs': '/profile/habit/{userId}',
    'logsInAMonth': '/profile/habit/logs/{habitId}/{month}',
  };

  static final Map<String, String> deleteRoute = {
    'deleteProfileImage': '/profile/image/delete'
  };

  static Future<Map<String, dynamic>> getProfile(AuthUser user) async {
    Map<String, String> data = {'userId': user.id.toString()};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getProfile']!, data),
        'getProfile@ProfileApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    DataSet.dataSetConvert(body['data_set']);
    Map<String, dynamic>? habitData = body['habit'];
    Habit? _habit = habitData == null ? null : Habit.fromJson(habitData);
    List<dynamic>? logData = body['logs'];
    List<HabitLog>? _logs = logData == null ? null : habitLogFromJson(logData);
    List<Post> _posts = Post.sortByCreatedAt(postFromJson(body['posts']));
    List<Partner> _partners = partnerFromJson(body['partners']);
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
  }

  static Future<List<Post>> getProfilePosts(AuthUser user,
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
    final http.Response response = await Network.getData(
        Network.routeNormalize(route, data), "getProfilePosts@ProfileApi");
    Map body = jsonDecode(response.body);
    if (body.containsKey('count')) {
      user.postCount = body['count'];
    }
    return Post.sortByCreatedAt(postFromJson(body['posts']));
  }

  static Future<String> saveProfileImage(File imageFile) async {
    List<File> fileList = [imageFile];
    http.Response response = await Network.postDataWithImage({}, fileList,
        postRoutes['profileImageSave'], 'saveProfileImage@ProfileApi');
    return jsonDecode(response.body)['image_url'];
  }

  static Future<void> deleteProfileImage() async {
    await Network.deleteData(
        deleteRoute['deleteProfileImage'], 'deleteProfileImage@ProfileApi');
  }

  static Future<bool> customIdAvailable(String text) async {
    Map<String, String> data = {'id': text};
    http.Response response = await Network.getWithoutToken(
        Network.routeNormalize(getRoutes['customIdAvailable']!, data),
        'customIdAvailable@ProfileApi');
    return jsonDecode(response.body)['available'];
  }

  static Future<String> getRandomCustomId() async {
    http.Response response = await Network.getWithoutToken(
      getRoutes['randomCustomId'],
      'getRandomCustomId@ProfileApi'
    );
    return jsonDecode(response.body)['id'];
  }

  static Future<AuthUser> saveProfile(Map<String, dynamic> data,
      {File? imageFile}) async {
    http.Response response;
    Map<String, String> stringData = <String, String>{'data': jsonEncode(data)};
    if (imageFile != null) {
      response = await Network.postDataWithImage(stringData, [imageFile],
          postRoutes['profileSave'], 'saveProfile@ProfileApi');
    } else {
      response = await Network.postData(
          stringData, postRoutes['profileSave'], 'saveProfile@ProfileApi');
    }
    return AuthUser.fromJson(jsonDecode(response.body));
  }

  static Future<Map<String, dynamic>> getHabitLogs(AuthUser user) async {
    Map<String, String> data = <String, String>{'userId': user.id.toString()};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getHabitLogs']!, data),
        'getHabitLogs@ProfileApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    Map<String, dynamic> result = <String, dynamic>{};
    DataSet.dataSetConvert(body['data_set']);
    result['hasMore'] = body['has_more'];
    result['logs'] = habitLogFromJson(body['logs']);
    return result;
  }

  static Future<List<HabitLog>> getLogsInAMonth(
      Habit habit, DateTime month) async {
    Map<String, String> data = {
      'habitId': habit.id.toString(),
      'month': month.toString()
    };
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['logsInAMonth']!, data),
        "getLogsInAMonth@ProfileApi");
    Map<String, dynamic> body = jsonDecode(response.body);
    DataSet.dataSetConvert(body['data_set']);
    return habitLogFromJson(body['logs']);
  }
}
