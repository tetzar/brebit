import 'dart:async';
import 'dart:convert';

import 'package:brebit/library/exceptions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../api/post.dart';
import '../../library/cache.dart';
import '../../model/post.dart';
import '../../model/user.dart';
import 'auth.dart';

final timelineProvider = StateNotifierProvider.family((ref, String name) {
  return TimelineProvider(name, new TimelineProviderState());
});

class TimelineProviderState {
  TimelineProviderState({posts}) : this.posts = posts ?? [];

  List<Post> posts;
}

class TimelineProvider extends StateNotifier<TimelineProviderState> {
  final String name;

  DateTime? lastUpdatedAt;
  DateTime? lastOlderUpdatedAt;

  bool noMoreContent = false;

  TimelineProvider(this.name, TimelineProviderState state) : super(state);

  List<Post> get posts => [...state.posts];

  void logout() {
    this.state.posts = [];
  }

  Future<bool> getTimeLine(WidgetRef ref, [DateTime? t]) async {
    if (state.posts.length == 0) {
      AuthUser _user = await ref.read(authProvider.notifier).getUser();
      List<Post> posts = await LocalManager.getPosts(_user, name);
      if (posts.length > 0) {
        state = new TimelineProviderState(posts: posts);
        if (lastUpdatedAt == null) {
          lastUpdatedAt = DateTime.now();
          reloadPosts(ref);
          if (state.posts.length < 10) noMoreContent = true;
        }
        return false;
      } else {
        String json = await PostApi.getTimeLine(_user, name);
        List<Post> posts = Post.sortByCreatedAt(postFromJson(jsonDecode(json)));
        if (posts.length < 10) reloadPosts(ref);
        if (state.posts.length < 10) noMoreContent = true;
        await LocalManager.setPosts(_user, posts, name);
        state = new TimelineProviderState(posts: posts);
      }
      return false;
    } else {
      DateTime? lastUpdatedAt = this.lastUpdatedAt;
      if (lastUpdatedAt != null) {
        if (lastUpdatedAt.add(Duration(minutes: 5)).isAfter(DateTime.now())) {
          return false;
        }
      }
      lastUpdatedAt = DateTime.now();
      return this.reloadPosts(ref);
    }
  }

  Future<bool> reloadPosts(WidgetRef ref, [bool older = false]) async {
    AuthProviderState _authProviderState =
        ref.read(authProvider.notifier).state;
    AuthUser? user = _authProviderState.user;
    if (user == null)
      throw ProviderValueMissingException(
          'user is null @ reloadPosts - PostsProvider');
    if (state.posts.length > 0) {
      if (older) {
        Post oldest = Post.getOldestInList(state.posts);
        DateTime? lastOlderUpdatedAt = this.lastOlderUpdatedAt;
        if (lastOlderUpdatedAt == null
            ? true
            : lastOlderUpdatedAt
                .isBefore(DateTime.now().subtract(Duration(minutes: 5)))) {
          String json =
              await PostApi.getTimeLine(user, name, oldest.createdAt, true);
          List<Post> newPosts = postFromJson(jsonDecode(json));
          if (newPosts.length < 10) noMoreContent = true;
          if (newPosts.length == 0) return true;
          state = new TimelineProviderState(
              posts:
                  Post.sortByCreatedAt(Post.mergeLists(newPosts, state.posts)));
          await LocalManager.setPosts(user, state.posts, name);
        }
        return false;
      } else {
        Post latest = Post.getLatestInList(state.posts);
        String json = await PostApi.getTimeLine(
          user,
          name,
          latest.createdAt,
        );
        List<Post> newPosts = postFromJson(jsonDecode(json));
        if (newPosts.length == 0) {
          return true;
        }
        state = new TimelineProviderState(
            posts:
                Post.sortByCreatedAt(Post.mergeLists(newPosts, state.posts)));
        await LocalManager.setPosts(user, state.posts, name);
        return false;
      }
    } else {
      String json = await PostApi.getTimeLine(
        user,
        name,
      );
      List<Post> posts = Post.sortByCreatedAt(postFromJson(jsonDecode(json)));
      if (posts.length == 0) {
        return true;
      }
      state = new TimelineProviderState(posts: posts);
      await LocalManager.setPosts(user, state.posts, name);
      return false;
    }
  }

  Future<void> deletePost(Post post) async {
    try {
      Post? _post =
      state.posts.firstWhere((_post) => _post.id == post.id);
      await _post.delete();
      removePost(_post);
    } on StateError{

    } catch (e) {
      throw e;
    }
  }

  void removePost(Post post) {
    this.state.posts.removeWhere((_post) => _post.id == post.id);
    state = new TimelineProviderState(posts: state.posts);
  }
}
