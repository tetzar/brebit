// package:brebit/model/AuthUser

import '../../library/data-set.dart';
import 'category.dart';
import 'post.dart';
import 'model.dart';
import 'partner.dart';
import '../network/api.dart';
import '../network/auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ignore: non_constant_identifier_names
List<AuthUser> AuthUserFromJson(List<dynamic> decodedList) =>
    new List<AuthUser>.from(
        decodedList.cast<Map>().map((x) => AuthUser.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> AuthUserToJson(List<AuthUser> data) =>
    List<Map>.from(data.map((x) => x.toJson()));

enum AdminType { general, administrator, defaultUser, hidden }

class AuthUser extends Model {
  static AuthUser selfUser;

  static List<AuthUser> userList = <AuthUser>[];

  static final Map<AdminType, int> adminID = {
    AdminType.general: 0,
    AdminType.administrator: 1,
    AdminType.defaultUser: 2,
    AdminType.hidden: 3,
  };

  String name;
  int id;
  String bio;
  String customId;
  int admin;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime softDeletedAt;
  String imageUrl;
  int postCount;
  List<Post> posts = [];
  List<Partner> partners = [];
  List<Category> habitCategories = [];
  List<Category> suspendingHabitCategories = [];
  List<int> likedPostIds = <int>[];
  List<int> likedCommentIds = <int>[];

  AuthUser({
    this.name,
    this.id,
    this.bio,
    this.customId,
    this.admin,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.softDeletedAt,
    this.habitCategories,
    this.suspendingHabitCategories,
    this.likedPostIds,
    this.likedCommentIds,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data_set')) {
      DataSet.dataSetConvert(json['data_set']);
    }
    AuthUser newUser;
    if (json.containsKey('habit_categories')) {
      newUser = new AuthUser(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        softDeletedAt: (json["soft_delete_at"] != null)
            ? DateTime.parse(json["soft_deleted_at"]).toLocal()
            : null,
        id: json["id"],
        bio: (json["bio"] != null) ? json['bio'] : '',
        customId: json["custom_id"],
        admin: json["admin"],
        name: json['name'],
        imageUrl: json['image_url'],
        habitCategories: CategoryFromJson(json['habit_categories'] ?? []),
        suspendingHabitCategories:
            CategoryFromJson(json['suspending_habit_categories'] ?? []),
        likedPostIds: json['liked_post_ids'].length > 0
            ? json['liked_post_ids'].cast<int>() as List<int>
            : <int>[],
        likedCommentIds: json['liked_comment_ids'].length > 0
            ? json['liked_comment_ids'].cast<int>() as List<int>
            : <int>[],
      );
    } else {
      newUser = new AuthUser(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        softDeletedAt: (json["soft_delete_at"] != null)
            ? DateTime.parse(json["soft_deleted_at"]).toLocal()
            : null,
        id: json["id"],
        bio: (json["bio"] != null) ? json['bio'] : '',
        customId: json["custom_id"],
        admin: json["admin"],
        name: json['name'],
        imageUrl: json['image_url'],
        habitCategories: Category.findAll(json['habit_category_ids'] ?? []),
        suspendingHabitCategories:
            Category.findAll(json['suspending_habit_category_ids'] ?? []),
        likedPostIds: json['liked_post_ids'].length > 0
            ? json['liked_post_ids'].cast<int>() as List<int>
            : <int>[],
        likedCommentIds: json['liked_comment_ids'].length > 0
            ? json['liked_comment_ids'].cast<int>() as List<int>
            : <int>[],
      );
    }

    int userIndex = AuthUser.userList.indexWhere((u) => u.id == newUser.id);
    if (userIndex < 0) {
      AuthUser.userList.add(newUser);
      userIndex = AuthUser.userList.length - 1;
    } else {
      AuthUser currentUser = AuthUser.userList[userIndex];
      newUser.posts = currentUser.posts;
      newUser.partners = currentUser.partners;
      AuthUser.userList[userIndex] = newUser;
    }
    return AuthUser.userList[userIndex];
  }

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "soft_deleted_at": updatedAt.toIso8601String(),
        "id": id,
        "bio": bio,
        'image_url': imageUrl,
        "custom_id": customId,
        "admin": admin,
        "name": name,
        "habit_categories": CategoryToJson(this.habitCategories),
        "suspending_habit_categories":
            CategoryToJson(this.suspendingHabitCategories),
        'liked_post_ids': likedPostIds,
        'liked_comment_ids': likedCommentIds,
      };

  static AuthUser find(int searchId) {
    int userIndex = AuthUser.userList.indexWhere((u) => u.id == searchId);
    if (userIndex < 0) {
      return null;
    } else {
      return AuthUser.userList[userIndex];
    }
  }

  static String getSelfUid() {
    FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return auth.currentUser.uid;
    } else {
      return null;
    }
  }

  static User getSelfUser() {
    FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return auth.currentUser;
    } else {
      return null;
    }
  }

  void setProfileImageUrl(String url) {
    this.imageUrl = url;
  }

  String getImageUrl() {
    return this.imageUrl ?? '';
  }

  bool hasImage() {
    return this.getImageUrl().length > 0;
  }

  Widget getImageWidget() {
    if (this.getImageUrl() == "") {
      return Image.asset(
        'assets/icon/default.png',
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      placeholder: (context, url) => Container(
        color: Colors.black12,
      ),
      imageUrl: Network.url + this.imageUrl,
      fit: BoxFit.cover,
    );
  }

  bool isHidden() {
    return adminID[AdminType.hidden] == this.admin;
  }

  //---------------------------------
  //  habit
  //---------------------------------

  List<Category> getActiveHabitCategories() {
    return this.habitCategories;
  }

  List<Category> getSuspendingHabitCategories() {
    return this.suspendingHabitCategories;
  }

  bool isActiveHabitCategory(CategoryName categoryName) {
    int index = habitCategories.indexWhere((category) {
      return category.name == categoryName;
    });
    return !(index < 0);
  }

  bool isSuspendingCategory(CategoryName categoryName) {
    int index = suspendingHabitCategories
        .indexWhere((category) => categoryName == category.name);
    return !(index < 0);
  }

  bool isUnStartedCategory(CategoryName categoryName) {
    int index = suspendingHabitCategories
        .indexWhere((category) => categoryName == category.name);
    if (!(index < 0)) {
      return false;
    }
    index = habitCategories.indexWhere((category) {
      return category.name == categoryName;
    });
    return index < 0;
  }

  void addActiveHabitCategory(Category category) {
    int index = this
        .habitCategories
        .indexWhere((habitCategory) => habitCategory.id == category.id);
    if (index < 0) {
      this.habitCategories.add(category);
    } else {
      this.habitCategories[index] = category;
    }
    this
        .suspendingHabitCategories
        .removeWhere((habitCategory) => habitCategory.id == category.id);
  }

  //---------------------------------
  //  partner
  //---------------------------------

  void setPartners(List<Partner> partners) {
    this.partners = partners;
  }

  int partnerState(AuthUser user) {
    int index =
        this.partners.indexWhere((partner) => partner.user.id == user.id);
    if (index < 0) {
      return -1;
    } else {
      return this.partners[index].state;
    }
  }

  Partner getPartner(AuthUser user) {
    int index =
        this.partners.indexWhere((partner) => partner.user.id == user.id);
    if (index < 0) {
      return null;
    } else {
      return this.partners[index];
    }
  }

  void addPartner(Partner partner) {
    int index = this.partners.indexWhere((p) => p.id == partner.id);
    if (index < 0) {
      this.partners.add(partner);
    } else {
      this.partners[index] = partner;
    }
  }

  void removePartner(Partner partner) {
    if (partner != null) {
      this.partners.removeWhere((p) => p.id == partner.id);
    }
  }

  int getPartnerCount() {
    return this.getAcceptedPartners().length;
  }

  List<Partner> getAcceptedPartners() {
    return this.partners.where((p) => p.stateIs(PartnerState.partner)).toList();
  }

  List<Partner> getRequestedPartners() {
    return this
        .partners
        .where((p) => p.stateIs(PartnerState.requested))
        .toList();
  }

  bool isFriend(AuthUser user) {
    int state = this.partnerState(user);
    return state == Partner.getStateId(PartnerState.partner);
  }

  bool isRequesting(AuthUser user) {
    int state = this.partnerState(user);
    return state == Partner.getStateId(PartnerState.request);
  }

  bool isBlocking(AuthUser user) {
    int state = this.partnerState(user);
    return state == Partner.getStateId(PartnerState.block);
  }

  bool isBlocked(AuthUser user) {
    int state = this.partnerState(user);
    return state == Partner.getStateId(PartnerState.blocked);
  }

  List<Partner> getBlockingList() {
    return this.partners.where((partner) {
      return partner.stateIs(PartnerState.block);
    }).toList();
  }

  //---------------------------------
  //  post
  //---------------------------------

  int getPostCount() {
    if (this.postCount != null) {
      return this.postCount;
    }
    if (this.posts == null) {
      this.posts = <Post>[];
      return 0;
    } else {
      return this.posts.length;
    }
  }

  Future<bool> deletePost(Post post) async {
    int count = await AuthApi.deletePost(post);
    if (count < 0) {
      return false;
    }
    this.postCount = count;
    return true;
  }

  void setPost(Post post) {
    int index = this.getIndexOfPosts(post);
    if (index < 0) {
      this.posts.add(post);
    } else {
      this.posts[index] = post;
    }
  }

  void updatePost(Post post) {
    int index = this.getIndexOfPosts(post);
    if (!(index < 0)) {
      this.posts[index] = post;
    }
  }

  int getIndexOfPosts(Post post) {
    return this.posts.indexWhere((_post) => post.id == _post.id);
  }

  void removePost(Post post) {
    if (this.posts == null) return;
    this.posts.removeWhere((_post) => _post.id == post.id);
  }
}
