import '../../library/data-set.dart';
import '../api/notification.dart';
import 'comment.dart';
import 'favorite.dart';
import 'model.dart';
import 'partner.dart';
import 'post.dart';

List<UserNotification> userNotificationFromJson(List<dynamic> decodedList) =>
    List<UserNotification>.from(decodedList
        .cast<Map<String, dynamic>>()
        .map((x) => UserNotification.fromJson(x)));

List<Map> userNotificationToJson(List<UserNotification> data) =>
    new List<Map>.from(data.map((x) => x.toJson()));

enum UserNotificationType {
  liked,
  commented,
  partnerRequested,
  partnerAccepted,
  information,
}

class UserNotification extends Model {
  static final int _keepDays = 30;

  String id;
  String type;
  Map<String, dynamic> data;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? readAt;

  UserNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.readAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data_set')) {
      DataSet.dataSetConvert(json['data_set']);
    }
    return new UserNotification(
      createdAt: DateTime.parse(json["created_at"]).toLocal(),
      updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
      readAt: (json['read_at'] == null)
          ? null
          : DateTime.parse(json["read_at"]).toLocal(),
      id: json["id"],
      type: json["type"],
      data: json["data"],
    );
  }

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "read_at": readAt?.toIso8601String(),
        "id": id,
        "type": type,
        "data": data,
      };

  bool hasRead() {
    return this.readAt != null;
  }

  Future<void> read() async {
    this.readAt = await NotificationApi.readNotification(this.id);
  }

  bool get expired {
    return DateTime.now()
        .isAfter(this.createdAt.add(Duration(days: _keepDays)));
  }

  UserNotificationType getType() {
    List<String> splitType = this.type.split('\\');
    switch (splitType.last) {
      case 'LikedNotification':
        return UserNotificationType.liked;
      case 'CommentNotification':
        return UserNotificationType.commented;
      case 'PartnerRequestNotification':
        return UserNotificationType.partnerRequested;
      case 'PartnerAcceptedNotification':
        return UserNotificationType.partnerAccepted;
      default:
        return UserNotificationType.information;
    }
  }

  Map<String, dynamic> getBody() {
    UserNotificationType? _type = this.getType();
    Map<String, dynamic> result = <String, dynamic>{};
    switch (_type) {
      case UserNotificationType.liked:
        List<Favorite> favorites = favoriteFromJson(data['favorites']);
        result['favorites'] = favorites;
        if (!data.containsKey('favorite_count')) {
          result['favorite_count'] = favorites.length;
        } else {
          result['favorite_count'] = data['favorite_count'];
        }
        if (this.data.containsKey('post')) {
          Post post = Post.fromJson(data['post']);
          result['post'] = post;
        } else {
          Comment comment = Comment.fromJson(data['comment']);
          Post post = Post.fromJson(data['post']);
          result['post'] = post;
          result['comment'] = comment;
        }
        break;
      case UserNotificationType.commented:
        Comment comment = Comment.fromJson(data['comment']);
        result['comment'] = comment;
        if (this.data.containsKey('post')) {
          Post post = Post.fromJson(data['post']);
          result['post'] = post;
        } else {
          Comment comment = Comment.fromJson(data['commented']);
          Post post = Post.fromJson(data['post']);
          result['post'] = post;
          result['commented'] = comment;
        }
        break;
      case UserNotificationType.partnerAccepted:
      case UserNotificationType.partnerRequested:
        Partner partner = Partner.fromJson(data['partner']);
        result['partner'] = partner;
        break;
      default:
        result['title'] = data['title'];
        result['information_id'] = data['information_id'];
        break;
    }
    return result;
  }

  static List<UserNotification> sortByCreatedAt(
      List<UserNotification> notifications,
      [bool desc = true]) {
    if (desc) {
      notifications.sort((a, b) {
        return a.createdAt.isAfter(b.createdAt) ? -1 : 1;
      });
    } else {
      notifications.sort((a, b) {
        return a.createdAt.isBefore(b.createdAt) ? -1 : 1;
      });
    }
    return notifications;
  }

  static Map<bool, List<UserNotification>> collectByRead(
      List<UserNotification> notifications) {
    List<UserNotification> read = <UserNotification>[];
    List<UserNotification> unread = <UserNotification>[];
    for (UserNotification _notification in notifications) {
      if (_notification.hasRead()) {
        read.add(_notification);
      } else {
        unread.add(_notification);
      }
    }
    read = UserNotification.sortByCreatedAt(read);
    unread = UserNotification.sortByCreatedAt(unread);
    return <bool, List<UserNotification>>{true: read, false: unread};
  }
}
