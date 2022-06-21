import '../../model/comment.dart';
import '../../model/post.dart';
import '../../api/post.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final postProvider = StateNotifierProvider.family<PostProvider, int>(
    (ref, postId) => PostProvider(new PostProviderState()));

class PostProviderState {
  Post post;

  PostProviderState({this.post});
}

class PostProvider extends StateNotifier<PostProviderState> {
  PostProvider(PostProviderState state) : super(state);

  void setPost(Post post) {
    state.post = post;
  }

  void setPostNotify(Post post) {
    this.state = new PostProviderState(post: post);
  }

  Future<void> addCommentToPost(comment) async {
    await state.post.addComment(comment);
    state = state;
  }

  Future<void> deleteComment(Comment comment) async {
    await state.post.deleteComment(comment);
    state = state;
  }

  void removeComment(Comment comment) {
    state.post.removeComment(comment);
    state = state;
  }

  Post getPost() {
    return this.state.post;
  }

  Future<void> reload() async {
    Post post = await PostApi.getPost(this.state.post.id);
    state.post.updatePost(post);
    this.state = state;
  }
}
