import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../journey/application/journey_inbox_controller.dart';
import '../../journey/application/journey_list_controller.dart';
import '../../journey/domain/journey_repository.dart';

/// 홈 대시보드용 타임라인 타입
enum HomeTimelineType {
  inboxReceived,
  inboxResponded,
  sentResponseArrived,
}

/// 홈 인박스 요약 데이터
class HomeInboxSummary {
  const HomeInboxSummary({
    required this.pendingCount,
    required this.completedCount,
    required this.sentResponseCount,
    required this.lastUpdatedAt,
  });

  final int pendingCount;
  final int completedCount;
  final int sentResponseCount;
  final DateTime? lastUpdatedAt;
}

/// 홈 타임라인 아이템
class HomeTimelineItem {
  const HomeTimelineItem({
    required this.type,
    required this.createdAt,
    this.inboxItem,
    this.sentItem,
  });

  final HomeTimelineType type;
  final DateTime createdAt;
  final JourneyInboxItem? inboxItem;
  final JourneySummary? sentItem;
}

/// 오늘의 질문 데이터
class HomeDailyPrompt {
  const HomeDailyPrompt({required this.index});

  final int index;
}

/// 공지 카드 데이터
class HomeAnnouncement {
  const HomeAnnouncement({
    required this.isVisible,
    this.updatedAt,
    this.publishedAt,
  });

  final bool isVisible;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  /// 표시용 날짜 (updatedAt 우선, 없으면 publishedAt)
  DateTime? get displayDate => updatedAt ?? publishedAt;
}

/// 홈 대시보드 합산 상태
class HomeDashboardState {
  const HomeDashboardState({
    required this.summary,
    required this.isSummaryLoading,
    required this.hasSummaryError,
    required this.timelineItems,
    required this.isTimelineLoading,
    required this.dailyPrompt,
    required this.announcement,
  });

  final HomeInboxSummary summary;
  final bool isSummaryLoading;
  final bool hasSummaryError;
  final List<HomeTimelineItem> timelineItems;
  final bool isTimelineLoading;
  final HomeDailyPrompt dailyPrompt;
  final HomeAnnouncement? announcement;
}

/// 홈 대시보드 Provider (요약/타임라인/질문/공지)
final homeDashboardProvider = Provider<HomeDashboardState>((ref) {
  final inboxState = ref.watch(journeyInboxControllerProvider);
  final sentState = ref.watch(journeyListControllerProvider);

  final pendingCount = inboxState.items
      .where((item) => item.recipientStatus != 'RESPONDED')
      .length;
  final completedCount = inboxState.items
      .where((item) => item.recipientStatus == 'RESPONDED')
      .length;
  final sentResponseCount = sentState.items
      .where((item) => item.statusCode == 'COMPLETED')
      .length;

  final lastUpdatedAt = _resolveLastUpdatedAt(
    inboxItems: inboxState.items,
    sentItems: sentState.items,
  );

  final summary = HomeInboxSummary(
    pendingCount: pendingCount,
    completedCount: completedCount,
    sentResponseCount: sentResponseCount,
    lastUpdatedAt: lastUpdatedAt,
  );

  final hasSummaryError =
      inboxState.message != null || sentState.message != null;
  final isSummaryLoading =
      (inboxState.isLoading || sentState.isLoading) &&
      inboxState.items.isEmpty &&
      sentState.items.isEmpty;

  final timelineItems = _buildTimeline(
    inboxItems: inboxState.items,
    sentItems: sentState.items,
  );
  final isTimelineLoading =
      (inboxState.isLoading || sentState.isLoading) && timelineItems.isEmpty;

  final dailyPrompt = HomeDailyPrompt(
    index: _resolvePromptIndex(DateTime.now()),
  );

  // 공지 데이터 생성/매핑
  // 우선순위: updatedAt > publishedAt > null (둘 다 없으면 subtitle 숨김)
  // 모델에는 UTC 그대로 저장, 표시 직전에만 local 변환 (AnnouncementDateFormatter 사용)
  final announcement = _buildAnnouncement();

  return HomeDashboardState(
    summary: summary,
    isSummaryLoading: isSummaryLoading,
    hasSummaryError: hasSummaryError,
    timelineItems: timelineItems,
    isTimelineLoading: isTimelineLoading,
    dailyPrompt: dailyPrompt,
    announcement: announcement?.isVisible == true ? announcement : null,
  );
});

