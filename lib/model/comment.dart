
// ignore: non_constant_identifier_names
import 'package:brebit/library/data-set.dart';
import 'package:brebit/model/user.dart';
import 'package:brebit/api/post.dart';

import 'favorite.dart';
import 'model.dart';

List<Comment> CommentFromJson(List<dynamic> list) =>
    new List<Comment>.from(list.cast<Map>().map((x) => Comment.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> CommentToJson(List<Comment> data) =>
    new List<Map>.from(data.map((x) => x.toJson()));

class Comment extends Model {
  int id;
  AuthUser user;
  String body;
  int favoriteCount;
  List<Comment> comments;
  List<String> imageUrls;
  List<Favorite> favorites;
  DateTime createdAt;
  DateTime updatedAt;
  bool hide;
  var parent;

  Comment({
    this.id,
    this.user,
    this.body,
    this.comments,
    this.imageUrls,
    this.favoriteCount,
    this.hide,
    this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data_set')) {
      DataSet.dataSetConvert(json['data_set']);
    }
    if (json.containsKey('user')) {
      return new Comment(
        id: json["id"],
        user: AuthUser.fromJson(json['user']),
        body: json["body"],
        comments: CommentFromJson(json['comments']),
        favoriteCount: json['favorite_count'],
        hide: json['hide'],
        imageUrls: json['image_urls'].length > 0
            ? []
            : json['image_urls'].cast<String>(),
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
      );
    }
    return new Comment(
      id: json["id"],
      user: AuthUser.find(json['user_id']),
      body: json["body"],
      comments: CommentFromJson(json['comments']),
      favoriteCount: json['favorite_count'],
      hide: json['hide'],
      imageUrls: json['image_urls'].length > 0
          ? []
          : json['image_urls'].cast<String>(),
      createdAt: DateTime.parse(json["created_at"]),
      updatedAt: DateTime.parse(json["updated_at"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "id": id,
        "user": user.toJson(),
        'image_urls': imageUrls,
        "body": body,
        "hide": hide,
        'favorite_count': favoriteCount,
        'comments': CommentToJson(comments),
      };

  bool isMine() {
    int selfUserId = AuthUser.selfUser.id;
    return this.user.id == selfUserId;
  }

  bool isLiked() {
    AuthUser selfUser = AuthUser.selfUser;
    return selfUser.likedCommentIds.contains(this.id);
  }

  Future<int> like() async {
    if (!this.isLiked()) {
      if (!AuthUser.selfUser.likedCommentIds.contains(this.id)) {
        AuthUser.selfUser.likedCommentIds.add(this.id);
      }
      int favCount = await PostApi.likeToComment(this.id);
      if (favCount == null) return this.favoriteCount;
      this.favoriteCount = favCount;
    }
    return this.favoriteCount;
  }

  Future<int> unlike() async {
    if (this.isLiked()) {
      int result = await PostApi.unlikeFromComment(this.id);
      if (result != null) {
        this.favoriteCount = result;
        if (AuthUser.selfUser.likedCommentIds.contains(this.id)) {
          AuthUser.selfUser.likedCommentIds.remove(this.id);
        }
      }
    }
    return this.favoriteCount;
  }

  int getFavCount() {
    return this.favoriteCount;
  }

  String getCreatedTime() {
    Duration duration = DateTime.now().difference(this.createdAt);
    int days = duration.inDays;
    if (days > 0) {
      if (days > 6) {
        if (days > 29) {
          if (days > 364) {
            return (days ~/ 365).toString() + '年前';
          } else {
            return (days ~/ 30).toString() + 'ヶ月前';
          }
        } else {
          return (days ~/ 7).toString() + '週間前';
        }
      } else {
        return (days).toString() + '日前';
      }
    } else {
      int hours = duration.inHours;
      if (hours > 0) {
        return hours.toString() + '時間前';
      } else {
        int minutes = duration.inMinutes;
        if (minutes > 0) {
          return minutes.toString() + '分前';
        } else {
          return duration.inSeconds.toString() + '秒前';
        }
      }
    }
  }
}
