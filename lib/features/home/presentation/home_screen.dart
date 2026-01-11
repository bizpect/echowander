import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/presentation/scaffolds/main_tab_controller.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/presentation/widgets/app_skeleton.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/application/journey_inbox_controller.dart';
import '../../journey/application/journey_list_controller.dart';
import '../../journey/presentation/journey_inbox_screen.dart';
import '../../journey/presentation/journey_list_screen.dart';
import '../application/home_dashboard_controller.dart';

/// Home 화면 (대시보드)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 홈 진입 시 요약용 데이터 확보 (중복 호출은 controller에서 가드)
    Future.microtask(() {
      ref.read(journeyListControllerProvider.notifier).load();
      ref.read(journeyInboxControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dashboard = ref.watch(homeDashboardProvider);

    final promptText = _resolveDailyPrompt(l10n, dashboard.dailyPrompt);

    return AppScaffold(
      appBar: AppHeader(
        title: l10n.homeTitle,
        alignTitleLeft: true,
      ),
      bodyPadding: EdgeInsets.zero,
      body: ListView(
        padding: AppSpacing.pagePadding.copyWith(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        children: [
          // 오늘의 인박스 섹션
          _SectionHeader(
            title: l10n.homeInboxSummaryTitle,
            subtitle: _formatUpdatedAt(l10n, dashboard.summary.lastUpdatedAt),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          _InboxSummaryCard(
            summary: dashboard.summary,
            isLoading: dashboard.isSummaryLoading,
            hasError: dashboard.hasSummaryError,
            onRefresh: _handleRefresh,
            onTapPending: () => _goToInboxTab(ReceivedTab.pending),
            onTapCompleted: () => _goToInboxTab(ReceivedTab.completed),
            onTapSentResponses: () => _goToSentTab(SentTab.completed),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 최근 활동 섹션
          _SectionHeader(title: l10n.homeTimelineTitle),
          const SizedBox(height: AppSpacing.spacing12),
          _TimelineCard(
            items: dashboard.timelineItems,
            isLoading: dashboard.isTimelineLoading,
            onTapItem: _handleTimelineTap,
          ),
          const SizedBox(height: AppSpacing.lg),
          // 오늘의 질문 섹션
          _SectionHeader(title: l10n.homeDailyPromptTitle),
          const SizedBox(height: AppSpacing.spacing12),
          _DailyPromptCard(
            question: promptText,
            hint: l10n.homeDailyPromptHint,
            actionLabel: l10n.homeDailyPromptAction,
            onTap: () => _openComposeWithPrefill(promptText),
          ),
          if (dashboard.announcement != null) ...[
            const SizedBox(height: AppSpacing.lg),
            // 업데이트 섹션
            _SectionHeader(
              title: l10n.homeAnnouncementTitle,
              subtitle: dashboard.announcement!.displayDate != null
                  ? _formatAnnouncementDate(
                      l10n,
                      dashboard.announcement!.displayDate!,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            _AnnouncementCard(
              summary: l10n.homeAnnouncementSummary,
              actionLabel: l10n.homeAnnouncementAction,
              onTap: () => _openAnnouncement(l10n),
            ),
          ],
        ],
      ),
    );
  }

  String _resolveDailyPrompt(AppLocalizations l10n, HomeDailyPrompt prompt) {
    final questions = [
      l10n.homePromptQ1,
      l10n.homePromptQ2,
      l10n.homePromptQ3,
      l10n.homePromptQ4,
      l10n.homePromptQ5,
      l10n.homePromptQ6,
      l10n.homePromptQ7,
      l10n.homePromptQ8,
      l10n.homePromptQ9,
      l10n.homePromptQ10,
    ];
    if (questions.isEmpty) {
      return '';
    }
    final index = prompt.index % questions.length;
    return questions[index];
  }

  void _handleRefresh() {
    ref.read(journeyListControllerProvider.notifier).load();
    ref.read(journeyInboxControllerProvider.notifier).load();
  }

  void _goToInboxTab(ReceivedTab tab) {
    ref.read(receivedTabProvider.notifier).setTab(tab);
    ref.read(mainTabControllerProvider.notifier).switchToInboxTab();
    context.go(AppRoutes.home);
  }

  void _goToSentTab(SentTab tab) {
    ref.read(sentTabProvider.notifier).setTab(tab);
    ref.read(mainTabControllerProvider.notifier).switchToSentTab();
    context.go(AppRoutes.home);
  }

  void _handleTimelineTap(HomeTimelineItem item) {
    if (item.inboxItem != null) {
      context.go(
        '${AppRoutes.inbox}/${item.inboxItem!.journeyId}',
        extra: item.inboxItem,
      );
      return;
    }
    if (item.sentItem != null) {
      context.go('${AppRoutes.journeyList}/${item.sentItem!.journeyId}');
    }
  }

  void _openComposeWithPrefill(String question) {
    if (question.trim().isEmpty) {
      return;
    }
    final encoded = Uri.encodeComponent(question);
    context.go('${AppRoutes.compose}?prefill=$encoded');
  }

  Future<void> _openAnnouncement(AppLocalizations l10n) async {
    await showAppAlertDialog(
      context: context,
      title: l10n.homeAnnouncementDetailTitle,
      message: l10n.homeAnnouncementDetailBody,
      confirmLabel: l10n.commonOk,
    );
  }

  String? _formatUpdatedAt(AppLocalizations l10n, DateTime? updatedAt) {
    if (updatedAt == null) {
      return null;
    }
    // 공통 포맷터 사용 (UTC/local 변환 중앙화, 재발 방지)
    // DateTime 객체이므로 formatLocalDateTime 사용
    final formatted = AnnouncementDateFormatter.formatLocalDateTime(
      updatedAt,
      l10n.localeName,
    );
    return l10n.homeInboxSummaryUpdatedAt(formatted);
  }

  String? _formatAnnouncementDate(
    AppLocalizations l10n,
    DateTime dateTime,
  ) {
    // 공통 포맷터 사용 (UTC/local 변환 중앙화, 재발 방지)
    // DateTime 객체이므로 formatLocalDateTime 사용
    return AnnouncementDateFormatter.formatLocalDateTime(
      dateTime,
      l10n.localeName,
    );
  }
}

/// 섹션 헤더 (타이틀 + 서브타이틀)
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (subtitle != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            subtitle!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
    return Text(
      title,
      style: AppTextStyles.titleSm.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InboxSummaryCard extends StatelessWidget {
  const _InboxSummaryCard({
    required this.summary,
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
    required this.onTapPending,
    required this.onTapCompleted,
    required this.onTapSentResponses,
  });

  final HomeInboxSummary summary;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRefresh;
  final VoidCallback onTapPending;
  final VoidCallback onTapCompleted;
  final VoidCallback onTapSentResponses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final showError = hasError &&
        summary.pendingCount == 0 &&
        summary.completedCount == 0 &&
        summary.sentResponseCount == 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const _InboxSummarySkeleton()
          else if (showError)
            _InboxSummaryError(
              message: l10n.homeInboxSummaryLoadFailed,
              actionLabel: l10n.homeInboxSummaryRefresh,
              onRefresh: onRefresh,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // 작은 화면에서는 Wrap으로 줄바꿈, 큰 화면에서는 Row로 가로 배치
                if (constraints.maxWidth < 300) {
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.sm * 2) / 3,
                        child: _SummaryTile(
                          label: l10n.homeInboxSummaryPending,
                          count: summary.pendingCount,
                          formattedCount:
                              numberFormat.format(summary.pendingCount),
                          onTap: onTapPending,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.sm * 2) / 3,
                        child: _SummaryTile(
                          label: l10n.homeInboxSummaryCompleted,
                          count: summary.completedCount,
                          formattedCount:
                              numberFormat.format(summary.completedCount),
                          onTap: onTapCompleted,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.sm * 2) / 3,
                        child: _SummaryTile(
                          label: l10n.homeInboxSummarySentResponses,
                          count: summary.sentResponseCount,
                          formattedCount:
                              numberFormat.format(summary.sentResponseCount),
                          onTap: onTapSentResponses,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: l10n.homeInboxSummaryPending,
                        count: summary.pendingCount,
                        formattedCount:
                            numberFormat.format(summary.pendingCount),
                        onTap: onTapPending,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _SummaryTile(
                        label: l10n.homeInboxSummaryCompleted,
                        count: summary.completedCount,
                        formattedCount:
                            numberFormat.format(summary.completedCount),
                        onTap: onTapCompleted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _SummaryTile(
                        label: l10n.homeInboxSummarySentResponses,
                        count: summary.sentResponseCount,
                        formattedCount:
                            numberFormat.format(summary.sentResponseCount),
                        onTap: onTapSentResponses,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    required this.formattedCount,
    required this.onTap,
  });

  final String label;
  final int count;
  final String formattedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.homeInboxSummaryItemSemantics(label, count),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.small,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formattedCount,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InboxSummarySkeleton extends StatelessWidget {
  const _InboxSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SummarySkeletonItem()),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _SummarySkeletonItem()),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _SummarySkeletonItem()),
      ],
    );
  }
}

class _SummarySkeletonItem extends StatelessWidget {
  const _SummarySkeletonItem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          AppSkeleton(width: 36, height: 18),
          SizedBox(height: AppSpacing.xs),
          AppSkeleton(width: 56, height: 12),
        ],
      ),
    );
  }
}

class _InboxSummaryError extends StatelessWidget {
  const _InboxSummaryError({
    required this.message,
    required this.actionLabel,
    required this.onRefresh,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: onRefresh,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.items,
    required this.isLoading,
    required this.onTapItem,
  });

  final List<HomeTimelineItem> items;
  final bool isLoading;
  final ValueChanged<HomeTimelineItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const _TimelineSkeleton()
          else if (items.isEmpty)
            Text(
              l10n.homeTimelineEmptyTitle,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _TimelineRow(
                        item: item,
                        onTap: () => onTapItem(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.skeletonBase,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 160, height: 14),
                    SizedBox(height: AppSpacing.xs),
                    AppSkeleton(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.onTap});

  final HomeTimelineItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _resolveTitle(l10n, item.type);
    final timeLabel = _formatTime(l10n, item.createdAt);

    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.small,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.homeTimelineSubtitle(timeLabel),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resolveTitle(AppLocalizations l10n, HomeTimelineType type) {
    switch (type) {
      case HomeTimelineType.inboxReceived:
        return l10n.homeTimelineReceivedTitle;
      case HomeTimelineType.inboxResponded:
        return l10n.homeTimelineRespondedTitle;
      case HomeTimelineType.sentResponseArrived:
        return l10n.homeTimelineSentResponseTitle;
    }
  }

  String _formatTime(AppLocalizations l10n, DateTime time) {
    // 공통 포맷터 사용 (UTC/local 변환 중앙화, 재발 방지)
    // 타임라인은 날짜+시간 형식 (Md + Hm)
    // DateTime 객체이므로 formatLocalDateTime 사용
    final pattern = DateFormat.Md(l10n.localeName).add_Hm();
    return AnnouncementDateFormatter.formatLocalDateTime(
      time,
      l10n.localeName,
      pattern: pattern,
    );
  }
}

class _DailyPromptCard extends StatelessWidget {
  const _DailyPromptCard({
    required this.question,
    required this.hint,
    required this.actionLabel,
    required this.onTap,
  });

  final String question;
  final String hint;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  hint,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(onPressed: onTap, child: Text(actionLabel)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.summary,
    required this.actionLabel,
    required this.onTap,
  });

  final String summary;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
