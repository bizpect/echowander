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
  const HomeAnnouncement({required this.isVisible});

  final bool isVisible;
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

  // 공지 데이터가 없으면 null로 유지 (MVP는 로컬 토글)
  const announcement = HomeAnnouncement(isVisible: true);

  return HomeDashboardState(
    summary: summary,
    isSummaryLoading: isSummaryLoading,
    hasSummaryError: hasSummaryError,
    timelineItems: timelineItems,
    isTimelineLoading: isTimelineLoading,
    dailyPrompt: dailyPrompt,
    announcement: announcement.isVisible ? announcement : null,
  );
});

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
