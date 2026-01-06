import 'dart:convert';

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
    if (kDebugMode) {
      debugPrint('[InboxTrace][Provider] build - initializing controller');
    }
    _journeyRepository = ref.read(journeyRepositoryProvider);
    return const JourneyInboxState(
      items: [],
      isLoading: false,
      message: null,
    );
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    if (kDebugMode) {
      debugPrint('[InboxTrace][Provider] load - start, limit: $limit, offset: $offset');
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Provider] load - missing accessToken');
      }
      state = state.copyWith(message: JourneyInboxMessage.missingSession);
      return;
    }
    if (kDebugMode) {
      debugPrint('[InboxTrace][Provider] load - accessToken exists (length: ${accessToken.length})');
      // accessToken 시작 부분 확인 (JWT는 eyJ로 시작해야 함)
      final tokenStart = accessToken.length > 20 ? accessToken.substring(0, 20) : accessToken;
      debugPrint('[InboxTrace][Provider] load - accessToken starts with: $tokenStart...');
      // JWT 전체 payload 출력
      try {
        final parts = accessToken.split('.');
        debugPrint('[InboxTrace][Provider] load - JWT parts count: ${parts.length}');
        if (parts.length == 3) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          debugPrint('[InboxTrace][Provider] load - JWT payload: $payload');
        } else {
          debugPrint('[InboxTrace][Provider] load - INVALID JWT: expected 3 parts, got ${parts.length}');
        }
      } catch (e) {
        debugPrint('[InboxTrace][Provider] load - JWT decode error: $e');
      }
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
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
      final items = await _journeyRepository.fetchInboxJourneys(
        limit: limit,
        offset: offset,
        accessToken: accessToken,
      );
      if (kDebugMode) {
        debugPrint('[InboxTrace][Provider] load - fetchInboxJourneys completed, items: ${items.length}');
      }
      state = state.copyWith(
        items: items,
        isLoading: false,
      );
      if (kDebugMode) {
        debugPrint('[InboxTrace][Provider] load - state updated, items: ${state.items.length}, isLoading: ${state.isLoading}');
      }
    } on JourneyInboxException catch (error) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Provider] load - JourneyInboxException: ${error.error}');
      }
      final message = error.error == JourneyInboxError.unauthorized
          ? JourneyInboxMessage.missingSession
          : JourneyInboxMessage.loadFailed;
      state = state.copyWith(
        isLoading: false,
        message: message,
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
