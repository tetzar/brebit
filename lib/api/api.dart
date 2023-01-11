import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../library/cache.dart';
import '../../library/exceptions.dart';
import '../../model/user.dart';
import 'auth.dart';

class Network {
  static final String _url =
      'https://brebit.lsv.jp/brebit-server-backend/public';

  // for emulator (Android)
  // static final String _url = 'http://10.0.2.2:80';
  // for emulator (iOS)
  // static final String _url = 'http://localhost:80';
  // マイハウス
  // static final String _url = 'http://192.168.3.40:80';
  // イマジナリーハウス
  // static final String _url = 'http://192.168.247.216:4655';

  static String get url => _url;

  static const int TIME_OUT_SECONDS = 30;

  //if you are using android studio emulator, change localhost to 10.0.2.2
  static var token;

  static String getFullUrl(String apiUrl) {
    return _url + '/api' + apiUrl;
  }

  static Future<String?> _getToken() async {
    String? uid = AuthUser.getSelfUid();
    if (uid == null) {
      return null;
    }
    String? tkn = await LocalManager.getToken(uid);
    if (tkn != 'expired' && tkn.length != 0) {
      token = tkn;
      return tkn;
    }
    User? firebaseUser = AuthUser.getSelfUser();
    if (firebaseUser == null) {
      return null;
    }
    tkn = await AuthApi.refreshToken(firebaseUser);
    token = tkn;
    return token;
  }

  static Future<http.Response> postWithoutToken(
      data, apiUrl, String calledAt) async {
    String fullUrl = _url + '/api' + apiUrl;
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);

    http.Response response = await http
        .post(url, body: jsonEncode(data), headers: _setHeadersWithoutToken())
        .timeout(Duration(seconds: TIME_OUT_SECONDS));
    hasErrorMessage(response, calledAt);
    return response;
  }

  static Future<http.Response> postData(data, apiUrl, String calledAt) async {
    var fullUrl = _url + '/api' + apiUrl;
    await _getToken();
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);

    http.Response response = await http
        .post(url, body: jsonEncode(data), headers: _setHeaders())
        .timeout(Duration(seconds: TIME_OUT_SECONDS));
    hasErrorMessage(response, calledAt);
    return response;
  }

  static Future<http.Response> postDataWithImage(Map<String, String> data,
      List<File> imageList, apiUrl, String calledAt) async {
    String uploadURL = Network.getFullUrl(apiUrl);
    print(uploadURL);

    var uri = Uri.parse(uploadURL);

    var request = new http.MultipartRequest("POST", uri);

    await _getToken();

    if (imageList.length > 0) {
      imageList.forEach((file) async {
        var stream = file.readAsBytes().asStream();
        var length = file.lengthSync();

        var multipartFile = new http.MultipartFile('file[]', stream, length,
            filename: 'image.jpg', contentType: MediaType('image', 'jpeg'));

        request.files.add(multipartFile);
      });
    }
    data.forEach((key, value) {
      request.fields[key] = value;
    });
    request.headers.addAll(_setHeadersMulti());

    http.Response response =
        await http.Response.fromStream(await request.send());
    hasErrorMessage(response, calledAt);
    return response;
  }

  static Future<http.Response> getData(apiUrl, String calledAt) async {
    var fullUrl = _url + '/api' + apiUrl;
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);
    await _getToken();
    http.Response response = await http.get(url, headers: _setHeaders());
    hasErrorMessage(response, calledAt);
    return response;
  }

  static Future<http.Response> getWithoutToken(apiUrl, String calledAt) async {
    String fullUrl = _url + '/api' + apiUrl;
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);
    http.Response response =
        await http.get(url, headers: _setHeadersWithoutToken());
    hasErrorMessage(response, calledAt);
    return response;
  }

  static Future<http.Response> deleteData(apiUrl, String calledAt) async {
    var fullUrl = _url + '/api' + apiUrl;
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);
    await _getToken();
    http.Response response = await http.delete(url, headers: _setHeaders());
    hasErrorMessage(response, calledAt);
    return response;
  }

  static _setHeadersWithoutToken() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

  static _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };

  static _setHeadersMulti() => {
        'Content-type': "multipart/form-data",
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  static String routeNormalize(String apiUrl, Map<String, String> data) {
    data.forEach((key, value) {
      apiUrl = apiUrl.replaceAll('{$key}', value);
    });
    return apiUrl;
  }

  static String routeNormalizeDelete(String apiUrl, Map<String, String> data) {
    data.forEach((key, value) {
      apiUrl = apiUrl.replaceAll('{$key}', value);
    });
    return apiUrl;
  }

  static void hasErrorMessage(http.Response response, String causedAt) {
    developer.log(response.body);
    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw InvalidUrlException(response.body, causedAt);
      }
      if (response.statusCode == 201 || response.statusCode == 409) {
        return;
      }
      throw UnExpectedException(response.body, causedAt, response.statusCode);
    }
    dynamic body = jsonDecode(response.body);
    if (body is Map && body.containsKey('message')) {
      if (body.containsKey('exception_code')) {
        developer.log(response.body);
        switch (body['exception_code']) {
          case 'record-not-found':
            throw RecordNotFoundException(body['message']);
          case 'unauthorized':
            throw UnauthorizedException(body['message']);
          case 'user-not-found':
            throw UserNotFoundException(body['message']);
          case 'invalid-token':
            throw InvalidTokenException(body['message']);
          case 'create-record-failed':
            throw CreateRecordFailedException(body['message']);
          case 'firebase-not-found':
            throw FirebaseNotFoundException(body['message']);
          case 'access-denied':
            throw AccessDeniedException(body['message']);
        }
      }
    }
  }
}
