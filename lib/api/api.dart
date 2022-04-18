import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../library/cache.dart';
import '../../library/exceptions.dart';
import '../../model/user.dart';
import 'auth.dart';

class Network {
  // for emulator (Android)
  static final String _url = 'http://10.0.2.2:80';

  static const int TIME_OUT_SECONDS = 30;

  // for emulator (iOS)
  // static final String _url = 'http://localhost:80';
  // マイハウス
  // static final String _url = 'http://192.168.3.40:80';
  // イマジナリーハウス
  // static final String _url = 'http://192.168.247.216:4655';

  static String get url => _url;

  //if you are using android studio emulator, change localhost to 10.0.2.2
  static var token;

  static String getFullUrl(String apiUrl) {
    return _url + '/api' + apiUrl;
  }

  static _getToken() async {
    String tkn = await LocalManager.getToken(AuthUser.getSelfUid());
    if (tkn != null) {
      if (tkn != 'expired' && tkn.length != 0) {
        token = tkn;
        return tkn;
      }
    }
    tkn = await AuthApi.refreshToken(AuthUser.getSelfUser());
    token = tkn;
    return token;
  }

  static postWithoutToken(data, apiUrl) async {
    String fullUrl = _url + '/api' + apiUrl;
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);
    return await http.post(url,
        body: jsonEncode(data), headers: _setHeadersWithoutToken()).timeout(
        Duration(seconds: TIME_OUT_SECONDS)
    );
  }

  static postData(data, apiUrl) async {
    var fullUrl = _url + '/api' + apiUrl;
    await _getToken();
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);
    return await http.post(url, body: jsonEncode(data), headers: _setHeaders()).timeout(
      Duration(seconds: TIME_OUT_SECONDS)
    );
  }

  static postDataWithImage(
      Map<String, String> data, List<File> imageList, apiUrl) async {
    String uploadURL = Network.getFullUrl(apiUrl);
    print(uploadURL);

    var uri = Uri.parse(uploadURL);

    var request = new http.MultipartRequest("POST", uri);

    await _getToken();

    if (imageList != null) {
      if (imageList.length > 0) {
        imageList.forEach((file) async {
          var stream = file.readAsBytes().asStream();
          var length = file.lengthSync();

          var multipartFile = new http.MultipartFile('file[]', stream, length,
              filename: 'image.jpg', contentType: MediaType('image', 'jpeg'));

          request.files.add(multipartFile);
        });
      }
    }
    data.forEach((key, value) {
      request.fields[key] = value;
    });
    request.headers.addAll(_setHeadersMulti());

    http.Response response =
        await http.Response.fromStream(await request.send());
    return response;
  }

  static getData(apiUrl) async {
    var fullUrl = _url + '/api' + apiUrl;
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);
    await _getToken();
    return await http.get(url, headers: _setHeaders());
  }

  static getWithoutToken(apiUrl) async {
    String fullUrl = _url + '/api' + apiUrl;
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);
    return await http.get(url, headers: _setHeadersWithoutToken());
  }

  static deleteData(apiUrl) async {
    var fullUrl = _url + '/api' + apiUrl;
    Uri url = Uri.parse(fullUrl);
    print(fullUrl);
    await _getToken();

    return await http.delete(url, headers: _setHeaders());
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
    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw InvalidUrlException(response.body, causedAt);
      }
      if (response.statusCode == 201 || response.statusCode == 409) {
        return;
      }
      print(response.body);
      throw UnExpectedException(response.body, causedAt, response.statusCode);
    }
    Map<String, dynamic> body = jsonDecode(response.body);
    if (body.containsKey('message')) {
      if (body.containsKey('exception_code')) {
        switch (body['exception_code']) {
          case 'record-not-found':
            throw RecordNotFoundException(body['message']);
            break;
          case 'unauthorized':
            throw UnauthorizedException(body['message']);
            break;
          case 'user-not-found':
            throw UserNotFoundException(body['message']);
            break;
          case 'invalid-token':
            throw InvalidTokenException(body['message']);
            break;
          case 'create-record-failed':
            throw CreateRecordFailedException(body['message']);
            break;
          case 'firebase-not-found':
            throw FirebaseNotFoundException(body['message']);
            break;
          case 'access-denied':
            throw AccessDeniedException(body['message']);
            break;
        }
      }
    }
  }
}
