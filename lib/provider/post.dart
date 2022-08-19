import '../../model/comment.dart';
import '../../model/post.dart';
import '../../api/post.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final postProvider = StateNotifierProvider.family<PostProvider, PostProviderState, int>(
    (ref, postId) => PostProvider(new PostProviderState()));

class PostProviderState {
  Post? post;

  PostProviderState({this.post});
}

class PostProvider extends StateNotifier<PostProviderState> {
  PostProvider(PostProviderState state) : super(state);

  Post? get post => state.post;

  void setPost(Post post) {
    state.post = post;
  }

  void setPostNotify(Post post) {
    this.state = new PostProviderState(post: post);
  }

  Future<void> addCommentToPost(comment) async {
    Post? post = state.post;
    if (post == null) return;
    await post.addComment(comment);
    setPostNotify(post);
  }

  Future<void> deleteComment(Comment comment) async {
    Post? post = state.post;
    if (post == null) return;
    await post.deleteComment(comment);
    setPostNotify(post);
  }

  void removeComment(Comment comment) {
    Post? post = state.post;
    if (post == null) return;
    post.removeComment(comment);
    setPostNotify(post);
  }

  Post? getPost() {
    return this.state.post;
  }

  Future<void> reload() async {
    Post? currentPost = state.post;
    if (currentPost == null) return;
    Post post = await PostApi.getPost(currentPost.id);
    currentPost.updatePost(post);
    this.setPostNotify(post);
  }
}
