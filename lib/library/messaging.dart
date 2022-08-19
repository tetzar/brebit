import 'dart:async';
import 'dart:convert';

import 'package:brebit/api/auth.dart';
import 'package:brebit/model/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'cache.dart';
import 'notification.dart';

class MyFirebaseMessaging {
  static late FlutterLocalNotificationsPlugin plugin;

  static bool _hasInitialized = false;

  static late StreamController<FcmNotification> notificationStream;

  static Future<void> init() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.getNotificationSettings();
    notificationStream = new StreamController<FcmNotification>.broadcast();
    _hasInitialized = settings.alert != AppleNotificationSetting.enabled;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        onForeground(message);
      }
    });
    if (!_hasInitialized) {
      WidgetsFlutterBinding.ensureInitialized();
      _hasInitialized = true;
    }
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      String? fcmToken = await LocalManager.getFCMToken(firebaseUser.uid);
      if (fcmToken == null) {
        await setToken();
      }
    }
  }

  static dispose() {
    notificationStream.close();
  }

  static Future<void> setToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await saveTokenToDatabase(token);
    }
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
  }

  static Future<void> saveTokenToDatabase(String token) async {
    await AuthApi.setFCMToken(token);
  }

  static Future<void> onBackGround(RemoteMessage message) async {
    await Firebase.initializeApp();
    if (message.notification != null) {
      print(message.data);
      bool shouldNotify = message.data.containsKey('notify')
          ? jsonDecode(message.data['notify'])
          : true;
      FcmNotification _notification = new FcmNotification(message.data);
      Map<String, bool> notificationSetting = await MyNotification.getSetting();

      switch (_notification.getType()) {
        case UserNotificationType.partnerRequested:
        case UserNotificationType.partnerAccepted:
          if (!notificationSetting['friend']!) {
            shouldNotify = false;
          }
          break;
        case UserNotificationType.liked:
        case UserNotificationType.commented:
          if (!notificationSetting['reply']!) {
            shouldNotify = false;
          }
          break;
        case UserNotificationType.information:
          if (!notificationSetting['information']!) {
            shouldNotify = false;
          }
          break;
        default:
          break;
      }
      if (shouldNotify) {
        MyNotification.showNotification(message);
      }
    }
  }

  static Future<void> onForeground(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.
    if (notification != null && android != null) {
      // await FirebaseMessaging.instance
      //     .setForegroundNotificationPresentationOptions(
      //   alert: true, // Required to display a heads up notification
      //   badge: true,
      //   sound: true,
      // );
      //
      // const AndroidNotificationChannel channel = AndroidNotificationChannel(
      //   'high_importance_channel', // id
      //   'High Importance Notifications', // title
      //   'This channel is used for important notifications.', // description
      //   importance: Importance.max,
      // );
      //
      // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      //     FlutterLocalNotificationsPlugin();
      //
      // await flutterLocalNotificationsPlugin
      //     .resolvePlatformSpecificImplementation<
      //         AndroidFlutterLocalNotificationsPlugin>()
      //     ?.createNotificationChannel(channel);
      //
      // flutterLocalNotificationsPlugin.show(
      //     notification.hashCode,
      //     notification.title,
      //     notification.body,
      //     NotificationDetails(
      //       android: AndroidNotificationDetails(
      //         channel.id,
      //         channel.name,
      //         channel.description,
      //         icon: android?.smallIcon,
      //         // other properties...
      //       ),
      //     ));
      FcmNotification _fcmNotification = new FcmNotification(
        message.data,
      );
      notificationStream.add(_fcmNotification);
    }
  }
}

class FcmNotification {
  late Map data;
  late String type;

  FcmNotification(Map data) {
    this.data = data;
    this.type = data.containsKey('type') ? data['type'] : '';
  }

  int? getNotificationCount() {
    return this.data.containsKey('notification_count')
        ? int.parse(this.data['notification_count'])
        : null;
  }

  UserNotificationType? getType() {
    List<String> splitType = this.type.split('\\');
    switch (splitType.last) {
      case 'LikedNotification':
        return UserNotificationType.liked;
      case 'CommentNotification':
        return UserNotificationType.commented;
      case 'PartnerRequestNotification':
        return UserNotificationType.partnerRequested;
      case 'PartnerAcceptedNotification':
        return UserNotificationType.partnerAccepted;
      case 'InformationNotification':
        return UserNotificationType.information;
      default:
        return null;
    }
  }
}
