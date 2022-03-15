import 'dart:convert';
import 'dart:core';
import 'dart:async';

import 'package:brebit/model/draft.dart';
import 'package:brebit/model/habit.dart';
import 'package:brebit/model/notification.dart';
import 'package:brebit/model/post.dart';
import 'package:brebit/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Key {
  token,
  FCMToken,
  started,
  register,
  posts,
  habit,
  profileTimeLine,
  partners,
  notifications,
  notificationSetting,
  recentSearch,
  draft,
  analysisLanguage,
}

class
LocalManager {
  static SharedPreferences _prefs;

  static final Map<_Key, String> _keyList = <_Key, String>{
    _Key.posts: 'posts/{userId}/{name}',
    _Key.started: 'started',
    _Key.token: 'token/{firebaseUid}',
    _Key.FCMToken: 'fcm-token/{firebaseUid}',
    _Key.register: 'register/{firebaseUid}',
    _Key.habit: 'habit/{userId}',
    _Key.profileTimeLine: 'profile-time-line/{userId}',
    _Key.partners: 'partners/{userId}',
    _Key.notifications: 'notifications/{userId}',
    _Key.notificationSetting: 'notification-setting',
    _Key.recentSearch: 'recent-search/{userId}',
    _Key.draft: 'draft/{userId}',
    _Key.analysisLanguage: 'analysis-language/{userId}',
  };

  static String _getKey(_Key key, [Map<String, String> data]) {
    if (_keyList.containsKey(key)) {
      String _key = _keyList[key];
      if (data != null) {
        data.forEach((k, v) {
          _key = _key.replaceAll('{$k}', v);
        });
      }
      return _key;
    }
    return null;
  }

  static Future<SharedPreferences> get preferences async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs;
  }

  static Future<void> _storeExpires(String key,
      [Duration storeDuration]) async {
    var prefs = await preferences;
    if (storeDuration != null ? storeDuration.isNegative : false) {
      return;
    }
    storeDuration = storeDuration ?? Duration(hours: 24);
    prefs.setString(key + '/expires-at',
        DateTime.now().add(storeDuration).toIso8601String());
  }

  static Future<bool> _expired(String key) async {
    var prefs = await preferences;
    String _key = key + '/expires-at';
    if (!prefs.containsKey(_key)) {
      return false;
    }
    String iso6801Time = prefs.getString(key + '/expires-at');
    return DateTime.now().isAfter(DateTime.parse(iso6801Time).toLocal());
  }

  static Future<void> _set(String key, dynamic value,
      {Duration storeDuration, bool expires = true}) async {
    assert(value is int ||
        value is double ||
        value is String ||
        value is List<String> ||
        value is bool);
    var prefs = await preferences;
    if (prefs.containsKey(key)) {
      prefs.remove(key);
    }
    if (value is int) {
      prefs.setInt(key, value);
    }
    if (value is double) {
      prefs.setDouble(key, value);
    }
    if (value is String) {
      prefs.setString(key, value);
    }
    if (value is List<String>) {
      prefs.setStringList(key, value);
    }
    if (value is bool) {
      prefs.setBool(key, value);
    }
    if (expires) {
      await _storeExpires(key, storeDuration);
    }
  }

  static Future<dynamic> _get(String key) async {
    SharedPreferences prefs = await preferences;
    if (await _expired(key)) {
      return null;
    }
    if (prefs.containsKey(key)) {
      dynamic value = prefs.get(key);
      if (value is List<dynamic>) {
        value = value.cast<String>();
      }
      return value;
    }
    return null;
  }

  static Future<void> _remove(String key) async {
    SharedPreferences prefs = await preferences;
    if (prefs.containsKey(key)) {
      prefs.remove(key);
    }
    if (prefs.containsKey(key + '/expires-at')) {
      prefs.remove(key + '/expires-at');
    }
  }

  //---------------------------------
  //  token
  //---------------------------------
  static Future<String> getToken(String firebaseUid) async {
    String key = _getKey(_Key.token, {'firebaseUid': firebaseUid});
    List<String> tokenData = await _get(key);
    if (tokenData != null) {
      String token = tokenData[0];
      DateTime expireAt = DateTime.parse(tokenData[1]);
      if (DateTime.now().isAfter(expireAt)) {
        return 'expired';
      } else {
        return token;
      }
    } else {
      return '';
    }
  }

  static Future<void> setToken(
      String token, DateTime expireAt, String firebaseUid) async {
    String key = _getKey(_Key.token, {'firebaseUid': firebaseUid});
    List<String> value = [token, expireAt.toIso8601String()];
    await _set(key, value, expires: false);
  }

  static Future<void> deleteToken(String firebaseUid) async {
    String key = _getKey(_Key.token, {'firebaseUid': firebaseUid});
    await _remove(key);
  }

  //---------------------------------
  //  fcm token
  //---------------------------------

  static Future<String> getFCMToken(String firebaseUid) async {
    String key = _getKey(_Key.FCMToken, {'firebaseUid': firebaseUid});
    String token = await _get(key);
    return token;
  }

  static Future<void> setFCMToken(
      String token, String firebaseUid) async {
    String key = _getKey(_Key.FCMToken, {'firebaseUid': firebaseUid});
    await _set(key, token, expires: false);
  }

  static Future<void> deleteFCMToken(String firebaseUid) async {
    String key = _getKey(_Key.FCMToken, {'firebaseUid': firebaseUid});
    await _remove(key);
  }

  //---------------------------------
  //  started
  //---------------------------------

  static Future<void> setHasStarted() async {
    String _key = _getKey(_Key.started);
    await _set(_key, true, expires: false);
  }

  static Future<bool> getHasStarted() async {
    String _key = _getKey(_Key.started);
    bool started = await _get(_key);
    return started ?? false;
  }

  //---------------------------------
  //  register
  //---------------------------------

  static Future<void> setRegisterInformation(
      User firebaseUser,
      String email,
      String userName,
      String nickName,
      ) async {
    String _key = _getKey(_Key.register, {'firebaseUid': firebaseUser.uid});
    print(_key);
    Map<String, String> data =  {
      'email': email,
      'userName': userName,
      'nickName': nickName,
    };
    await _set(_key, jsonEncode(data), storeDuration: Duration(minutes: -1));
  }

  static Future<Map<String, String>> getRegisterInformation(User firebaseUser) async {
    String _key = _getKey(_Key.register, {'firebaseUid': firebaseUser.uid});
    print(_key);
    String encoded = await _get(_key);
    if (encoded == null) {
      return null;
    }
    Map decoded = jsonDecode(encoded);
    return decoded.cast<String, String>();
  }

  static Future<void> deleteRegisterInformation(User firebaseUser) async {
    await _remove(
      _getKey(_Key.register, {'firebaseUid': firebaseUser.uid})
    );
  }

  //---------------------------------
  //  posts
  //---------------------------------

  static Future<void> setPosts(AuthUser user, List<Post> posts, String name) async {
    final String _key = _getKey(_Key.posts, {'userId': user.id.toString() ,'name': name});
    List<String> encodedList = await _get(_key);
    List<Map> _decodedList = encodedList != null
        ? encodedList.map((encoded) => jsonDecode(encoded)).toList().cast<Map>()
        : <Map>[];
    posts.forEach((post) {
      int index = _decodedList.indexWhere((decoded) => decoded['id'] == post.id);
      if (index < 0) {
        _decodedList.add(post.toJson());
      } else {
        _decodedList[index] = post.toJson();
      }
      if (_decodedList.length > 100) {
        _decodedList.removeRange(0, _decodedList.length - 100);
      }
    });
    await _set(
        _key, _decodedList.map((decoded) => jsonEncode(decoded)).toList());
  }

  static Future<List<Post>> getPosts(AuthUser user, String name) async {
    String _key = _getKey(_Key.posts, {'userId': user.id.toString(), 'name': name});
    List<String> encodedPosts = await _get(_key);
    if (encodedPosts != null) {
      if (encodedPosts.length == 0) {
        return [];
      }
      List<Post> posts = encodedPosts.map((d) {
        return Post.fromJson(jsonDecode(d));
      }).toList();
      return Post.sortByCreatedAt(posts);
    } else {
      return [];
    }
  }

  static Future<void> setPost(AuthUser user, Post post, String name) async {
    String _key = _getKey(_Key.posts, {'userId': user.id.toString(), 'name': name});
    List<String> encodedPosts = await _get(_key);
    if (encodedPosts != null) {
      int index = encodedPosts.indexWhere((encoded) {
        Map decoded = jsonDecode(encoded);
        return decoded['id'] == null ? false : decoded['id'];
      });
      if (index < 0) {
        encodedPosts.add(jsonEncode(post.toJson()));
      } else {
        encodedPosts[index] = jsonEncode(post.toJson());
      }
      await _set(_key, encodedPosts);
    } else {
      await _set(_key, [jsonEncode(post.toJson())]);
    }
  }

  static Future<void> updatePost(AuthUser user, Post post, String name) async {
    String key = _getKey(_Key.posts, {'userId': user.id.toString(), 'name': name});
    List<String> encodedPosts = await _get(key);
    if (encodedPosts != null) {
      int index = encodedPosts.indexWhere((encoded){
        return jsonDecode(encoded)['id'] == post.id;
      });
      if (!(index < 0)) {
        encodedPosts[index] = jsonEncode(post.toJson());
        await _set(key, encodedPosts);
      }
    }
  }

  static Future<void> deletePosts(AuthUser user, String name) async {
    String key = _getKey(_Key.posts, {'userId': user.id.toString(), 'name': name});
    await _remove(key);
  }

  static Future deletePost(AuthUser user, Post post, String name) async {
    String _key = _getKey(_Key.posts, {'userId': user.id.toString(), 'name': name});
    List<String> encodedPosts = await _get(_key);
    if (encodedPosts != null) {
      int index = encodedPosts.indexWhere((encoded) {
        Map decoded = jsonDecode(encoded);
        return decoded.containsKey('id') ? decoded['id'] == post.id : false;
      });
      if (!(index < 0)) {
        List<String> tempList = List<String>.from(encodedPosts);
        tempList.removeAt(index);
        await _set(_key, tempList);
      }
    }
  }

  //---------------------------------
  //  habit
  //---------------------------------

  static Future<void> setHabit(Habit habit) async {
    String key = _getKey(_Key.habit, {'userId': habit.user.id.toString()});
    String encodedJson = jsonEncode(habit.toJson());
    await _set(key, encodedJson);
  }

  static Future<Habit> getHabit(AuthUser user) async {
    String key = _getKey(_Key.habit, {'userId': user.id.toString()});
    String encodedHabit = await _get(key);
    return encodedHabit != null
        ? Habit.fromJson(jsonDecode(encodedHabit))
        : null;
  }

  static Future<void> deleteHabit(AuthUser user) async {
    String key = _getKey(_Key.habit, {'userId': user.id.toString()});
    _remove(key);
  }

  //---------------------------------
  //  profile
  //---------------------------------

  static Future<List<Post>> getProfilePosts(AuthUser user) async {
    try {
      String key =
          _getKey(_Key.profileTimeLine, {'userId': user.id.toString()});
      List<String> encodedPosts = await _get(key);
      if (encodedPosts != null) {
        return encodedPosts
            .map((encoded) => Post.fromJson(jsonDecode(encoded))).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw (e);
    }
  }

  static Future<void> setProfilePosts(
      AuthUser user, List<Post> posts) async {
    try {
      String key =
          _getKey(_Key.profileTimeLine, {'userId': user.id.toString()});
      await _set(
          key, posts.map((post) => jsonEncode(post.toJson())).toList());
    } catch (e) {
      throw e;
    }
  }

  static Future<void> updateProfilePost(AuthUser user, Post post) async {
    String key =
    _getKey(_Key.profileTimeLine, {'userId': user.id.toString()});
    List<String> _encodedPosts = await _get(key);
    if (_encodedPosts != null) {
      int index = _encodedPosts.indexWhere((_encodedPost) {
        Map decoded = jsonDecode(_encodedPost);
        return decoded['id'] == post.id;
      });
      if (!(index < 0)) {
        _encodedPosts[index] = jsonEncode(post.toJson());
      }
      await _set(key, _encodedPosts);
    }
  }

  static Future<void> deleteProfilePost(AuthUser user, Post post) async {
    String key =
    _getKey(_Key.profileTimeLine, {'userId': user.id.toString()});
    List<String> _encodedPosts = await _get(key);
    if (_encodedPosts != null) {
      int index = _encodedPosts.indexWhere((_encodedPost) {
        Map decoded = jsonDecode(_encodedPost);
        return decoded['id'] == post.id;
      });
      if (!(index < 0)) {
        List<String> tempList = List<String>.from(_encodedPosts);
        tempList.removeAt(index);
        await _set(key, tempList);
      }
    }
  }
  //---------------------------------
  //  notification
  //---------------------------------

  static Future<void> setNotifications(
      List<UserNotification> notifications, AuthUser user) async {
    String key = _getKey(_Key.notifications, {'userId': user.id.toString()});
    List<String> encodedOlderNotifications = await _get(key) ?? <String>[];
    List<UserNotification> olderNotifications = encodedOlderNotifications
        .map((encodedNotification) =>
            UserNotification.fromJson(jsonDecode(encodedNotification)))
        .toList();
    notifications.forEach((notification) {
      int index = olderNotifications.indexWhere((olderNotification) {
        return notification.id == olderNotification.id;
      });
      if (index < 0) {
        olderNotifications.add(notification);
      } else {
        olderNotifications[index] = notification;
      }
    });
    olderNotifications.removeWhere((notification) => notification.expired);
    await _set(
        key,
        olderNotifications
            .map((notification) => jsonEncode(notification.toJson()))
            .toList());
  }

  static Future<List<UserNotification>> getNotifications(AuthUser user) async {
    String key = _getKey(_Key.notifications, {'userId': user.id.toString()});
    List<String> encodedNotifications = await _get(key);
    if (encodedNotifications != null) {
      List<UserNotification> notifications = encodedNotifications
          .map((notificationJson) =>
              UserNotification.fromJson(jsonDecode(notificationJson)))
          .where((notification) => !notification.expired)
          .toList()
            ..sort((UserNotification a, UserNotification b) {
              if (a.createdAt.isBefore(b.createdAt)) {
                return -1;
              } else {
                return 1;
              }
            });
      await _set(
          key,
          notifications
              .map((notification) => jsonEncode(notification.toJson()))
              .toList());
      return notifications;
    } else {
      return null;
    }
  }

  static Future<void> deleteNotifications(AuthUser user) async {
    String key = _getKey(_Key.notifications, {'userId': user.id.toString()});
    await _remove(key);
  }

//  settings

  static Future<Map<String, bool>> getNotificationSetting() async {
    String key =
        _getKey(_Key.notificationSetting, {});
    String allowed = await _get(key);
    if (allowed == null) {
      return null;
    }
    Map<String, dynamic> settings = jsonDecode(allowed);
    return settings.cast<String, bool>();
  }

  static Future<void> setNotificationSetting(Map<String, bool> state) async {
    String key =
    _getKey(_Key.notificationSetting, {});
    await _set(key, jsonEncode(state), storeDuration: Duration(minutes: -1));
  }

  //---------------------------------
  //  recent search
  //---------------------------------

  static Future<void> setRecentSearch(AuthUser user, String text) async {
    String key =
    _getKey(_Key.recentSearch, {'userId': user.id.toString()});
    List<String> remaining = await _get(key) ?? <String>[];
    remaining.remove(text);
    remaining.add(text);
    await _set(key, remaining);
  }

  static Future<List<String>> getRecentSearch(AuthUser user) async {
    String key =
    _getKey(_Key.recentSearch, {'userId': user.id.toString()});
    return await _get(key) ?? <String>[];
  }

  static Future<void> deleteRecentSearch(AuthUser user) async {
    String key =
    _getKey(_Key.recentSearch, {'userId': user.id.toString()});
    await _remove(key);
  }

  //---------------------------------
  //  drafts
  //---------------------------------

  static Future<void> setDraft(AuthUser user, Draft draft) async {
    String key =
    _getKey(_Key.draft, {'userId': user.id.toString()});
    List<String> encodedDrafts = await _get(key);
    if (encodedDrafts != null) {
      int index = encodedDrafts.indexWhere((data) {
        Map<String, dynamic> dataMap = jsonDecode(data);
        return dataMap['id'] == draft.id;
      });
      if (index < 0) {
        encodedDrafts.add(jsonEncode(draft.toJson()));
      } else {
        encodedDrafts[index] = jsonEncode(draft.toJson());
      }
    } else {
      encodedDrafts = <String>[jsonEncode(draft.toJson())];
    }
    await _set(key, encodedDrafts);
  }

  static Future<List<Draft>> getDrafts(AuthUser user) async {
    String key =
    _getKey(_Key.draft, {'userId': user.id.toString()});
    List<String> encodedDrafts = await _get(key);
    List<Draft> drafts = <Draft>[];
    if (encodedDrafts == null) {
      return drafts;
    }
    for (String encodedDraft in encodedDrafts) {
      drafts.add(await Draft.fromJson(jsonDecode(encodedDraft)));
    }
    return drafts;
  }

  static Future<void> removeDraft(AuthUser user, Draft draft) async {
    String key =
    _getKey(_Key.draft, {'userId': user.id.toString()});
    List<String> encodedDrafts = await _get(key);
    if (encodedDrafts != null) {
      encodedDrafts.removeWhere((d) {
        Map<String, dynamic> decoded = jsonDecode(d);
        return decoded['id'] == draft.id;
      });
      await _set(key, encodedDrafts);
    }
  }

  //---------------------------------
  //  analysis language
  //---------------------------------

  static Future<void> setAnalysisVersion(String v) async {
    String key = _getKey(_Key.analysisLanguage);
    await _set(key, v);
  }

  static Future<String> getAnalysisVersion() async {
    String key = _getKey(_Key.analysisLanguage);
    return await _get(key);
  }

  static Future<void> removeAnalysisVersion() async {
    String key = _getKey(_Key.analysisLanguage);
    await _remove(key);

  }
}
