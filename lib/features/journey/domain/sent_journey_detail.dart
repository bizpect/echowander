class SentJourneyDetail {
  SentJourneyDetail({
    required this.journeyId,
    required this.content,
    required this.createdAt,
    required this.statusCode,
    required this.responseCount,
    required this.imageCount,
    required this.isRewardUnlocked,
  });

  final String journeyId;
  final String content;
  final DateTime createdAt;
  final String statusCode;
  final int responseCount;
  final int imageCount;
  final bool isRewardUnlocked;
}
