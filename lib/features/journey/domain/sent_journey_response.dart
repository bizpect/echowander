class SentJourneyResponse {
  SentJourneyResponse({
    required this.responseId,
    required this.content,
    required this.createdAt,
    required this.responderNickname,
  });

  final int responseId;
  final String content;
  final DateTime createdAt;
  final String responderNickname;
}
