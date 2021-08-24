import 'dart:convert';
import 'dart:io';

import '../../model/comment.dart';
import '../../model/post.dart';
import '../../model/habit_log.dart';
import '../../model/user.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class PostApi {
  static final Map<String, String> postRoutes = {
    'savePost': '/post/save',
    'addCommentToPost': '/post/add-comment',
    'likeToPost': '/post/like',
    'likeToComment': '/comment/like',
    'report': '/report',
  };

  static final Map<String, String> getRoutes = {
    'getTimeLine': '/timeline/{userId}/{condition}',
    'getPost': '/post/get/{postId}',
    'reloadTimeLine': '/timeline/reload/later/{userId}/{dateTime}/{condition}',
    'reloadTimeLineOlder': '/timeline/reload/older/{userId}/{dateTime}/{condition}',
  };

  static final Map<String, String> deleteRoutes = {
    'deleteComment': '/comment/delete/{commentId}',
    'unlikeFromComment': '/comment/unlike/{commentId}',
    'unlikeFromPost': '/post/unlike/{postId}',
    'deletePost': '/post/delete/{postId}',
  };

  static Future<String> getTimeLine(AuthUser user,
      [String condition, DateTime t, bool older = false]) async {
    String route;
    if (t == null) {
      route = Network.routeNormalize(getRoutes['getTimeLine'], {
        'userId': user.id.toString(),
        'condition': condition == null ? '_' : condition,
      });
    } else if (older) {
      route = Network.routeNormalize(getRoutes['reloadTimeLineOlder'], {
        'userId': user.id.toString(),
        'dateTime': t.toString(),
        'condition': condition == null ? '_' : condition,
      });
    } else {
      route = Network.routeNormalize(getRoutes['reloadTimeLine'], {
        'userId': user.id.toString(),
        'dateTime': t.toString(),
        'condition': condition == null ? '_' : condition,
      });
    }

    final http.Response response = await Network.getData(route);
    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 404) {
      return jsonEncode({'error': 'user not found'});
    } else {
      print(response.body);
      throw Exception('get timeline error');
    }
  }

  static Future<bool> deletePost(Post post) async {
    Map<String, String> data = {'postId': post.id.toString()};
    final http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['deletePost'], data));
    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      print(response.body);
      return false;
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in PostApi@deletePost');
    }
  }

  static Future<Post> savePost(String inputText, List<File> images, [HabitLog log]) async {

    Map<String, String> data = {
      'text': inputText,
    };
    if (log != null) {
      data['habit_log'] = log.id.toString();
    }
    try {
      http.Response response =
          await Network.postDataWithImage(data, images, postRoutes['savePost']);
      if (response.statusCode == 201) {
        return Post.fromJson(jsonDecode(response.body));
      } else {
        print(response.body);
        throw Exception('unexpected error occurred in PostApi@savePost');
      }
    } catch (e) {
      throw e;
    }
  }

  static Future<Post> getPost(int postId) async {
    Map<String, String> data = {
      'postId': postId.toString()
    };
    http.Response response = await Network.getData(
      Network.routeNormalize(
        getRoutes['getPost'],
        data
      )
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(response.body);
      if (body.containsKey('message')) {
        print(body['message']);
        return null;
      }
      return Post.fromJson(body['post']);
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in getPost@PostApi');
    }

  }

  static Future<Post> addCommentToPost(int postId, String commentBody) async {
    Map<String, dynamic> data = {
      'postId': postId,
      'commentBody': commentBody,
    };
    final http.Response response = await Network.postData(
      data,
      postRoutes["addCommentToPost"],
    );
    if (response.statusCode == 201) {
      Map<String, dynamic> json = jsonDecode(response.body);
      Post post = Post.fromJson(json);
      return post;
    } else if (response.statusCode == 404) {
      Map<String, dynamic> json = jsonDecode(response.body);
      print(json['message']);
      return null;
    } else {
      print(response.body);
      throw Exception('Error occurred in route/PostApi@addCommentToPost');
    }
  }

  static Future<bool> deleteComment(int commentId) async {
    Map<String, String> data = {'commentId': commentId.toString()};
    final http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['deleteComment'], data));
    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      print(response.body);
      return false;
    } else if (response.statusCode == 409) {
      print('comment has been deleted');
      return false;
    } else {
      print('response statusCode : ' + response.statusCode.toString());
      print(response.body);
      throw Exception('unexpected error occurred in PostApi@deleteComment');
    }
  }

  static Future<int> likeToComment(int commentId) async {
    Map<String, dynamic> data = {
      'comment_id': commentId,
    };
    final http.Response response =
        await Network.postData(data, postRoutes['likeToComment']);
    if (response.statusCode == 201) {
      return jsonDecode(response.body)['favorite_count'];
    } else if (response.statusCode == 404) {
      print(jsonDecode(response.body)['message']);
      return null;
    } else if (response.statusCode == 409) {
      print('already liked');
      return jsonDecode(response.body)['favorite_count'];
    } else {
      print(response.body);
      throw Exception('error occurred in PostApi@likeToComment');
    }
  }

  static Future<int> unlikeFromComment(int commentId) async {
    Map<String, String> data = {
      'commentId': commentId.toString(),
    };
    final http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['unlikeFromComment'], data));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['favorite_count'];
    } else if (response.statusCode == 404) {
      print(jsonDecode(response.body)['message']);
      return null;
    } else if (response.statusCode == 409) {
      print('already unLiked');
      return null;
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in PostApi@unlikeFromComment');
    }
  }

  static Future<int> likeToPost(int postId) async {
    Map<String, dynamic> data = {
      'post_id': postId,
    };
    final http.Response response =
        await Network.postData(data, postRoutes['likeToPost']);
    if (response.statusCode == 201) {
      Map<String, dynamic> json = jsonDecode(response.body);
      return json['favorite_count'];
    } else if (response.statusCode == 404) {
      print(jsonDecode(response.body)['message']);
      return null;
    } else if (response.statusCode == 409) {
      print('already liked');
      return null;
    } else {
      print(response.body);
      throw Exception('error occurred in PostApi@likeToPost');
    }
  }

  static Future<int> unlikeFromPost(int postId) async {
    Map<String, String> data = {
      'postId': postId.toString(),
    };
    final http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['unlikeFromPost'], data));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['favorite_count'];
    } else if (response.statusCode == 404) {
      print(jsonDecode(response.body)['message']);
      return null;
    } else if (response.statusCode == 409) {
      print('already unLiked');
      return null;
    } else {
      print(response.body);
      throw Exception('unexpected error occurred in PostApi@unlikeFromPost');
    }
  }

  static Future<void> report(dynamic reportable, String body) async {
    String reportableType;
    if (reportable is Post) {
      reportableType = 'Post';
    } else if (reportable is Comment) {
      reportableType = 'Comment';
    } else {
      return;
    }
    Map<String, dynamic> data = {
      'reportable_type': reportableType,
        'reportable_id' : reportable.id,
        'body': body
,    };
    http.Response response = await Network.postData(
        data,
        postRoutes['report']
    );
    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('unexpected error occurred in PostApi@report');
    }
  }
}
