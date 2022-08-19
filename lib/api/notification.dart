import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../library/data-set.dart';
import '../../model/notification.dart';
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
      [DateTime? latestPostCreatedAt]) async {
    Map<String, String> data = {
      'latest': latestPostCreatedAt == null
          ? '_'
          : latestPostCreatedAt.toIso8601String()
    };
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getNotifications']!, data),
        "getNotifications@NotificationApi");
    Map<String, dynamic> body = jsonDecode(response.body);
    DataSet.dataSetConvert(body['data_set']);
    return userNotificationFromJson(body['notifications']);
  }

  static Future<List<UserNotification>> getUnreadNotifications() async {
    http.Response response = await Network.getData(
        getRoutes['getUnreadNotifications'],
        'getUnreadNotifications@NotificationApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    DataSet.dataSetConvert(body['data_set']);
    return userNotificationFromJson(body['notifications']);
  }

  static Future<DateTime> readNotification(String notificationId) async {
    Map<String, dynamic> data = {'notification_id': notificationId};
    http.Response response = await Network.postData(data,
        postRoutes['readNotification'], 'readNotification@NotificationApi');
    return DateTime.parse(jsonDecode(response.body)["read_at"]);
  }

  static Future<void> deleteNotification(String notificationId) async {
    Map<String, String> data = {'notificationId': notificationId};
    await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['deleteNotification']!, data),
        'deleteNotification@NotificationApi');
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
    http.Response response = await Network.postData(
        data, postRoutes['markAsRead'], "markAsRead@NotificationsApi");
    Map<String, dynamic> body = jsonDecode(response.body);
    DataSet.dataSetConvert(body['data_set']);
    return userNotificationFromJson(body['notifications']);
  }

  static Future<String?> getInformationNotificationBody(
      int informationId) async {
    Map<String, String> data = {'informationId': informationId.toString()};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getInformationBody']!, data),
        'getInformationNotificationBody@NotificationApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    return body['body'];
  }
}
