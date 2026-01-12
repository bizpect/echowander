class SentJourneyResponse {
  SentJourneyResponse({
    required this.responseId,
    required this.content,
    required this.createdAt,
    required this.responderNickname,
    this.contentClean,
  });

  final int responseId;
  final String content;
  final DateTime createdAt;
  final String responderNickname;
  final String? contentClean; // 마스킹된 텍스트 (MASK인 경우)
  
  // 화면 표시용 텍스트 (content_clean이 있으면 우선 사용)
  String get displayContent => contentClean ?? content;
}
