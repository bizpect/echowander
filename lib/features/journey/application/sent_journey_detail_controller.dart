import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';
import '../domain/sent_journey_detail.dart';
import '../domain/sent_journey_response.dart';

class SentJourneyDetailState {
  const SentJourneyDetailState({
    required this.detail,
    required this.responses,
    required this.isLoading,
    required this.loadFailed,
    required this.responsesLoadFailed,
    required this.responsesMissing,
  });

  final SentJourneyDetail? detail;
  final List<SentJourneyResponse> responses;
  final bool isLoading;
  final bool loadFailed;
  final bool responsesLoadFailed;
  final bool responsesMissing;

  SentJourneyDetailState copyWith({
    SentJourneyDetail? detail,
    List<SentJourneyResponse>? responses,
    bool? isLoading,
    bool? loadFailed,
    bool? responsesLoadFailed,
    bool? responsesMissing,
  }) {
    return SentJourneyDetailState(
      detail: detail ?? this.detail,
      responses: responses ?? this.responses,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      responsesLoadFailed: responsesLoadFailed ?? this.responsesLoadFailed,
      responsesMissing: responsesMissing ?? this.responsesMissing,
    );
  }
}

final sentJourneyDetailControllerProvider =
    NotifierProvider<SentJourneyDetailController, SentJourneyDetailState>(
  SentJourneyDetailController.new,
);

class SentJourneyDetailController extends Notifier<SentJourneyDetailState> {
  JourneyRepository get _journeyRepository => ref.read(journeyRepositoryProvider);

  @override
  SentJourneyDetailState build() {
    return const SentJourneyDetailState(
      detail: null,
      responses: [],
      isLoading: false,
      loadFailed: false,
      responsesLoadFailed: false,
      responsesMissing: false,
    );
  }

  Future<void> load({
    required String journeyId,
    required String accessToken,
    required String reqId,
  }) async {
    if (state.isLoading) {
      return;
    }
    state = state.copyWith(
      isLoading: true,
      loadFailed: false,
      responsesLoadFailed: false,
      responsesMissing: false,
    );
    if (kDebugMode) {
      debugPrint('[SentDetail] load reqId=$reqId journeyId=$journeyId');
    }

    try {
      final detail = await _journeyRepository.fetchSentJourneyDetail(
        journeyId: journeyId,
        accessToken: accessToken,
      );
      if (kDebugMode) {
        debugPrint('[SentDetail] rpc=get_sent_journey_detail reqId=$reqId status=ok');
      }

      var responses = <SentJourneyResponse>[];
      var responsesFailed = false;
      var responsesMissing = false;
      final canLoadResponses =
          detail.statusCode == 'COMPLETED' && detail.isRewardUnlocked;
      if (canLoadResponses) {
        try {
          responses = await _journeyRepository.fetchSentJourneyResponses(
            journeyId: journeyId,
            limit: 50,
            offset: 0,
            accessToken: accessToken,
          );
          if (kDebugMode) {
            debugPrint(
              '[SentDetail] responses rpc=list_sent_journey_responses reqId=$reqId count=${responses.length}',
            );
          }
        } on JourneyReplyException catch (error) {
          if (error.error == JourneyReplyError.unexpectedEmpty) {
            responsesMissing = true;
            if (kDebugMode) {
              debugPrint(
                '[SentDetail] responses missing reqId=$reqId journeyId=$journeyId',
              );
            }
          } else {
            responsesFailed = true;
          }
        } catch (_) {
          responsesFailed = true;
        }
      }

      state = state.copyWith(
        detail: detail,
        responses: responses,
        isLoading: false,
        responsesLoadFailed: responsesFailed,
        responsesMissing: responsesMissing,
      );
    } on JourneyProgressException {
      state = state.copyWith(
        isLoading: false,
        loadFailed: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadFailed: true,
      );
    }
  }

  void setUnlockState({
    required String journeyId,
    required String reqId,
  }) {
    final detail = state.detail;
    if (detail == null || detail.journeyId != journeyId) {
      return;
    }
    state = state.copyWith(
      detail: SentJourneyDetail(
        journeyId: detail.journeyId,
        content: detail.content,
        createdAt: detail.createdAt,
        statusCode: detail.statusCode,
        responseCount: detail.responseCount,
        imageCount: detail.imageCount,
        isRewardUnlocked: true,
      ),
    );
    if (kDebugMode) {
      debugPrint('[Provider] unlock_set reqId=$reqId journeyId=$journeyId unlocked=true');
    }
  }
}
