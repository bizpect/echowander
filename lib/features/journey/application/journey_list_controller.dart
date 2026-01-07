import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/auth_executor.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';

const _logPrefix = '[JourneyList]';

enum JourneyListMessage {
  missingSession,
  loadFailed,
}

class JourneyListState {
  const JourneyListState({
    required this.items,
    required this.isLoading,
    this.message,
  });

  final List<JourneySummary> items;
  final bool isLoading;
  final JourneyListMessage? message;

  JourneyListState copyWith({
    List<JourneySummary>? items,
    bool? isLoading,
    JourneyListMessage? message,
    bool clearMessage = false,
  }) {
    return JourneyListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final journeyListControllerProvider =
    NotifierProvider<JourneyListController, JourneyListState>(
  JourneyListController.new,
);

class JourneyListController extends Notifier<JourneyListState> {
  static const int _defaultLimit = 20;

  /// build 재호출 시 LateInitializationError 방지를 위해 getter로 접근
  JourneyRepository get _journeyRepository => ref.read(journeyRepositoryProvider);

  @override
  JourneyListState build() {
    return const JourneyListState(
      items: [],
      isLoading: false,
      message: null,
    );
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    // 재진입 가드: 이미 로딩 중이면 중복 호출 방지
    if (state.isLoading) {
      if (kDebugMode) {
        debugPrint('$_logPrefix load - 이미 로딩 중, 중복 호출 무시');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('$_logPrefix load - start, limit: $limit, offset: $offset');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);

    try {
      final executor = AuthExecutor(ref);
      final result = await executor.execute<List<JourneySummary>>(
        operation: (accessToken) => _journeyRepository.fetchJourneys(
          limit: limit,
          offset: offset,
          accessToken: accessToken,
        ),
        isUnauthorized: (error) =>
            error is JourneyListException && error.error == JourneyListError.unauthorized,
      );

      switch (result) {
        case AuthExecutorSuccess<List<JourneySummary>>(:final data):
          if (kDebugMode) {
            debugPrint('$_logPrefix load - completed, items: ${data.length}');
          }
          state = state.copyWith(
            items: data,
            isLoading: false,
          );
        case AuthExecutorNoSession<List<JourneySummary>>():
          if (kDebugMode) {
            debugPrint('$_logPrefix load - missing accessToken');
          }
          state = state.copyWith(
            isLoading: false,
            message: JourneyListMessage.missingSession,
          );
        case AuthExecutorUnauthorized<List<JourneySummary>>():
          if (kDebugMode) {
            debugPrint('$_logPrefix load - unauthorized after retry');
          }
          state = state.copyWith(
            isLoading: false,
            message: JourneyListMessage.missingSession,
          );
        case AuthExecutorTransientError<List<JourneySummary>>():
          // 일시 장애: 네트워크/서버 문제 (로그아웃 아님)
          if (kDebugMode) {
            debugPrint('$_logPrefix load - transient error (network/server)');
          }
          state = state.copyWith(
            isLoading: false,
            message: JourneyListMessage.loadFailed,
          );
      }
    } on JourneyListException catch (error) {
      // 네트워크 오류 등 401이 아닌 예외
      if (kDebugMode) {
        debugPrint('$_logPrefix load - JourneyListException: ${error.error}');
      }
      state = state.copyWith(
        isLoading: false,
        message: JourneyListMessage.loadFailed,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix load - unknown error: $error');
      }
      state = state.copyWith(
        isLoading: false,
        message: JourneyListMessage.loadFailed,
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}
