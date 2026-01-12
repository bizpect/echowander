import 'sent_journey_detail.dart';
import 'sent_journey_response.dart';

class JourneyCreationResult {
  JourneyCreationResult({
    required this.journeyId,
    required this.createdAt,
    this.moderationStatus,
    this.contentClean,
  });

  final String journeyId;
  final DateTime createdAt;
  final String? moderationStatus;
  final String? contentClean;
}

enum JourneyCreationError {
  missingConfig,
  unauthorized,
  emptyContent,
  contentTooLong,
  missingLanguage,
  tooManyImages,
  containsForbidden,
  invalidRecipientCount,
  missingCodeValue,
  invalidPayload,
  contentBlocked, // moderation BLOCK
  serverRejected,
  network,
  unknown,
}

class JourneyCreationException implements Exception {
  JourneyCreationException(this.error);

  final JourneyCreationError error;
}

class JourneySummary {
  JourneySummary({
    required this.journeyId,
    required this.content,
    required this.createdAt,
    required this.imageCount,
    required this.statusCode,
    required this.filterCode,
    required this.isRewardUnlocked,
    this.contentClean,
  });

  final String journeyId;
  final String content;
  final DateTime createdAt;
  final int imageCount;
  final String statusCode;
  final String filterCode;
  final bool isRewardUnlocked;
  final String? contentClean; // 마스킹된 텍스트 (MASK인 경우)
  
  // 화면 표시용 텍스트 (content_clean이 있으면 우선 사용)
  String get displayContent => contentClean ?? content;
}

enum JourneyListError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class JourneyListException implements Exception {
  JourneyListException(this.error);

  final JourneyListError error;
}

class JourneyInboxItem {
  JourneyInboxItem({
    required this.recipientId,
    required this.journeyId,
    required this.senderUserId,
    required this.content,
    required this.createdAt,
    required this.imageCount,
    required this.recipientStatus,
    this.contentClean,
  });

  final int recipientId; // journey_recipients.id (PK)
  final String journeyId;
  final String senderUserId;
  final String content;
  final DateTime createdAt;
  final int imageCount;
  final String recipientStatus;
  final String? contentClean; // 마스킹된 텍스트 (MASK인 경우)
  
  // 화면 표시용 텍스트 (content_clean이 있으면 우선 사용)
  String get displayContent => contentClean ?? content;
}

class JourneyProgress {
  JourneyProgress({
    required this.journeyId,
    required this.statusCode,
    required this.responseTarget,
    required this.respondedCount,
    required this.assignedCount,
    required this.passedCount,
    required this.reportedCount,
    required this.relayDeadlineAt,
    required this.countryCodes,
  });

  final String journeyId;
  final String statusCode;
  final int responseTarget;
  final int respondedCount;
  final int assignedCount;
  final int passedCount;
  final int reportedCount;
  final DateTime relayDeadlineAt;
  final List<String> countryCodes;
}

class JourneyReplyItem {
  JourneyReplyItem({
    required this.responseId,
    required this.content,
    required this.createdAt,
    required this.responderNickname,
    this.contentClean,
  });

  final int responseId;
  final String content;
  final DateTime createdAt;
  final String? responderNickname;
  final String? contentClean; // 마스킹된 텍스트 (MASK인 경우)
  
  // 화면 표시용 텍스트 (content_clean이 있으면 우선 사용)
  String get displayContent => contentClean ?? content;
}

enum JourneyInboxError {
  missingConfig,
  unauthorized,
  forbidden, // 권한 거부 (403, 42501) - 권한/정책 문제, refresh로 해결 불가
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class JourneyInboxException implements Exception {
  JourneyInboxException(this.error);

  final JourneyInboxError error;
}

enum JourneyActionError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  alreadyReported,
  unknown,
}

class JourneyActionException implements Exception {
  JourneyActionException(this.error);

  final JourneyActionError error;
}

enum JourneyProgressError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class JourneyProgressException implements Exception {
  JourneyProgressException(this.error);

  final JourneyProgressError error;
}

enum JourneyReplyError {
  missingConfig,
  unauthorized,
  invalidPayload,
  unexpectedEmpty,
  contentBlocked, // moderation BLOCK
  serverRejected,
  network,
  unknown,
}

class JourneyReplyException implements Exception {
  JourneyReplyException(this.error);

  final JourneyReplyError error;
}

enum JourneyReplyReportError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class JourneyReplyReportException implements Exception {
  JourneyReplyReportException(this.error);

  final JourneyReplyReportError error;
}

abstract class JourneyRepository {
  Future<JourneyCreationResult> createJourney({
    required String content,
    required String languageTag,
    required List<String> imagePaths,
    required int recipientCount,
    required String accessToken,
  });

  Future<void> dispatchJourneyMatch({
    required String journeyId,
    required String accessToken,
  });

  Future<List<JourneySummary>> fetchJourneys({
    required int limit,
    required int offset,
    required String accessToken,
  });

  Future<List<JourneyInboxItem>> fetchInboxJourneys({
    required int limit,
    required int offset,
    required String accessToken,
  });

  /// 디버그용: auth.uid() 값 확인
  Future<String> debugAuth({required String accessToken});

  /// 디버그용: Storage 객체 존재 여부 확인 (kDebugMode에서만 호출)
  /// 
  /// [bucket] Storage 버킷 ID
  /// [paths] 확인할 경로 리스트
  /// [accessToken] 액세스 토큰
  /// 
  /// 반환: 각 path별 exists, found_name, bucket_id 정보
  Future<List<Map<String, dynamic>>> debugCheckStorageObjects({
    required String bucket,
    required List<String> paths,
    required String accessToken,
  });

  Future<List<String>> fetchInboxJourneyImageUrls({
    required String journeyId,
    required String accessToken,
  });

  /// 받은 메시지의 이미지 objectPath 리스트 조회
  ///
  /// [journeyId] Journey ID
  /// [accessToken] 액세스 토큰
  ///
  /// 반환: objectPath 리스트 (storage_path)
  Future<List<String>> fetchInboxJourneyImagePaths({
    required String journeyId,
    required String accessToken,
  });

  /// Storage objectPath 리스트를 signedUrl 리스트로 변환
  ///
  /// [bucketId] Storage 버킷 ID
  /// [paths] objectPath 리스트
  /// [accessToken] 액세스 토큰
  ///
  /// 반환: signedUrl 리스트 (실패한 항목은 제외)
  Future<List<String>> createSignedUrls({
    required String bucketId,
    required List<String> paths,
    required String accessToken,
  });

  Future<void> respondJourney({
    required String journeyId,
    required String content,
    required String accessToken,
  });

  Future<void> passJourney({
    required String journeyId,
    required String accessToken,
  });

  Future<void> blockSenderAndPass({
    required int recipientId,
    String? reasonCode,
    required String accessToken,
    String? reqId,
  });

  Future<void> reportJourney({
    required String journeyId,
    required String reasonCode,
    required String accessToken,
  });

  Future<JourneyProgress> fetchJourneyProgress({
    required String journeyId,
    required String accessToken,
  });

  Future<List<JourneyReplyItem>> fetchJourneyReplies({
    required String journeyId,
    required String accessToken,
  });

  Future<SentJourneyDetail> fetchSentJourneyDetail({
    required String journeyId,
    required String accessToken,
  });

  Future<List<SentJourneyResponse>> fetchSentJourneyResponses({
    required String journeyId,
    required int limit,
    required int offset,
    required String accessToken,
  });

  Future<void> reportJourneyResponse({
    required int responseId,
    required String reasonCode,
    required String accessToken,
  });
}
