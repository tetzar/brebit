
import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:rxdart/subjects.dart';

import 'cache.dart';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    this.title,
    this.body,
    this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

class MyNotification{

  static final BehaviorSubject<String> selectNotificationSubject =
  BehaviorSubject<String>();

  MethodChannel platform =
  MethodChannel('dexterx.dev/flutter_local_notifications_example');

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static late NotificationAppLaunchDetails? notificationAppLaunchDetails;

  static late AndroidInitializationSettings initializationSettingsAndroid;

  static final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
  BehaviorSubject<ReceivedNotification>();

  static Future<void> init() async{
    notificationAppLaunchDetails =
    await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    initializationSettingsAndroid =
    AndroidInitializationSettings('brebit_sample_icon');
    // TODO It is sample
    /// Note: permissions aren't requested here just to demonstrate that can be
    /// done later
    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) {
          print(payload);
          didReceiveLocalNotificationSubject.add(ReceivedNotification(
              id: id, title: title, body: body, payload: payload));
        });
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) {
          if (payload != null) {
            debugPrint('notification payload: $payload');
            selectNotificationSubject.add(payload);
          }
        });

    _requestPermissions();
    // _configureSelectNotificationSubject();

  }

  static dispose() {
    didReceiveLocalNotificationSubject.close();
  }

  static void _requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }


  static void configureDidReceiveLocalNotificationSubject(BuildContext context) {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title!)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body!)
              : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                // await Navigator.push(
                //   context,
                //   MaterialPageRoute<void>(
                //     builder: (BuildContext context) =>
                //         SecondScreen(receivedNotification.payload),
                //   ),
                // );
              },
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }
  //
  // static void _configureSelectNotificationSubject(BuildContext context) {
  //   selectNotificationSubject.stream.listen((String payload) async {
  //     await Navigator.push(
  //       context,
  //       MaterialPageRoute<void>(
  //           builder: (BuildContext context) => SecondScreen(payload)),
  //     );
  //   });
  // }



  static Future<void> showNotification(RemoteMessage message) async {
    if(message.notification != null){
      RemoteNotification notification = message.notification!;
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
          'your channel id', 'your channel name', channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
          0, notification.title, notification.body, platformChannelSpecifics,
          payload: 'item x');
    }
  }

  static Future<bool> getPermission() async{
    PermissionStatus status = await NotificationPermissions.getNotificationPermissionStatus();
    return status == PermissionStatus.granted;
  }

  static Future<void> setPermission() async {
    await AppSettings.openNotificationSettings();
  }

  static Future<Map<String, bool>> getSetting() async{
    Map<String, bool>? settings = await LocalManager.getNotificationSetting();
    if (settings == null) {
      settings = {
        'challenge': true,
        'reply': true,
        'friend': true,
        'information': true,
      };
    }
    return settings;
  }

  static Future<void> setSetting(bool setting, String id) async {
    Map<String, bool> settings = await getSetting();
    settings[id] = setting;
    await LocalManager.setNotificationSetting(settings);
  }
}