import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_manager.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';

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

  late final JourneyRepository _journeyRepository;

  @override
  JourneyListState build() {
    _journeyRepository = ref.read(journeyRepositoryProvider);
    return const JourneyListState(
      items: [],
      isLoading: false,
      message: null,
    );
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: JourneyListMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final items = await _journeyRepository.fetchJourneys(
        limit: limit,
        offset: offset,
        accessToken: accessToken,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } on JourneyListException catch (error) {
      if (kDebugMode) {
        debugPrint('journeys: 목록 로드 실패 (${error.error})');
      }
      final message = error.error == JourneyListError.unauthorized
          ? JourneyListMessage.missingSession
          : JourneyListMessage.loadFailed;
      state = state.copyWith(
        isLoading: false,
        message: message,
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('journeys: 목록 로드 알 수 없는 오류');
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
