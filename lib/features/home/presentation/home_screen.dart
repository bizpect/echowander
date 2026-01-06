import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/presentation/widgets/empty_state.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/application/journey_list_controller.dart';
import '../../journey/application/journey_inbox_controller.dart';

/// Home 화면
///
/// 앱의 진입점으로 다음을 제공:
/// - 최근 보낸 Journey 요약 카드
/// - Inbox/Create 주요 액션 카드
/// - 빈 상태 안내
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 데이터 초기 로드
    Future.microtask(() {
      ref.read(journeyListControllerProvider.notifier).load(limit: 3);
      ref.read(journeyInboxControllerProvider.notifier).load(limit: 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final journeyListState = ref.watch(journeyListControllerProvider);
    final inboxState = ref.watch(journeyInboxControllerProvider);

    final isLoading = journeyListState.isLoading || inboxState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.homeRefresh,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              children: [
                // 최근 보낸 Journey 섹션
                _RecentJourneysSection(
                  items: journeyListState.items,
                  hasError: journeyListState.message != null,
                  onRetry: _handleRefresh,
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // 주요 액션 섹션
                Text(
                  l10n.homeActionsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.spacing12),

                // Inbox 액션 카드
                _ActionCard(
                  icon: Icons.inbox,
                  title: l10n.homeInboxCardTitle,
                  description: l10n.homeInboxCardDescription,
                  badgeCount: inboxState.items.length,
                  onTap: () => context.go(AppRoutes.inbox),
                  isPrimary: false,
                ),
                const SizedBox(height: AppSpacing.spacing12),

                // Create 액션 카드
                _ActionCard(
                  icon: Icons.edit,
                  title: l10n.homeCreateCardTitle,
                  description: l10n.homeCreateCardDescription,
                  onTap: () => context.go(AppRoutes.compose),
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(journeyListControllerProvider.notifier).load(limit: 3),
      ref.read(journeyInboxControllerProvider.notifier).load(limit: 20),
    ]);
  }
}

/// 최근 보낸 Journey 섹션
class _RecentJourneysSection extends StatelessWidget {
  const _RecentJourneysSection({
    required this.items,
    required this.hasError,
    required this.onRetry,
  });

  final List<dynamic> items;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 에러 상태
    if (hasError) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: l10n.homeLoadFailed,
        actionLabel: l10n.homeRefresh,
        onAction: onRetry,
      );
    }

    // 빈 상태
    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.explore_outlined,
        title: l10n.homeEmptyTitle,
        description: l10n.homeEmptyDescription,
      );
    }

    // 최근 Journey 카드 표시
    final recentJourney = items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeRecentJourneysTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _JourneyCard(journey: recentJourney),
      ],
    );
  }
}

/// Journey 요약 카드
class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.journey});

  final dynamic journey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    // statusCode에 따른 라벨 매핑
    final statusLabel = _getStatusLabel(l10n, journey.statusCode);

    return Card(
      child: InkWell(
        onTap: () => context.go('${AppRoutes.journeyList}/${journey.journeyId}'),
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메시지 내용
              Text(
                journey.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurface,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.spacing8),

              // 상태 및 날짜
              Row(
                children: [
                  // 상태 칩
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing8,
                      vertical: AppSpacing.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppRadius.small,
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing8),

                  // 날짜
                  Expanded(
                    child: Text(
                      dateFormat.format(journey.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ),

                  // 자세히 보기 아이콘
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(AppLocalizations l10n, String statusCode) {
    switch (statusCode) {
      case 'CREATED':
        return l10n.journeyStatusCreated;
      case 'WAITING':
        return l10n.journeyStatusWaiting;
      case 'COMPLETED':
        return l10n.journeyStatusCompleted;
      default:
        return l10n.journeyStatusUnknown;
    }
  }
}

/// 액션 카드 (Inbox / Create)
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badgeCount = 0,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final int badgeCount;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: isPrimary ? 2 : 1,
      color: isPrimary ? AppColors.primaryContainer : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPrimary ? AppColors.primary : AppColors.primaryContainer,
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? AppColors.onPrimary : AppColors.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing16),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isPrimary ? AppColors.onPrimaryContainer : AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (badgeCount > 0) ...[
                          const SizedBox(width: AppSpacing.spacing8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacing8,
                              vertical: AppSpacing.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.homeInboxCount(badgeCount),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.onError,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isPrimary ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // 화살표 아이콘
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isPrimary ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
