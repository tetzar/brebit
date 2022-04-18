import '../../library/data-set.dart';
import '../../library/resolver.dart';
import 'comment.dart';
import 'favorite.dart';
import 'model.dart';
import 'user.dart';
import '../api/api.dart';
import '../api/post.dart';

// ignore: non_constant_identifier_names
List<Post> PostFromJson(List<dynamic> jsonList) =>
    List<Post>.from(jsonList.cast<Map>().map((x) => Post.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> PostToJson(List<Post> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

class Post extends Model {
  static Map<int, Post> posts;

  int id;
  AuthUser user;
  Map<String, dynamic> body;
  List<Comment> comments;
  List<String> imageUrls;
  List<Favorite> favorites;
  int favoriteCount;
  int public;
  DateTime createdAt;
  DateTime updatedAt;
  bool hide;

  Post({
    this.id,
    this.user,
    this.comments,
    this.body,
    this.public,
    this.imageUrls,
    this.hide,
    this.favoriteCount,
    this.createdAt,
    this.updatedAt,
  });

  static Post setPost(Post post) {
    if (posts == null) {
      posts = <int, Post>{};
    }
    posts[post.id] = post;
    return posts[post.id];
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data_set')) {
      DataSet.dataSetConvert(json['data_set']);
    }
    Post post;
    if (json.containsKey('user')) {
      post = Post(
        id: json["id"],
        user: AuthUser.fromJson(json["user"]),
        body:
            (json['body'] is List) ? new Map<String, dynamic>() : json['body'],
        comments: CommentFromJson(json['comments']),
        public: json["public"],
        hide: json["hide"],
        favoriteCount: json['favorite_count'],
        imageUrls: json['image_urls'].cast<String>(),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
      );
    } else {
      post = Post(
        id: json["id"],
        user: AuthUser.find(json["user_id"]),
        body:
            (json['body'] is List) ? new Map<String, dynamic>() : json['body'],
        comments: CommentFromJson(json['comments']),
        public: json["public"],
        hide: json["hide"],
        favoriteCount: json['favorite_count'],
        imageUrls: json['image_urls'].cast<String>(),
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
      );
    }
    post.setParentToComments();
    return setPost(post);
  }

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "id": id,
        "user": user.toJson(),
        "body": body,
        "public": public,
        "hide": hide,
        "comments": CommentToJson(comments),
        'favorite_count': favoriteCount,
        "image_urls": imageUrls,
      };

  Map<String, dynamic> getBody() {
    Map<String, dynamic> body = this.body;
    return Resolver.getBody(body);
  }

  //---------------------------------
  //  comment
  //---------------------------------

  int getCommentCount() {
    return this.comments.length;
  }

  Future<bool> addComment(String commentBody) async {
    Post post = await PostApi.addCommentToPost(this.id, commentBody);
    if (post == null) return false;
    post.comments.forEach((comment) {
      comment.parent = this;
      List<Comment> existing = this.comments.where((com) {
        return com.id == comment.id;
      }).toList();
      if (existing.length == 0) {
        int index = this.comments.indexWhere((com) {
          return comment.createdAt.isBefore(com.createdAt);
        });
        if (index < 0) {
          this.comments.add(comment);
        } else {
          this.comments.insert(index, comment);
        }
      }
    });
    return true;
  }

Future<bool> deleteComment(Comment comment) async {
    bool res = await PostApi.deleteComment(comment.id);
    if (res) removeComment(comment);
    return res;
  }

  void removeComment(Comment comment) {
    this.comments.removeWhere((cmt) {
      return cmt.id == comment.id;
    });
  }

  List<String> getImageUrls() {
    if (this.imageUrls == null) {
      return <String>[];
    }
    return this.imageUrls.map((url) => Network.url + url).toList();
  }

  //---------------------------------
  //  like
  //---------------------------------

  bool isLiked() {
    AuthUser selfUser = AuthUser.selfUser;
    return selfUser.likedPostIds.contains(this.id);
  }

  Future<int> like() async {
    if (!this.isLiked()) {
      if (!AuthUser.selfUser.likedPostIds.contains(this.id)) {
        AuthUser.selfUser.likedPostIds.add(this.id);
      }
      int favCount = await PostApi.likeToPost(this.id);
      if (favCount == null) return this.favoriteCount;
      this.favoriteCount = favCount;
      return favCount;
    }
    return this.favoriteCount;
  }

  Future<int> unlike() async {
    if (this.isLiked()) {
      int result = await PostApi.unlikeFromPost(this.id);
      if (result != null) {
        this.favoriteCount = result;
        if (AuthUser.selfUser.likedPostIds.contains(this.id)) {
          AuthUser.selfUser.likedPostIds.remove(this.id);
        }
        return result;
      }
    }
    return this.favoriteCount;
  }

  int getFavCount() {
    return this.favoriteCount;
  }

  bool isMine() {
    int selfUserId = AuthUser.selfUser.id;
    return this.user.id == selfUserId;
  }

  Future<bool> delete() async {
    return await PostApi.deletePost(this);
  }

  void setParentToComments() {
    this.comments.forEach((cmt) {
      cmt.parent = this;
    });
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

  //---------------------------------
  //  sort
  //---------------------------------

  static List<Post> sortByCreatedAt(List<Post> posts, [bool desc = true]) {
    if (posts == null) return [];
    if (desc) {
      posts.sort((a, b) {
        return a.createdAt.isAfter(b.createdAt) ? -1 : 1;
      });
    } else {
      posts.sort((a, b) {
        return a.createdAt.isBefore(b.createdAt) ? -1 : 1;
      });
    }
    return posts;
  }

  static Post getOldestInList(List<Post> posts) {
    DateTime t = posts.first.createdAt;
    Post oldest = posts.first;
    for (Post _p in posts) {
      if (t.isAfter(_p.createdAt)) {
        t = _p.createdAt;
        oldest = _p;
      }
    }
    return oldest;
  }

  static Post getLatestInList(List<Post> posts) {
    DateTime t = posts.first.createdAt;
    Post latest = posts.first;
    for (Post _p in posts) {
      if (t.isBefore(_p.createdAt)) {
        t = _p.createdAt;
        latest = _p;
      }
    }
    return latest;
  }

  static List<Post> mergeLists(List<Post> prior, List<Post> sub) {
    List<Post> merged = <Post>[...sub];
    for (Post _priorPost in prior) {
      int index = merged.indexWhere((_subPost) => _subPost.id == _priorPost.id);
      if (index < 0) {
        merged.add(_priorPost);
      } else {
        merged[index] = _priorPost;
      }
    }
    return merged;
  }
}
