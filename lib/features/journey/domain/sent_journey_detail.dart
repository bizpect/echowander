class SentJourneyDetail {
  SentJourneyDetail({
    required this.journeyId,
    required this.content,
    required this.createdAt,
    required this.statusCode,
    required this.responseCount,
    required this.imageCount,
    required this.isRewardUnlocked,
    this.contentClean,
  });

  final String journeyId;
  final String content;
  final DateTime createdAt;
  final String statusCode;
  final int responseCount;
  final int imageCount;
  final bool isRewardUnlocked;
  final String? contentClean; // 마스킹된 텍스트 (MASK인 경우)
  
  // 화면 표시용 텍스트 (content_clean이 있으면 우선 사용)
  String get displayContent => contentClean ?? content;
}
