import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:brebit/library/cache.dart';
import 'package:brebit/library/messaging.dart';
import 'package:brebit/model/category.dart';
import 'package:brebit/model/habit.dart';
import 'package:brebit/model/partner.dart';
import 'package:brebit/model/post.dart';
import 'package:brebit/model/user.dart';
import 'package:brebit/network/auth.dart';
import 'package:brebit/network/habit.dart';
import 'package:brebit/network/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authProvider = StateNotifierProvider<AuthProvider*, AuthProviderState*>(
        (ref) => AuthProvider(new AuthProviderState(user: null)));

class AuthProviderState {
  AuthProviderState({this.user});

  AuthUser user;
}

class AuthProvider extends StateNotifier<AuthProviderState> {
  AuthProvider(AuthProviderState state) : super(state) {
    listening = false;
  }

  bool listening;

  bool noMoreContent = false;

  void startNotificationListening() {
    if (listening) {
      return;
    }
    MyFirebaseMessaging.notificationStream.stream
        .listen((receivedNotification) {
      switch (receivedNotification.type) {
        case 'PartnerRequestNotification':
        case 'PartnerAcceptedNotification':
          Partner _partner = Partner.fromJson(
              jsonDecode(receivedNotification.data['partner']));
          if (this.state != null) {
            if (this.state.user != null) {
              this.state.user.addPartner(_partner);
              this.state = state;
            }
          }
      }
    });
    listening = true;
  }

  //---------------------------------
  //  register
  //---------------------------------

  Future<void> registerWithFirebase(String nickName, String userName, User firebaseUser) async {
    AuthUser user = await AuthApi.register(firebaseUser, nickName, userName);
    AuthUser.selfUser = user;
    state = new AuthProviderState(user: user);
    await LocalManager.deleteHabit(user);
    await LocalManager.deletePosts(user, nickName);
    await LocalManager.deleteNotifications(user);
    await LocalManager.deleteRecentSearch(user);
  }

  // ---------------------------------------------
  // Log In
  // ---------------------------------------------

  Future<AuthUser> login(String email, String password) async {
    AuthUser user = await AuthApi.login(FirebaseAuth.instance.currentUser);
    AuthUser.selfUser = user;
    this.state.user = user;
    return user;
  }

  Future<AuthUser> loginWithFirebase(User firebaseUser) async {
    AuthUser user = await AuthApi.login(firebaseUser);
    AuthUser.selfUser = user;
    this.state.user = user;
    return user;
  }

  //---------------------------------
  //  user
  //---------------------------------

  void setUser(AuthUser updatedUser) {
    this.state = new AuthProviderState(user: updatedUser);
  }

  Future<AuthUser> getUser() async {
    if (this.state.user != null) {
      return this.state.user;
    } else {
      AuthUser user = await AuthApi.getUser();
      this.state.user = user;
      return user;
    }
  }

  //---------------------------------
  //  log out
  //---------------------------------

  Future<bool> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      AuthUser.selfUser = null;
      this.state.user = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await AuthApi.deleteAccount();
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      AuthUser.selfUser = null;
      this.state.user = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  //---------------------------------
  //  provider
  //---------------------------------

  static Map<CredentialProviders, String> providerIds =
  <CredentialProviders, String>{
    CredentialProviders.google: 'google.com',
    CredentialProviders.apple: 'apple.com',
    CredentialProviders.password: 'password'
  };

  static CredentialProviders getCredentialProviderFromId(String id) {
    int index = providerIds.values.toList().indexOf(id);
    if (index < 0) {
      return null;
    } else {
      return providerIds.keys.toList()[index];
    }
  }

  static String getProviderIdFromCredentialProvider(
      CredentialProviders provider) {
    if (providerIds.containsKey(provider)) {
      return providerIds[provider];
    }
    return null;
  }

  static List<CredentialProviders> getProviders() {
    return FirebaseAuth.instance.currentUser.providerData
        .map((userInfo) {
          return AuthProvider.getCredentialProviderFromId(userInfo.providerId);
    })
        .toList()
        .cast<CredentialProviders>();
  }

  //---------------------------------
  //  time line
  //---------------------------------

