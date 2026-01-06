class JourneyCreationResult {
  JourneyCreationResult({
    required this.journeyId,
    required this.createdAt,
  });

  final String journeyId;
  final DateTime createdAt;
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
  });

  final String journeyId;
  final String content;
  final DateTime createdAt;
  final int imageCount;
  final String statusCode;
  final String filterCode;
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
    required this.journeyId,
    required this.senderUserId,
    required this.content,
    required this.createdAt,
    required this.imageCount,
    required this.recipientStatus,
  });

  final String journeyId;
  final String senderUserId;
  final String content;
  final DateTime createdAt;
  final int imageCount;
  final String recipientStatus;
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

class JourneyResultItem {
  JourneyResultItem({
    required this.responseId,
    required this.content,
    required this.createdAt,
  });

  final int responseId;
  final String content;
  final DateTime createdAt;
}

enum JourneyInboxError {
  missingConfig,
  unauthorized,
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

enum JourneyResultError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class JourneyResultException implements Exception {
  JourneyResultException(this.error);

  final JourneyResultError error;
}

enum JourneyResultReportError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class JourneyResultReportException implements Exception {
  JourneyResultReportException(this.error);

  final JourneyResultReportError error;
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
  Future<String> debugAuth({
    required String accessToken,
  });

  Future<List<String>> fetchInboxJourneyImageUrls({
    required String journeyId,
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

  Future<void> reportJourney({
    required String journeyId,
    required String reasonCode,
    required String accessToken,
  });

  Future<JourneyProgress> fetchJourneyProgress({
    required String journeyId,
    required String accessToken,
  });

  Future<List<JourneyResultItem>> fetchJourneyResults({
    required String journeyId,
    required String accessToken,
  });

  Future<void> reportJourneyResponse({
    required int responseId,
    required String reasonCode,
    required String accessToken,
  });
}
