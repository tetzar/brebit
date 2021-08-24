import 'dart:async';
import 'dart:convert';

import '../../library/cache.dart';
import '../../model/post.dart';
import '../../model/user.dart';
import '../../network/post.dart';
import 'auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final timelineProvider = StateNotifierProvider.family((ref, name) {
  return TimelineProvider(name, new TimelineProviderState());
});

class TimelineProviderState {
  TimelineProviderState({this.posts});

  List<Post> posts;
}

class TimelineProvider extends StateNotifier<TimelineProviderState> {
  final String name;

  DateTime lastUpdatedAt;
  DateTime lastOlderUpdatedAt;

  TimelineProvider(this.name, TimelineProviderState state) : super(state);

  void logout() {
    this.state.posts = null;
    print(this.state.posts);
  }

  Future<bool> getTimeLine(BuildContext context, [DateTime t]) async {
    if (state.posts == null ? true : state.posts.length == 0) {
      try {
        AuthUser _user = await context.read(authProvider).getUser();
        List<Post> posts = await LocalManager.getPosts(_user, name);
        if (!(posts == null)) {
          state = new TimelineProviderState(posts: posts);
          if (lastUpdatedAt == null) {
            lastUpdatedAt = DateTime.now();
            reloadPosts(context);
          }
          return false;
        } else {
          String json = await PostApi.getTimeLine(_user, name);
          List<Post> posts =
              Post.sortByCreatedAt(PostFromJson(jsonDecode(json)));
          await LocalManager.setPosts(_user, posts, name);
          state = new TimelineProviderState(posts: posts);
        }
        return false;
      } catch (e) {
        print('caught error in provider/posts.dart@getTimeLine');
        throw e;
      }
    } else {
      try {
        if (lastUpdatedAt != null) {
          if (lastUpdatedAt.add(Duration(minutes: 5)).isAfter(DateTime.now())) {
            return false;
          }
        }
        lastUpdatedAt = DateTime.now();
        return this.reloadPosts(context);
      } catch (e) {
        print('caught error in provider/posts.dart@getTimeLine');
        throw e;
      }
    }
  }

  Future<bool> reloadPosts(BuildContext context, [bool older = false]) async {
    AuthProviderState _authProviderState = context.read(authProvider).state;
    if (state.posts == null) {
      return await getTimeLine(context);
    } else if (state.posts.length > 0) {
      if (older) {
        Post oldest = Post.getOldestInList(state.posts);
        try {
          if (lastOlderUpdatedAt == null ? true :
          lastOlderUpdatedAt.isBefore(
            DateTime.now().subtract(Duration(minutes: 5))
          )){
            String json = await PostApi.getTimeLine(
                _authProviderState.user, name, oldest.createdAt, true);
            List<Post> newPosts = PostFromJson(jsonDecode(json));
            if (newPosts.length == 0) {
              return true;
            }
            state = new TimelineProviderState(
                posts:
                Post.sortByCreatedAt(Post.mergeLists(newPosts, state.posts)));
            await LocalManager.setPosts(
                _authProviderState.user, state.posts, name);
          }
          return false;
        } catch (e) {
          print(e.toString());
          print('Error occurred in provider/posts@getTimeLine');
          throw e;
        }
      } else {
        Post latest = Post.getLatestInList(state.posts);
        try {
          String json = await PostApi.getTimeLine(
            _authProviderState.user,
            name,
            latest.createdAt,
          );
          List<Post> newPosts = PostFromJson(jsonDecode(json));
          if (newPosts.length == 0) {
            return true;
          }
          state = new TimelineProviderState(
              posts: Post.sortByCreatedAt(
                Post.mergeLists(newPosts, state.posts)
              ));
          await LocalManager.setPosts(
              _authProviderState.user, state.posts, name);
          return false;
        } catch (e) {
          print(e.toString());
          print('Error occurred in provider/posts@getTimeLine');
          throw e;
        }
      }
    } else {
      String json = await PostApi.getTimeLine(
        _authProviderState.user,
        name,
      );
      List<Post> posts = Post.sortByCreatedAt(PostFromJson(jsonDecode(json)));
      if (posts == null) {
        state = new TimelineProviderState(posts: <Post>[]);
        return true;
      } else {
        if (posts.length == 0) {
          return true;
        }
        state = new TimelineProviderState(posts: posts);
      }
      await LocalManager.setPosts(_authProviderState.user, state.posts, name);
      return false;
    }
  }

  Future<bool> deletePost(Post post) async {
    if (state == null) {
      return null;
    }
    if (state.posts == null) {
      return null;
    }
    Post _post = state.posts
        .firstWhere((_post) => _post.id == post.id, orElse: () => null);
    if (_post != null) {
      bool success = await _post.delete();
      if (success) {
        List<Post> posts = state.posts;
        posts.removeWhere((_post) => _post.id == post.id);
        state = new TimelineProviderState(posts: posts);
        return true;
      }
    }
    return false;
  }

  void removePost(Post post) {
    this.state.posts.removeWhere((_post) => _post.id == post.id);
    state = new TimelineProviderState(posts: state.posts);
  }
}