  Future<bool> getProfileTimeline() async {
    try {
      List<Post> posts = await LocalManager.getProfilePosts(state.user);
      if (posts.length == 0) {
        List<Post> resultPosts = await ProfileApi.getProfilePosts(state.user);
        if (resultPosts.length < 10) {
          noMoreContent = true;
        }
        if (resultPosts.length > 0) {
          this.state.user.posts = resultPosts;
          state = new AuthProviderState(user: state.user);
          await LocalManager.setProfilePosts(this.state.user, resultPosts);
        }
        return true;
      } else {
        Post latestPost = posts.first;
        this.state.user.posts = posts;
        state = new AuthProviderState(user: state.user);
        List<Post> newPosts =
        await ProfileApi.getProfilePosts(state.user, latestPost.createdAt);
        if (newPosts.length > 0) {
          List<Post> resultPosts = new List.from(newPosts)
            ..addAll(posts);
          this.state.user.posts = resultPosts;
          await LocalManager.setProfilePosts(this.state.user, resultPosts);
          state = new AuthProviderState(user: state.user);
        }
        if (this.state.user.posts.length < 10) reloadOlderTimeLine();
        return true;
      }
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<void> reloadTimeLine() async {
    if (state.user.posts != null &&
        state.user.posts.length > 0) {
        List<Post> newPosts = await ProfileApi.getProfilePosts(
            state.user, state.user.posts.first.createdAt);
        newPosts.addAll(state.user.posts);
        AuthUser user = state.user;
        user.posts = newPosts;
        await LocalManager.setProfilePosts(this.state.user, newPosts);
        state = new AuthProviderState(user: user);
        return;
    }
    await this.getProfileTimeline();
  }

  Future<bool> reloadOlderTimeLine() async {
    if (state.user.posts != null && state.user.posts.length > 0) {
      List<Post> newPosts = await ProfileApi.getProfilePosts(
          state.user, state.user.posts.last.createdAt, true);
      if (newPosts.length == 0) {
        this.noMoreContent = true;
        state = state;
        return true;
      }
      state.user.posts.addAll(newPosts);
      await LocalManager.setProfilePosts(this.state.user, state.user.posts);
      state = new AuthProviderState(user: state.user);
    }
    return false;
  }

  Future<bool> deletePost(Post post) async {
    Post _post = state.user.posts
        .firstWhere((_post) => _post.id == post.id, orElse: () => null);
    if (_post != null) {
      bool success = await state.user.deletePost(post);
      if (success) {
        removePost(post);
        return true;
      }
    }
    return false;
  }

  void removePost(Post post) {
    if (this.state != null && this.state.user != null) {
      this.state.user.removePost(post);
      state = state;
    }
  }

  //---------------------------------
  //  profile
  //---------------------------------

  Future<void> saveName(String newName) async {
    try {
      AuthUser user = await ProfileApi.saveProfile(
          {'name': newName, 'custom_id': null, 'bio': null});
      user.postCount = state.user.postCount;
      state = new AuthProviderState(user: user);
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Future<void> saveProfileImage(File imageFile) async {
    try {
      String imageUrl = await ProfileApi.saveProfileImage(imageFile);
      if (imageUrl != null) {
        AuthUser user = state.user;
        user.setProfileImageUrl(imageUrl);
        state = new AuthProviderState(user: user);
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> saveProfile(String nickName, String bio, File imageFile,
      bool deleted) async {
    AuthUser user = await ProfileApi.saveProfile({
      'name': nickName,
      'custom_id': null,
      'bio': bio,
      'image_deleted': deleted
    }, imageFile: imageFile);
    this.setUser(user);
  }

  Future<void> switchOpened(bool toOpen) async {
    AuthUser user = await AuthApi.setOpened(toOpen);
    state = state..user = user;
  }

  //---------------------------------
  //  partner
  //---------------------------------

  void breakOffWithFriend(Partner partner) {
    this.state.user.removePartner(partner);
    state = AuthProviderState(user: state.user);
  }

  void setPartner(Partner partner) {
    this.state.user.addPartner(partner);
    state = AuthProviderState(user: state.user);
  }

  void removePartner(Partner partner) {
    this.state.user.removePartner(partner);
    state = AuthProviderState(user: state.user);
  }

  //---------------------------------
  //  habit
  //---------------------------------

  Future<Habit> suspendHabit(CategoryName categoryName) async {
    Map<String, dynamic> result = await HabitApi.suspend(categoryName);
    this.state = state..user = result['user'];
    return result['habit'];
  }

  Future<Habit> restartHabit(CategoryName categoryName) async {
    Map<String, dynamic> result = await HabitApi.restart(categoryName);
    this.state = state..user = result['user'];
    return result['habit'];
  }

  void start(Category category) {
    AuthUser user = this.state.user;
    user.addActiveHabitCategory(category);
    state = state..user = user;
  }
}

enum CredentialProviders {
  google,
  apple,
  password,
}
