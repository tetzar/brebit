import 'dart:async';
import 'dart:core';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../api/notification.dart';
import '../../library/cache.dart';
import '../../library/messaging.dart';
import '../../model/notification.dart';
import '../../model/user.dart';

late StreamController<FcmNotification> _notificationStreamController;

final notificationProvider =
    StateNotifierProvider<NotificationProvider, NotificationProviderState>(
        (ref) {
  _notificationStreamController = MyFirebaseMessaging.notificationStream;
  ref.onDispose(() {
    _notificationStreamController.close();
  });
  return NotificationProvider(
      new NotificationProviderState(notifications: <UserNotification>[]));
});

class NotificationProviderState {
  List<UserNotification> notifications;

  NotificationProviderState({required this.notifications});

  NotificationProviderState copy() {
    return new NotificationProviderState(notifications: this.notifications);
  }
}

class NotificationProvider extends StateNotifier<NotificationProviderState> {
  int? _unreadCount;

  DateTime? _lastReloaded;

  int get unreadCount {
    return _unreadCount ?? this.getUnreadNotifications();
  }

  List<UserNotification> get notifications => [...state.notifications];

  set unreadCount(int count) {
    _unreadCount = count;
  }

  NotificationProvider(NotificationProviderState state) : super(state) {
    _notificationStreamController.stream.listen((receivedNotification) {
      this._unreadCount = receivedNotification.getNotificationCount();
      this._lastReloaded = null;
      AuthUser? selfUser = AuthUser.selfUser;
      if (selfUser != null) this.refreshNotification(selfUser);
      int? _unreadCount = this._unreadCount;
      if (_unreadCount != null && _unreadCount > 0) {
        this.state = this.state.copy();
      }
    });
  }

  void setUserNotification(List<UserNotification> receivedUserNotifications) {
    List<UserNotification> notifications;
    notifications = state.notifications;
    if (receivedUserNotifications.length > 0) {
      notifications.addAll(receivedUserNotifications);
      this.state = new NotificationProviderState(notifications: notifications);
    }
  }

  Future<void> getNotifications(AuthUser user) async {
    List<UserNotification>? currentNotifications =
        await LocalManager.getNotifications(user);
    List<UserNotification>? notifications;
    DateTime? createdAt;
    if (currentNotifications != null) {
      if (currentNotifications.length > 0) {
        createdAt = currentNotifications.last.createdAt;
      }
    } else {
      currentNotifications = <UserNotification>[];
    }
    if (currentNotifications.length > 0) {
      DateTime? _lastReloaded = this._lastReloaded;
      if (_lastReloaded == null
          ? true
          : _lastReloaded
              .isBefore(DateTime.now().subtract(Duration(minutes: 10)))) {
        notifications = await NotificationApi.getUnreadNotifications();
        _lastReloaded = DateTime.now();
      }
    } else {
      notifications = await NotificationApi.getNotifications(createdAt);
      _lastReloaded = DateTime.now();
    }
    if (notifications == null) return;
    for (UserNotification _notification in notifications) {
      int index = currentNotifications
          .indexWhere((_current) => _notification.id == _current.id);
      if (index < 0) {
        currentNotifications.add(_notification);
      } else {
        currentNotifications[index] = _notification;
      }
    }
    currentNotifications
      ..sort((UserNotification a, UserNotification b) {
        if (a.createdAt.isBefore(b.createdAt)) {
          return 1;
        } else {
          return -1;
        }
      });
    state = new NotificationProviderState(notifications: currentNotifications);
    await LocalManager.setNotifications(currentNotifications, user);
  }

  Future<void> refreshNotification(AuthUser user) async {
    List<UserNotification> currentNotifications = state.notifications;
    List<UserNotification> notifications = <UserNotification>[];
    DateTime? _lastReloaded = this._lastReloaded;
    if (_lastReloaded == null
        ? true
        : _lastReloaded
            .isBefore(DateTime.now().subtract(Duration(minutes: 10)))) {
      notifications = await NotificationApi.getUnreadNotifications();
      _lastReloaded = DateTime.now();
    }
    notifications.forEach((_notification) {
      int index = currentNotifications.indexWhere((_currentNotification) =>
          _currentNotification.id == _notification.id);
      if (index < 0) {
        currentNotifications.add(_notification);
      } else {
        currentNotifications[index] = _notification;
      }
    });
    state = new NotificationProviderState(notifications: currentNotifications);
    await LocalManager.setNotifications(currentNotifications, user);
  }

  Future<void> markAsReadAll() async {
    if (this.state.notifications.length == 0) return;
    List<UserNotification> _notifications = state.notifications
        .where((_notification) => _notification.readAt == null)
        .toList();
    _notifications = UserNotification.sortByCreatedAt(_notifications);
    if (_notifications.length > 0) {
      List<UserNotification> _readNotifications =
          await NotificationApi.markAsRead(_notifications);
      for (UserNotification _notification in _readNotifications) {
        int index = state.notifications.indexWhere((_currentNotification) =>
            _currentNotification.id == _notification.id);
        if (index >= 0) {
          state.notifications[index] = _notification;
        }
      }
      state = this.state.copy();
      AuthUser? selfUser = AuthUser.selfUser;
      if (selfUser != null) {
        await LocalManager.setNotifications(state.notifications, selfUser);
      }
    }
    this._unreadCount = 0;
  }

  Future<void> deleteNotification(UserNotification deleteNotification) async {
    await NotificationApi.deleteNotification(deleteNotification.id);
    state.notifications.removeWhere(
        (notification) => notification.id == deleteNotification.id);
    state = new NotificationProviderState(notifications: state.notifications);
  }

  int getUnreadNotifications() {
    int unreadCount = 0;
    for (UserNotification notification in this.state.notifications) {
      if (!notification.hasRead()) {
        unreadCount++;
      }
    }
    return unreadCount;
  }

  bool updateRequired() {
    return this._unreadCount != getUnreadNotifications();
  }
}
