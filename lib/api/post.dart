import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../model/comment.dart';
import '../../model/habit_log.dart';
import '../../model/post.dart';
import '../../model/user.dart';
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
    'reloadTimeLineOlder':
        '/timeline/reload/older/{userId}/{dateTime}/{condition}',
  };

  static final Map<String, String> deleteRoutes = {
    'deleteComment': '/comment/delete/{commentId}',
    'unlikeFromComment': '/comment/unlike/{commentId}',
    'unlikeFromPost': '/post/unlike/{postId}',
    'deletePost': '/post/delete/{postId}',
  };

  static Future<String> getTimeLine(AuthUser user,
      [String? condition, DateTime? t, bool older = false]) async {
    String route;
    if (t == null) {
      route = Network.routeNormalize(getRoutes['getTimeLine']!, {
        'userId': user.id.toString(),
        'condition': condition == null ? '_' : condition,
      });
    } else if (older) {
      route = Network.routeNormalize(getRoutes['reloadTimeLineOlder']!, {
        'userId': user.id.toString(),
        'dateTime': t.toString(),
        'condition': condition == null ? '_' : condition,
      });
    } else {
      route = Network.routeNormalize(getRoutes['reloadTimeLine']!, {
        'userId': user.id.toString(),
        'dateTime': t.toString(),
        'condition': condition == null ? '_' : condition,
      });
    }

    final http.Response response =
        await Network.getData(route, 'getTimeLine@PostApi');
    return response.body;
  }

  static Future<void> deletePost(Post post) async {
    Map<String, String> data = {'postId': post.id.toString()};
    await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['deletePost']!, data),
        'deletePost@PostApi');
  }

  static Future<Post> savePost(String inputText, List<File> images,
      [HabitLog? log]) async {
    Map<String, String> data = {
      'text': inputText,
    };
    if (log != null) {
      data['habit_log'] = log.id.toString();
    }
    http.Response response = await Network.postDataWithImage(
        data, images, postRoutes['savePost'], 'savePost@PostApi');
    return Post.fromJson(jsonDecode(response.body));
  }

  static Future<Post> getPost(int postId) async {
    Map<String, String> data = {'postId': postId.toString()};
    http.Response response = await Network.getData(
        Network.routeNormalize(getRoutes['getPost']!, data), "getPost@PostApi");
    Map<String, dynamic> body = jsonDecode(response.body);
    return Post.fromJson(body['post']);
  }

  static Future<Post> addCommentToPost(int postId, String commentBody) async {
    Map<String, dynamic> data = {
      'postId': postId,
      'commentBody': commentBody,
    };
    final http.Response response = await Network.postData(
        data, postRoutes["addCommentToPost"], 'addCommentToPost@PostApi');
    Map<String, dynamic> json = jsonDecode(response.body);
    Post post = Post.fromJson(json);
    return post;
  }

  static Future<void> deleteComment(int commentId) async {
    Map<String, String> data = {'commentId': commentId.toString()};
    await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['deleteComment']!, data),
        'deleteComment@PostApi');
  }

  static Future<int> likeToComment(int commentId) async {
    Map<String, dynamic> data = {
      'comment_id': commentId,
    };
    final http.Response response = await Network.postData(
        data, postRoutes['likeToComment'], 'likeToComment@PostApi');

    return jsonDecode(response.body)['favorite_count'];
  }

  static Future<int> unlikeFromComment(int commentId) async {
    Map<String, String> data = {
      'commentId': commentId.toString(),
    };
    final http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['unlikeFromComment']!, data), 'unlikeFromComment@PostApi');
    return jsonDecode(response.body)['favorite_count'];
  }

  static Future<int> likeToPost(int postId) async {
    Map<String, dynamic> data = {
      'post_id': postId,
    };
    final http.Response response =
        await Network.postData(data, postRoutes['likeToPost'], 'likeToPost@PostApi');
    Map<String, dynamic> json = jsonDecode(response.body);
    return json['favorite_count'];
  }

  static Future<int> unlikeFromPost(int postId) async {
    Map<String, String> data = {
      'postId': postId.toString(),
    };
    final http.Response response = await Network.deleteData(
        Network.routeNormalizeDelete(deleteRoutes['unlikeFromPost']!, data), 'unlikeFromPost@PostApi');
    return jsonDecode(response.body)['favorite_count'];
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
      'reportable_id': reportable.id,
      'body': body,
    };
    await Network.postData(data, postRoutes['report'], 'report@PostApi');
  }
}
