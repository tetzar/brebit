
import '../../model/comment.dart';
import '../../model/post.dart';
import '../../network/post.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final postProvider =
StateNotifierProvider.family<PostProvider, int>(
  (ref, postId) => PostProvider(
    new PostProviderState()
  )
);

class PostProviderState{
  Post post;
  PostProviderState({this.post});
}

class PostProvider extends StateNotifier<PostProviderState> {
  PostProvider(PostProviderState state) : super(state);

  void setPost(Post post) {
    state.post = post;
  }

  void setPostNotify(Post post) {
    this.state = new PostProviderState(
      post: post
    );
  }

  Future<void> addCommentToPost(comment) async{
    await state.post.addComment(comment);
    state = state;
  }

  Future<void> deleteComment(Comment comment) async {
    await state.post.deleteComment(comment).then((value){
      state = new PostProviderState(
          post: state.post
      );
    });
  }

  void removeComment(Comment comment) {
    state.post.comments.removeWhere((_comment) => _comment.id == comment.id);
    state = state;
  }

  Post getPost() {
    return this.state.post;
  }

  Future<void> reload() async {
    Post post = await PostApi.getPost(this.state.post.id);
    state.post = post;
    this.state = state;
  }
}

