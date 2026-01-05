import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/block/block_repository.dart';
import '../../../core/block/supabase_block_repository.dart';
import '../../../core/session/session_manager.dart';

enum BlockListMessage {
  missingSession,
  loadFailed,
  unblockFailed,
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
  late final BlockRepository _blockRepository;

  @override
  BlockListState build() {
    _blockRepository = ref.read(blockRepositoryProvider);
    return const BlockListState(
      items: [],
      isLoading: false,
      message: null,
    );
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: BlockListMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final items = await _blockRepository.fetchBlocks(
        limit: limit,
        offset: offset,
        accessToken: accessToken,
      );
      state = state.copyWith(items: items, isLoading: false);
    } on BlockException catch (error) {
      if (kDebugMode) {
        debugPrint('block: 목록 로드 실패 (${error.error})');
      }
      final message = error.error == BlockError.unauthorized
          ? BlockListMessage.missingSession
          : BlockListMessage.loadFailed;
      state = state.copyWith(isLoading: false, message: message);
    } catch (_) {
      if (kDebugMode) {
        debugPrint('block: 목록 로드 알 수 없는 오류');
      }
      state = state.copyWith(isLoading: false, message: BlockListMessage.loadFailed);
    }
  }

  Future<void> unblock(String targetUserId) async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: BlockListMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _blockRepository.unblockUser(
        targetUserId: targetUserId,
        accessToken: accessToken,
      );
      final items = state.items.where((item) => item.userId != targetUserId).toList();
      state = state.copyWith(items: items, isLoading: false);
    } on BlockException catch (error) {
      if (kDebugMode) {
        debugPrint('block: 차단 해제 실패 (${error.error})');
      }
      final message = error.error == BlockError.unauthorized
          ? BlockListMessage.missingSession
          : BlockListMessage.unblockFailed;
      state = state.copyWith(isLoading: false, message: message);
    } catch (_) {
      if (kDebugMode) {
        debugPrint('block: 차단 해제 알 수 없는 오류');
      }
      state = state.copyWith(isLoading: false, message: BlockListMessage.unblockFailed);
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}
