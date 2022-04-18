import 'dart:convert';

import '../../library/data-set.dart';
import '../../model/notification.dart';

import 'package:http/http.dart' as http;

import 'api.dart';

class NotificationApi {
  static final Map<String, String> postRoutes = {
    'readNotification': '/notification/read',
    'markAsRead': '/notification/read-all',
  };

  static final Map<String, String> getRoutes = {
    'getNotifications': '/notification/get/{latest}',
    'getUnreadNotifications': '/notification/unread',
    'getInformationBody': '/notification/information/{informationId}',
  };

  static final Map<String, String> deleteRoutes = {
    'deleteNotification': '/notification/delete/{notificationId}',
  };

  static Future<List<UserNotification>> getNotifications(
      [DateTime latestPostCreatedAt]) async {
    Map<String, String> data = {
      'latest': latestPostCreatedAt == null
          ? '_'
          : latestPostCreatedAt.toIso8601String()
    };
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getNotifications'], data));
    if (response.statusCode == 200) {
      try {
        Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('message')) {
          print(body['message']);
          return null;
        }
        DataSet.dataSetConvert(body['data_set']);
        return UserNotificationFromJson(body['notifications']);
      } catch (e) {
        print(e.toString());
        return null;
      }
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in NotificationApi@getNotifications');
    }
  }

  static Future<List<UserNotification>> getUnreadNotifications() async {
    http.Response response = await Network.getData(getRoutes['getUnreadNotifications']);
    if (response.statusCode == 200) {
      try {
        Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('message')) {
          print(body['message']);
          return null;
        }
        DataSet.dataSetConvert(body['data_set']);
        return UserNotificationFromJson(body['notifications']);
      } catch (e) {
        print(e.toString());
        return null;
      }
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in NotificationApi@getNotifications');
    }
  }

  static Future<DateTime> readNotification(String notificationId) async {
    Map<String, dynamic> data = {'notification_id': notificationId};
    http.Response response =
        await Network.postData(data, postRoutes['readNotification']);
    if (response.statusCode == 201) {
      return DateTime.parse(jsonDecode(response.body)["read_at"]);
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in NotificationApi@readNotification');
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    Map<String, String> data = {'notificationId': notificationId};
    final http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['deleteNotification'], data));
    if (response.statusCode != 200) {
      print(response.body);
      throw Exception(
          'unexpected error occurred in NotificationApi@deleteNotification');
    }
  }

  static Future<List<UserNotification>> markAsRead(
      List<UserNotification> notifications) async {
    List<String> _notificationIds = <String>[];
    for (UserNotification _notification in notifications) {
      _notificationIds.add(_notification.id);
    }
    if (_notificationIds.length == 0) {
      return <UserNotification>[];
    }
    Map<String, dynamic> data = {'notification_ids': _notificationIds};
    http.Response response =
        await Network.postData(data, postRoutes['markAsRead']);
    if (response.statusCode == 201) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('message')) {
        print(body['message']);
        return null;
      }
      DataSet.dataSetConvert(body['data_set']);
      return UserNotificationFromJson(body['notifications']);
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in markAsRead@NotificationApi');
    }
  }

  static Future<String> getInformationNotificationBody(
      int informationId) async {
    Map<String, String> data = {'informationId': informationId.toString()};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getInformationBody'], data));
    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('message')) {
        print(body['message']);
        return null;
      }
      return body['body'];
    } else {
      print(response.body);
      throw Exception(
          'unexpected error occurred in getInformationBody@NotificationApi');
    }
  }
}
