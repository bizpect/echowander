import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/block/block_repository.dart';
import '../../../core/block/supabase_block_repository.dart';
import '../../../core/session/auth_executor.dart';
import '../../../core/session/session_manager.dart';

const _logPrefix = '[BlockList]';

enum BlockListMessage {
  missingSession,
  loadFailed,
  unblockFailed,
  unblockSuccess, // ✅ 차단 해제 성공
}

class BlockListState {
  const BlockListState({
    required this.items,
    required this.isLoading,
    this.message,
  });

  final List<BlockedUser> items;
  final bool isLoading;
  final BlockListMessage? message;

  BlockListState copyWith({
    List<BlockedUser>? items,
    bool? isLoading,
    BlockListMessage? message,
    bool clearMessage = false,
  }) {
    return BlockListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final blockListControllerProvider =
    NotifierProvider<BlockListController, BlockListState>(
      BlockListController.new,
    );

class BlockListController extends Notifier<BlockListState> {
  static const int _defaultLimit = 50;

  /// build 재호출 시 LateInitializationError 방지를 위해 getter로 접근
  BlockRepository get _blockRepository => ref.read(blockRepositoryProvider);

  @override
  BlockListState build() {
    return const BlockListState(items: [], isLoading: false, message: null);
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    if (kDebugMode) {
      debugPrint('$_logPrefix load - start, limit: $limit, offset: $offset');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);

    try {
      final executor = AuthExecutor(ref);
      final result = await executor.execute<List<BlockedUser>>(
        operation: (accessToken) => _blockRepository.fetchBlocks(
          limit: limit,
          offset: offset,
          accessToken: accessToken,
        ),
        isUnauthorized: (error) =>
            error is BlockException && error.error == BlockError.unauthorized,
      );

      switch (result) {
        case AuthExecutorSuccess<List<BlockedUser>>(:final data):
          if (kDebugMode) {
            debugPrint('$_logPrefix load - completed, items: ${data.length}');
          }
          state = state.copyWith(items: data, isLoading: false);
        case AuthExecutorNoSession<List<BlockedUser>>():
          if (kDebugMode) {
            debugPrint('$_logPrefix load - missing accessToken');
          }
          state = state.copyWith(
            isLoading: false,
            message: BlockListMessage.missingSession,
          );
        case AuthExecutorUnauthorized<List<BlockedUser>>():
          if (kDebugMode) {
            debugPrint('$_logPrefix load - unauthorized after retry');
          }
          state = state.copyWith(
            isLoading: false,
            message: BlockListMessage.missingSession,
          );
        case AuthExecutorTransientError<List<BlockedUser>>():
          // 일시 장애: 네트워크/서버 문제 (로그아웃 아님)
          if (kDebugMode) {
            debugPrint('$_logPrefix load - transient error (network/server)');
          }
          state = state.copyWith(
            isLoading: false,
            message: BlockListMessage.loadFailed,
          );
      }
    } on BlockException catch (error) {
      // 네트워크 오류 등 401이 아닌 예외
      if (kDebugMode) {
        debugPrint('$_logPrefix load - BlockException: ${error.error}');
      }
      state = state.copyWith(
        isLoading: false,
        message: BlockListMessage.loadFailed,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix load - unknown error: $error');
      }
      state = state.copyWith(
        isLoading: false,
        message: BlockListMessage.loadFailed,
      );
    }
  }

  Future<void> unblock(String targetUserId, {String? traceId}) async {
    // ✅ traceId 생성 (없으면 생성)
    final finalTraceId = traceId ?? DateTime.now().microsecondsSinceEpoch.toString();
    if (kDebugMode) {
      debugPrint('block:unblock start traceId=$finalTraceId target=$targetUserId');
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('block:unblock missingSession traceId=$finalTraceId');
      }
      state = state.copyWith(message: BlockListMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _blockRepository.unblockUser(
        targetUserId: targetUserId,
        accessToken: accessToken,
        traceId: finalTraceId,
      );
      if (kDebugMode) {
        debugPrint('block:unblock success traceId=$finalTraceId');
      }
      final items = state.items
          .where((item) => item.userId != targetUserId)
          .toList();
      // ✅ 차단 해제 성공 메시지 설정
      state = state.copyWith(
        items: items,
        isLoading: false,
        message: BlockListMessage.unblockSuccess,
      );
    } on BlockException catch (error) {
      if (kDebugMode) {
        debugPrint('block:unblock failed traceId=$finalTraceId error=${error.error}');
      }
      final message = error.error == BlockError.unauthorized
          ? BlockListMessage.missingSession
          : BlockListMessage.unblockFailed;
      state = state.copyWith(isLoading: false, message: message);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('block:unblock unknown error traceId=$finalTraceId error=$error');
      }
      state = state.copyWith(
        isLoading: false,
        message: BlockListMessage.unblockFailed,
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}
