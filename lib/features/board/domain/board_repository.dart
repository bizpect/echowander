import 'board_post.dart';

abstract class BoardRepository {
  Future<List<BoardPostSummary>> listBoardPosts({
    required String boardKey,
    String? typeCode,
    int limit,
    int offset,
    required String accessToken,
  });

  Future<BoardPostDetail> getBoardPost({
    required String postId,
    required String accessToken,
  });
}
