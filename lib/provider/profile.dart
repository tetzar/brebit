import 'dart:async';
import 'dart:convert';

import '../../library/cache.dart';
import '../../library/messaging.dart';
import '../../model/post.dart';
import '../../model/habit.dart';
import '../../model/habit_log.dart';
import '../../model/partner.dart';
import '../../model/user.dart';
import '../../api/partner.dart';
import '../../api/profile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Map<int, StreamController<FcmNotification>> _notificationStreamControllers
 = {};

var profileProvider =
    StateNotifierProvider.family<ProfileProvider, ProfileProviderState, int>((ref, id) {
  _notificationStreamControllers[id] = MyFirebaseMessaging.notificationStream;
  ref.onDispose(() {
    _notificationStreamControllers[id]?.close();
  });
  return ProfileProvider(new ProfileProviderState(), id);
});

class ProfileProviderState {
  late AuthUser user;
  late List<HabitLog> logs;
  late Habit habit;

  ProfileProviderState();

  ProfileProviderState copyWith(
      {AuthUser? user, List<HabitLog>? logs, Habit? habit}) {
    ProfileProviderState newState = ProfileProviderState();
    newState.user = user ?? this.user;
    newState.logs = logs ?? this.logs;
    newState.habit = habit ?? this.habit;
    return newState;
  }
}

class ProfileProvider extends StateNotifier<ProfileProviderState> {
  final int userId;

  ProfileProvider(ProfileProviderState state, this.userId) : super(state) {
    _notificationStreamControllers[this.userId]
        ?.stream
        .listen((receivedNotification) async {
      if (['PartnerRequestNotification', 'PartnerAcceptedNotification']
          .contains(receivedNotification.data['type'])) {
        Partner _partner =
            Partner.fromJson(jsonDecode(receivedNotification.data['partner']));
        if (_partner.user.id == this.userId) {
          await this.getPartners();
        }
      }
    });
  }

  bool noMoreContent = false;

  bool get noMoreLog {
    HabitLog _log = state.habit.logSort().first;
    HabitLog _latestLog = HabitLog.sortByCreatedAt(state.logs).first;
    if (_log.createdAt.isAfter(_latestLog.createdAt)) {
      return true;
    }
    return false;
  }

  get habit => state.habit;

  List<HabitLog> get logs => state.logs;

  void setUser(AuthUser user) {
    state.user = user;
  }

  AuthUser get user => state.user;

  // --------------------------------
  // users profile posts
  // --------------------------------

  Future<bool> getProfilePosts() async {
    try {
      List<Post> posts = await LocalManager.getProfilePosts(state.user);
      if (posts.length == 0) {
        List<Post> resultPosts = await ProfileApi.getProfilePosts(state.user);
        if (resultPosts.length > 0) {
          this.state.user.posts = resultPosts;
          state = state.copyWith(user: state.user);
          await LocalManager.setProfilePosts(this.state.user, resultPosts);
        }
        return true;
      } else {
        Post latestPost = posts.first;
        state = state.copyWith(user: state.user..posts = posts);
        List<Post> newPosts =
            await ProfileApi.getProfilePosts(state.user, latestPost.createdAt);
        if (newPosts.length > 0) {
          List<Post> resultPosts = new List.from(newPosts)..addAll(posts);
          this.state.user.posts = resultPosts;
          await LocalManager.setProfilePosts(this.state.user, resultPosts);
          state = state.copyWith(user: state.user);
        }
        return true;
      }
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<void> reloadTimeLine() async {
    if (state.user.posts.length > 0) {
      List<Post> newPosts = await ProfileApi.getProfilePosts(
          state.user, state.user.posts.first.createdAt);
      newPosts.addAll(state.user.posts);
      AuthUser user = state.user;
      user.posts = newPosts;
      await LocalManager.setProfilePosts(this.state.user, newPosts);
      state = state.copyWith(user: user);
      return;
    }
    await this.getProfilePosts();
  }

  Future<bool> reloadOlderTimeLine() async {
    if (state.user.posts.length > 0) {
      List<Post> newPosts = await ProfileApi.getProfilePosts(
          state.user, state.user.posts.last.createdAt, true);
      if (newPosts.length == 0) {
        this.noMoreContent = true;
        return true;
      }
      state.user.posts.addAll(newPosts);
      await LocalManager.setProfilePosts(this.state.user, state.user.posts);
      state = state.copyWith(user: state.user);
    }
    return false;
  }

  void removePost(Post post) {
    this.state.user.removePost(post);
    state = state;
  }

  // --------------------------------
  // users partners
  // --------------------------------

  Future<bool> getPartners() async {
    List<Partner> partners = await PartnerApi.getPartners(state.user);
    state.user.partners = partners;
    this.state = state.copyWith(user: state.user);
    return true;
  }

  void setPartner(Partner partner) {
    state.user.addPartner(partner);
    this.state = state.copyWith(user: state.user);
  }

  void removePartner(AuthUser user) {
    Partner? partner = state.user.getPartner(user);
    if (partner == null) return;
    state.user.removePartner(partner);
    this.state = state.copyWith(user: state.user);
  }

  Future<Partner> getProfile() async {
    Map<String, dynamic> result = await ProfileApi.getProfile(state.user);
    AuthUser _user = state.user;
    _user.partners = result['partners'];
    _user.posts = result['posts'];
    if (result['posts'].length < 10) noMoreContent = true;
    state = state.copyWith(
        user: _user, habit: result['habit'], logs: result['logs']);
    return result['partner'];
  }

  Future<void> getLogs(DateTime time) async {
    List<HabitLog> _monthlyLogs =
        await ProfileApi.getLogsInAMonth(state.habit, state.habit.createdAt);
    List<HabitLog> _logs = state.logs;
    _monthlyLogs.forEach((log) {
      int index = _logs.indexWhere((existingLog) => existingLog.id == log.id);
      if (index < 0) {
        _logs.add(log);
      } else {
        _logs[index] = log;
      }
    });
    state = state.copyWith(logs: _logs);
  }
}
