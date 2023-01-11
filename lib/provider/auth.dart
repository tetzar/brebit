import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:brebit/api/auth.dart';
import 'package:brebit/api/habit.dart';
import 'package:brebit/api/profile.dart';
import 'package:brebit/library/cache.dart';
import 'package:brebit/library/messaging.dart';
import 'package:brebit/model/category.dart';
import 'package:brebit/model/habit.dart';
import 'package:brebit/model/partner.dart';
import 'package:brebit/model/post.dart';
import 'package:brebit/model/user.dart';
import 'package:brebit/view/profile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../library/exceptions.dart';

final authProvider = StateNotifierProvider<AuthProvider, AuthProviderState>(
    (ref) => AuthProvider(new AuthProviderState(user: null)));

class AuthProviderState {
  AuthProviderState({this.user});

  AuthUser? user;
}

class AuthProvider extends StateNotifier<AuthProviderState> {
  AuthProvider(AuthProviderState state) : super(state) {
    listening = false;
  }

  late bool listening;

  bool noMoreContent = false;

  AuthUser? get user => state.user;

  void updateState({AuthUser? user}) {
    this.state = AuthProviderState(user: user ?? this.state.user);
  }

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
          AuthUser? user = this.state.user;
          if (user != null) {
            user.addPartner(_partner);
            updateState();
          }
      }
    });
    listening = true;
  }

  //---------------------------------
  //  register
  //---------------------------------

  Future<void> registerWithFirebase(
      String nickName, String userName, User firebaseUser) async {
    AuthUser user = await AuthApi.register(firebaseUser, nickName, userName);
    AuthUser.selfUser = user;
    updateState(user: user);
    await LocalManager.deleteHabit(user);
    await LocalManager.deletePosts(user, nickName);
    await LocalManager.deleteNotifications(user);
    await LocalManager.deleteRecentSearch(user);
  }

  // ---------------------------------------------
  // Log In
  // ---------------------------------------------

  Future<AuthUser> login(String email, String password) async {
    await FirebaseAuth.instance.currentUser?.reload();
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw NotLoggedInException('firebase user is null');
    }
    AuthUser user = await AuthApi.login(firebaseUser);
    AuthUser.selfUser = user;
    updateState(user: user);
    return user;
  }

  Future<AuthUser> loginWithFirebase(User firebaseUser) async {
    AuthUser user = await AuthApi.login(firebaseUser);
    AuthUser.selfUser = user;
    updateState(user: user);
    return user;
  }

  //---------------------------------
  //  user
  //---------------------------------

  Future<AuthUser> getUser() async {
    AuthUser? user = this.state.user;
    if (user != null) {
      return user;
    }
    user = await AuthApi.getUser();
    updateState(user: user);
    return user;
  }

  void setUser(AuthUser user) {
    this.state.user = user;
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
      await FirebaseAuth.instance.currentUser?.delete();
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

  static CredentialProviders? getCredentialProviderFromId(String id) {
    int index = providerIds.values.toList().indexOf(id);
    if (index < 0) {
      return null;
    } else {
      return providerIds.keys.toList()[index];
    }
  }

  static String? getProviderIdFromCredentialProvider(
      CredentialProviders provider) {
    if (providerIds.containsKey(provider)) {
      return providerIds[provider]!;
    }
    return null;
  }

  static List<CredentialProviders> getProviders() {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw NotLoggedInException("firebase current user is null");
    }
    return firebaseUser.providerData
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
    AuthUser? user = state.user;
    if (user == null) return false;
    List<Post> posts = await LocalManager.getProfilePosts(user);
    if (posts.length == 0) {
      List<Post> resultPosts = await ProfileApi.getProfilePosts(user);
      if (resultPosts.length < 10) {
        noMoreContent = true;
      }
      if (resultPosts.length > 0) {
        user.posts = resultPosts;
        state = new AuthProviderState(user: user);
        await LocalManager.setProfilePosts(user, resultPosts);
      }
      return true;
    }
    Post latestPost = posts.first;
    user.posts = posts;
    updateState();
    List<Post> newPosts =
        await ProfileApi.getProfilePosts(user, latestPost.createdAt);
    if (newPosts.length > 0) {
      List<Post> resultPosts = new List.from(newPosts)..addAll(posts);
      user.posts = resultPosts;
      await LocalManager.setProfilePosts(user, resultPosts);
      state = new AuthProviderState(user: state.user);
    }
    if (user.posts.length < 10) reloadOlderTimeLine();
    return true;
  }

  Future<void> reloadTimeLine() async {
    AuthUser? user = state.user;
    if (user != null && user.posts.length > 0) {
      List<Post> newPosts =
          await ProfileApi.getProfilePosts(user, user.posts.first.createdAt);
      newPosts.addAll(user.posts);
      user.posts = newPosts;
      await LocalManager.setProfilePosts(user, newPosts);
      updateState();
      return;
    }
    await this.getProfileTimeline();
  }

  Future<bool> reloadOlderTimeLine() async {
    AuthUser? user = state.user;
    if (user == null) return false;
    if (user.posts.length > 0) {
      List<Post> newPosts = await ProfileApi.getProfilePosts(
          user, user.posts.last.createdAt, true);
      if (newPosts.length == 0) {
        this.noMoreContent = true;
        updateState();
        return true;
      }
      user.posts.addAll(newPosts);
      await LocalManager.setProfilePosts(user, user.posts);
      updateState();
    }
    return false;
  }

  Future<bool> deletePost(Post post) async {
    AuthUser? user = state.user;
    if (user == null) return false;
    Post? _post;
    try {
      _post = user.posts.firstWhere((_post) => _post.id == post.id);
    } on StateError {
      _post = null;
    }
    if (_post != null) {
      bool success = await user.deletePost(post);
      if (success) {
        removePost(post);
        return true;
      }
    }
    return false;
  }

  void removePost(Post post) {
    AuthUser? user = state.user;
    if (user != null) {
      user.removePost(post);
      updateState();
    }
  }

  //---------------------------------
  //  profile
  //---------------------------------

  Future<void> saveName(String newName) async {
    AuthUser user = await ProfileApi.saveProfile(
        {'name': newName, 'custom_id': null, 'bio': null});
    AuthUser? currentUser = state.user;
    if (currentUser == null) return;
    user.postCount = currentUser.postCount;
    state = new AuthProviderState(user: user);
  }

  Future<void> saveProfileImage(File imageFile) async {
    String imageUrl = await ProfileApi.saveProfileImage(imageFile);
    AuthUser? user = state.user;
    if (user == null) return;
    await user.setProfileImageUrl(imageUrl);
    updateState();
  }

  Future<void> saveProfile(
      String nickName, String bio, File? imageFile, bool deleted) async {
    AuthUser user = await ProfileApi.saveProfile({
      'name': nickName,
      'custom_id': null,
      'bio': bio,
      'image_deleted': deleted
    }, imageFile: imageFile);
    updateState(user: user);
  }

  Future<void> reloadProfile() async {
    AuthUser user = await AuthApi.getUser();
    AuthUser? currentUser = state.user;
    if (currentUser == null) return;
    user.posts = currentUser.posts;
    updateState(user: user);
  }

  Future<void> switchOpened(bool toOpen) async {
    AuthUser user = await AuthApi.setOpened(toOpen);
    state = state..user = user;
  }

  //---------------------------------
  //  partner
  //---------------------------------

  void breakOffWithFriend(Partner partner) {
    AuthUser? user = state.user;
    if (user == null) return;
    user.removePartner(partner);
    updateState();
  }

  void setPartner(Partner partner) {
    AuthUser? user = state.user;
    if (user == null) return;
    user.addPartner(partner);
    updateState();
  }

  void removePartner(Partner partner) {
    AuthUser? user = state.user;
    if (user == null) return;
    user.removePartner(partner);
    updateState();
  }

  //---------------------------------
  //  habit
  //---------------------------------

  Future<Habit> suspendHabit(CategoryName categoryName) async {
    Map<String, dynamic> result = await HabitApi.suspend(categoryName);
    AuthUser? user = result['user'];
    if (user != null) {
      this.state = AuthProviderState(user: user);
    }
    return result['habit'];
  }

  Future<Habit> restartHabit(CategoryName categoryName) async {
    Map<String, dynamic> result = await HabitApi.restart(categoryName);
    AuthUser? user = result['user'];
    if (user != null) {
      this.state = AuthProviderState(user: user);
    }
    return result['habit'];
  }

  void start(Category category) {
    AuthUser? user = state.user;
    if (user == null) return;
    user.addActiveHabitCategory(category);
    updateState();
  }

  Future<void> deleteProfileImage() async {
    AuthUser? user = this.user;
    if (user == null) return;
    await user.deleteImage();
    this.state = AuthProviderState(user: this.user);
  }
}

enum CredentialProviders {
  google,
  apple,
  password,
}
