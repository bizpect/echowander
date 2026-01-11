import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_manager.dart';
import '../data/supabase_board_repository.dart';
import '../domain/board_error.dart';
import '../domain/board_post.dart';

@immutable
class BoardPostQuery {
  const BoardPostQuery({
    required this.boardKey,
    required this.typeCode,
    this.limit = 20,
    this.offset = 0,
  });

  final String boardKey;
  final String? typeCode;
  final int limit;
  final int offset;

  @override
  bool operator ==(Object other) {
    return other is BoardPostQuery &&
        other.boardKey == boardKey &&
        other.typeCode == typeCode &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(boardKey, typeCode, limit, offset);
}

final boardPostsProvider = FutureProvider.autoDispose
    .family<List<BoardPostSummary>, BoardPostQuery>((ref, query) async {
  final sessionState = ref.watch(sessionManagerProvider);
  final accessToken = sessionState.accessToken;
  if (accessToken == null || accessToken.isEmpty) {
    return [];
  }

  final repository = ref.read(boardRepositoryProvider);
  return repository.listBoardPosts(
    boardKey: query.boardKey,
    typeCode: query.typeCode,
    limit: query.limit,
    offset: query.offset,
    accessToken: accessToken,
  );
});

final boardPostDetailProvider =
    FutureProvider.autoDispose.family<BoardPostDetail, String>((ref, postId) {
  final sessionState = ref.watch(sessionManagerProvider);
  final accessToken = sessionState.accessToken;
  if (accessToken == null || accessToken.isEmpty) {
    throw const BoardException(BoardError.unauthorized);
  }

  final repository = ref.read(boardRepositoryProvider);
  return repository.getBoardPost(
    postId: postId,
    accessToken: accessToken,
  );
});
