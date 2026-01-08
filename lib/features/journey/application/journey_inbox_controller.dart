import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/auth_executor.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/session/session_state.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';

enum JourneyInboxMessage {
  missingSession,
  loadFailed,
}

class JourneyInboxState {
  const JourneyInboxState({
    required this.items,
    required this.isLoading,
    this.message,
  });

  final List<JourneyInboxItem> items;
  final bool isLoading;
  final JourneyInboxMessage? message;

  JourneyInboxState copyWith({
    List<JourneyInboxItem>? items,
    bool? isLoading,
    JourneyInboxMessage? message,
    bool clearMessage = false,
  }) {
    return JourneyInboxState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final journeyInboxControllerProvider =
    NotifierProvider<JourneyInboxController, JourneyInboxState>(
  JourneyInboxController.new,
);

class JourneyInboxController extends Notifier<JourneyInboxState> {
  static const int _defaultLimit = 20;

  /// build 재호출 시 LateInitializationError 방지를 위해 getter로 접근
  JourneyRepository get _journeyRepository => ref.read(journeyRepositoryProvider);

  @override
  JourneyInboxState build() {
    if (kDebugMode) {
      debugPrint('[InboxTrace][Provider] build - initializing controller');
    }
    return const JourneyInboxState(
      items: [],
      isLoading: false,
      message: null,
    );
  }

  /// 특정 journeyId의 아이템을 리스트에서 제거 (optimistic update)
  void removeItem(String journeyId) {
    if (kDebugMode) {
      debugPrint('[InboxTrace][Provider] removeItem - journeyId: $journeyId');
    }
    final updatedItems = state.items.where((item) => item.journeyId != journeyId).toList();
    state = state.copyWith(items: updatedItems);
    if (kDebugMode) {
      debugPrint('[InboxTrace][Provider] removeItem - updated items: ${updatedItems.length}');
    }
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    // 재진입 가드: 이미 로딩 중이면 중복 호출 방지
    if (state.isLoading) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Provider] load - 이미 로딩 중, 중복 호출 무시');
      }
      return;
    }

    // ✅ 세션 상태 가드: unauthenticated 상태에서는 fetch 호출 금지
    final sessionState = ref.read(sessionManagerProvider);
    if (sessionState.status != SessionStatus.authenticated) {
      if (kDebugMode) {
        debugPrint(
          '[InboxTrace][Provider] load - 세션 상태 가드: status=${sessionState.status}, '
          'fetch 호출 차단',
        );
      }
      state = state.copyWith(
        isLoading: false,
        message: JourneyInboxMessage.missingSession,
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('[InboxTrace][Provider] load - start, limit: $limit, offset: $offset');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);

    try {
      final executor = AuthExecutor(ref);
      final result = await executor.execute<List<JourneyInboxItem>>(
        operation: (accessToken) async {
          if (kDebugMode) {
            debugPrint(
                '[InboxTrace][Provider] load - accessToken exists (length: ${accessToken.length})');
            // accessToken 시작 부분 확인 (JWT는 eyJ로 시작해야 함)
            final tokenStart =
                accessToken.length > 20 ? accessToken.substring(0, 20) : accessToken;
            debugPrint('[InboxTrace][Provider] load - accessToken starts with: $tokenStart...');
            // JWT 전체 payload 출력
            try {
              final parts = accessToken.split('.');
              debugPrint('[InboxTrace][Provider] load - JWT parts count: ${parts.length}');
              if (parts.length == 3) {
                final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
                debugPrint('[InboxTrace][Provider] load - JWT payload: $payload');
              } else {
                debugPrint(
                    '[InboxTrace][Provider] load - INVALID JWT: expected 3 parts, got ${parts.length}');
              }
            } catch (e) {
              debugPrint('[InboxTrace][Provider] load - JWT decode error: $e');
            }
          }
          // 디버그: auth.uid() 값 확인
          if (kDebugMode) {
            try {
              final debugResult = await _journeyRepository.debugAuth(accessToken: accessToken);
              debugPrint('[InboxTrace][Provider] load - debug_auth result: $debugResult');
            } catch (e) {
              debugPrint('[InboxTrace][Provider] load - debug_auth error: $e');
            }
            debugPrint('[InboxTrace][Provider] load - calling fetchInboxJourneys');
          }
          return _journeyRepository.fetchInboxJourneys(
            limit: limit,
            offset: offset,
            accessToken: accessToken,
          );
        },
        isUnauthorized: (error) =>
            error is JourneyInboxException && error.error == JourneyInboxError.unauthorized,
      );

      switch (result) {
        case AuthExecutorSuccess<List<JourneyInboxItem>>(:final data):
          if (kDebugMode) {
            debugPrint(
                '[InboxTrace][Provider] load - fetchInboxJourneys completed, items: ${data.length}');
          }
          state = state.copyWith(
            items: data,
            isLoading: false,
          );
          if (kDebugMode) {
            debugPrint(
                '[InboxTrace][Provider] load - state updated, items: ${state.items.length}, isLoading: ${state.isLoading}');
          }
        case AuthExecutorNoSession<List<JourneyInboxItem>>():
          if (kDebugMode) {
            debugPrint('[InboxTrace][Provider] load - missing accessToken');
          }
          state = state.copyWith(
            isLoading: false,
            message: JourneyInboxMessage.missingSession,
          );
        case AuthExecutorUnauthorized<List<JourneyInboxItem>>():
          if (kDebugMode) {
            debugPrint('[InboxTrace][Provider] load - unauthorized after retry');
          }
          state = state.copyWith(
            isLoading: false,
            message: JourneyInboxMessage.missingSession,
          );
        case AuthExecutorTransientError<List<JourneyInboxItem>>():
          // 일시 장애: 네트워크/서버 문제 (로그아웃 아님)
          if (kDebugMode) {
            debugPrint('[InboxTrace][Provider] load - transient error (network/server)');
          }
          state = state.copyWith(
            isLoading: false,
            message: JourneyInboxMessage.loadFailed,
          );
      }
    } on JourneyInboxException catch (error) {
      // 네트워크 오류 등 401이 아닌 예외
      if (kDebugMode) {
        debugPrint('[InboxTrace][Provider] load - JourneyInboxException: ${error.error}');
      }
      state = state.copyWith(
        isLoading: false,
        message: JourneyInboxMessage.loadFailed,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Provider] load - unknown error: $error');
      }
      state = state.copyWith(
        isLoading: false,
        message: JourneyInboxMessage.loadFailed,
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}