/// 공지 데이터 생성/매핑
/// 
/// 현재: 더미 공지 (로컬 생성)
/// 향후: 서버 연동 시 서버 응답의 updated_at/published_at을 매핑
/// 
/// 규칙:
/// - updatedAt 우선, 없으면 publishedAt 사용
/// - 둘 다 없으면 null (subtitle 숨김)
/// - 모델에는 UTC 그대로 저장 (toLocal() 선변환 금지)
/// - 표시는 AnnouncementDateFormatter.formatLocalDateTime() 사용
HomeAnnouncement? _buildAnnouncement() {
  // 현재는 더미 공지 (서버 연동 전)
  // 더미 공지에 고정 날짜를 설정하여 subtitle이 표시되도록 함
  // (매번 변하지 않도록 고정 UTC 날짜 사용)
  
  // 향후 서버 연동 시 아래 주석의 로직으로 교체:
  // 
  // final serverData = ...; // 서버 응답
  // final updatedAt = serverData['updated_at'] != null
  //     ? DateTime.parse(serverData['updated_at'] as String)
  //     : null;
  // final publishedAt = serverData['published_at'] != null
  //     ? DateTime.parse(serverData['published_at'] as String)
  //     : null;
  // return HomeAnnouncement(
  //   isVisible: true,
  //   updatedAt: updatedAt,
  //   publishedAt: publishedAt,
  // );
  
  return HomeAnnouncement(
    isVisible: true,
    // 더미 공지: 고정 UTC 날짜 사용 (매번 변하지 않도록)
    // 향후 서버 연동 시 서버에서 받은 날짜로 교체
    publishedAt: DateTime.utc(2024, 1, 15, 0, 0, 0),
  );
}

int _resolvePromptIndex(DateTime now) {
  final startOfYear = DateTime(now.year, 1, 1);
  final dayOfYear = now.difference(startOfYear).inDays + 1;
  return dayOfYear % HomePromptCatalog.questionCount;
}

DateTime? _resolveLastUpdatedAt({
  required List<JourneyInboxItem> inboxItems,
  required List<JourneySummary> sentItems,
}) {
  DateTime? latest;
  for (final item in inboxItems) {
    if (latest == null || item.createdAt.isAfter(latest)) {
      latest = item.createdAt;
    }
  }
  for (final item in sentItems) {
    if (latest == null || item.createdAt.isAfter(latest)) {
      latest = item.createdAt;
    }
  }
  return latest;
}

List<HomeTimelineItem> _buildTimeline({
  required List<JourneyInboxItem> inboxItems,
  required List<JourneySummary> sentItems,
}) {
  final items = <HomeTimelineItem>[];

  for (final inbox in inboxItems) {
    final type = inbox.recipientStatus == 'RESPONDED'
        ? HomeTimelineType.inboxResponded
        : HomeTimelineType.inboxReceived;
    items.add(
      HomeTimelineItem(
        type: type,
        createdAt: inbox.createdAt,
        inboxItem: inbox,
      ),
    );
  }

  for (final sent in sentItems) {
    if (sent.statusCode != 'COMPLETED') {
      continue;
    }
    items.add(
      HomeTimelineItem(
        type: HomeTimelineType.sentResponseArrived,
        createdAt: sent.createdAt,
        sentItem: sent,
      ),
    );
  }

  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items.take(5).toList();
}

/// 오늘의 질문 목록 카탈로그
class HomePromptCatalog {
  static const int questionCount = 10;
}
