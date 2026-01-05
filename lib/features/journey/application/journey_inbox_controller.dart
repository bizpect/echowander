import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_manager.dart';
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

  late final JourneyRepository _journeyRepository;

  @override
  JourneyInboxState build() {
    _journeyRepository = ref.read(journeyRepositoryProvider);
    return const JourneyInboxState(
      items: [],
      isLoading: false,
      message: null,
    );
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: JourneyInboxMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final items = await _journeyRepository.fetchInboxJourneys(
        limit: limit,
        offset: offset,
        accessToken: accessToken,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } on JourneyInboxException catch (error) {
      if (kDebugMode) {
        debugPrint('inbox: 목록 로드 실패 (${error.error})');
      }
      final message = error.error == JourneyInboxError.unauthorized
          ? JourneyInboxMessage.missingSession
          : JourneyInboxMessage.loadFailed;
      state = state.copyWith(
        isLoading: false,
        message: message,
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('inbox: 목록 로드 알 수 없는 오류');
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
