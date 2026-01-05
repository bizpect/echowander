class BlockedUser {
  BlockedUser({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.createdAt,
  });

  final String userId;
  final String nickname;
  final String avatarUrl;
  final DateTime createdAt;
}

enum BlockError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class BlockException implements Exception {
  BlockException(this.error);

  final BlockError error;
}

abstract class BlockRepository {
  Future<List<BlockedUser>> fetchBlocks({
    required int limit,
    required int offset,
    required String accessToken,
  });

  Future<void> blockUser({
    required String targetUserId,
    required String accessToken,
  });

  Future<void> unblockUser({
    required String targetUserId,
    required String accessToken,
  });
}
