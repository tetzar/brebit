import 'dart:convert';

import '../../library/cache.dart';
import '../../model/post.dart';
import '../../model/partner.dart';
import '../../model/user.dart';
import 'api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthApi {
  static final Map<String, String> postRoutes = {
    'register': '/register',
    'login': '/login',
    'refreshToken': '/token/refresh',
    'setFCMToken': '/auth/fcm-token',
    'setOpened': '/auth/opened',
  };

  static final Map<String, String> getRoutes = {
    'getUser': '/auth/get-user',
    'getEmail': '/auth/get-email/{userName}',
  };

  static final Map<String, String> deleteRoutes = {
    'deletePost': '/auth/post/delete/{postId}',
    'deleteAccount': '/auth/account/delete',
  };

  static Future<AuthUser> register(User firebaseUser, String nickName, String userName) async {
    Map<String, dynamic> data = {
      "firebaseToken": await firebaseUser.getIdToken(),
      "name": nickName,
      'user-name': userName,
    };
    final http.Response response = await Network.postWithoutToken(
      data,
      postRoutes['register'],
    );
    Network.hasErrorMessage(response, 'register@AuthApi');
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    Map<String, dynamic> responseData = jsonDecode(response.body);
    String token = responseData['access_token'];
    DateTime expireAt = DateTime.parse(responseData['expires_at']);
    await LocalManager.setToken(token, expireAt, firebaseUser.uid);
    AuthUser user = AuthUser.fromJson(responseData['user']);
    List<Partner> partners = PartnerFromJson(responseData['partners']);
    user.setPartners(partners);
    return user;
  }

  static Future<AuthUser> login(User firebaseUser) async {
    String token = await firebaseUser.getIdToken();
    Map<String, dynamic> data = {'firebaseToken': token};
    final http.Response response =
        await Network.postWithoutToken(data, postRoutes['login']);
    Network.hasErrorMessage(response, 'login@AuthApi');
    Map body = jsonDecode(response.body);
    token = body['access_token'];
    DateTime expireAt = DateTime.parse(body['expires_at']);
    await LocalManager.setToken(token, expireAt, firebaseUser.uid);
    AuthUser user = AuthUser.fromJson(body['user']);
    List<Partner> partners = PartnerFromJson(body['partners']);
    user.setPartners(partners);
    return user;
  }

  static Future<String> getEmailAddress(String userName) async {
    Map<String, String> data = {
      'userName': userName
    };
    http.Response response = await Network.getWithoutToken(
      Network.routeNormalize(
        getRoutes['getEmail'],
        data
      )
    );
    Network.hasErrorMessage(response, 'getEmailAddress@AuthApi');
    return jsonDecode(response.body)['email'];
  }

  static Future<void> deleteAccount() async {
    http.Response response =
        await Network.deleteData(deleteRoutes['deleteAccount']);
    Network.hasErrorMessage(response, 'deleteAccount@AuthApi');
  }

  static Future<String> refreshToken(User firebaseUser) async {
    String firebaseToken = await firebaseUser.getIdToken();
    Map<String, dynamic> data = {'firebaseToken': firebaseToken};
    final http.Response response =
        await Network.postWithoutToken(data, postRoutes['refreshToken']);
    Network.hasErrorMessage(response, 'refreshToken@AuthApi');
    Map<String, dynamic> body = jsonDecode(response.body);
    DateTime expiresAt = DateTime.parse(body['expires_at']);
    String token = body['access_token'];
    LocalManager.setToken(token, expiresAt, firebaseUser.uid);
    return token;
  }

  static Future<AuthUser> getUser() async {
    final http.Response response = await Network.getData(getRoutes['getUser']);
    Map<String, dynamic> data = jsonDecode(response.body);
    Network.hasErrorMessage(response, 'getUser@AuthApi');
    AuthUser user = AuthUser.fromJson(data['user']);
    List<Partner> partners = PartnerFromJson(data['partners']);
    user.setPartners(partners);
    return user;
  }

  static Future<void> setFCMToken(String token) async {
    Map<String, dynamic> data = {
      'token': token,
    };
    final http.Response response =
        await Network.postData(data, postRoutes['setFCMToken']);
    Network.hasErrorMessage(response, 'setFCMToken@AuthApi');
  }

  static Future<int> deletePost(Post post) async {
    Map<String, String> data = {'postId': post.id.toString()};
    http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['deletePost'], data));
    Network.hasErrorMessage(response, 'deletePost@AuthApi');
    return jsonDecode(response.body)['post_count'];
  }

  static Future<AuthUser> setOpened(bool toOpen) async {
    Map<String, dynamic> data = {
      'open' : toOpen
    };
    http.Response response = await Network.postData(
        data,
        postRoutes['setOpened']
    );
    Network.hasErrorMessage(response, 'setOpened@AuthApi');
    return AuthUser.fromJson(jsonDecode(response.body)['user']);
  }
}
