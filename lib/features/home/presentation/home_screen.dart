import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/presentation/scaffolds/main_tab_controller.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_empty_state.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_icon_badge.dart';
import '../../../core/presentation/widgets/app_pill.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    // 2개 카드를 위한 애니메이션 컨트롤러 생성 (최근 Journey, Inbox)
    _controllers = List.generate(
      2,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    // Fade 애니메이션
    _fadeAnimations = _controllers
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.easeOut),
        )
        .toList();

    // Slide Up 애니메이션
    _slideAnimations = _controllers
        .map(
          (controller) => Tween<Offset>(
            begin: const Offset(0, 0.1), // 약간 아래에서 시작
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
        )
        .toList();

    // Staggered 애니메이션 시작 (50ms 간격)
    Future.microtask(() {
      for (var i = 0; i < _controllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          if (mounted) {
            _controllers[i].forward();
          }
        });
      }
    });

    // 데이터 초기 로드
    // 홈 화면에서는 보낸 메시지 리스트를 limit: 3으로 프리뷰만 로드
    // 단, 이미 20개 이상 로드되어 있으면 로드하지 않음 (탭 리스트에서 로드한 경우)
    Future.microtask(() {
      final journeyListState = ref.read(journeyListControllerProvider);
      // 리스트가 비어있거나 3개 이하일 때만 limit: 3으로 로드
      // 이미 20개 이상 로드되어 있으면 탭 리스트에서 로드한 것이므로 건드리지 않음
      if (journeyListState.items.isEmpty ||
          journeyListState.items.length <= 3) {
        ref.read(journeyListControllerProvider.notifier).load(limit: 3);
      }
      // 받은 메시지는 항상 limit: 20으로 로드 (홈 화면에서도 전체 목록 필요)
      ref.read(journeyInboxControllerProvider.notifier).load(limit: 20);
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final journeyListState = ref.watch(journeyListControllerProvider);
    final inboxState = ref.watch(journeyInboxControllerProvider);

    final isLoading = journeyListState.isLoading || inboxState.isLoading;

    return AppScaffold(
      appBar: AppHeader(
        title: l10n.homeTitle,
        alignTitleLeft: true,
      ),
      bodyPadding: EdgeInsets.zero,
      body: LoadingOverlay(
        isLoading: isLoading,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 컨텐츠 영역 (정보 밀도 높게)
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 최근 보낸 Journey 섹션 (애니메이션 index 0)
                  _buildAnimatedCard(
                    index: 0,
                    child: _RecentJourneysSection(
                      items: journeyListState.items,
                      hasError: journeyListState.message != null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Inbox 액션 카드 (애니메이션 index 1)
                  _buildAnimatedCard(
                    index: 1,
                    child: _ActionCard(
                      icon: Icons.inbox,
                      title: l10n.homeInboxCardTitle,
                      description: l10n.homeInboxCardDescription,
                      badgeCount: inboxState.items.length,
                      onTap: () {
                        // 받은 메시지 탭으로 이동
                        ref
                            .read(mainTabControllerProvider.notifier)
                            .switchToInboxTab();
                        context.go(AppRoutes.home);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Staggered 애니메이션이 적용된 카드 래퍼
  Widget _buildAnimatedCard({required int index, required Widget child}) {
    if (index >= _controllers.length) {
      return child; // 범위 초과 시 애니메이션 없이 반환
    }

    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
    );
  }
}

/// 최근 보낸 Journey 섹션
class _RecentJourneysSection extends StatelessWidget {
  const _RecentJourneysSection({required this.items, required this.hasError});

  final List<dynamic> items;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 에러 상태 (새로고침 버튼 제거)
    if (hasError) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: l10n.homeLoadFailed,
      );
    }

    // 빈 상태
    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.explore_outlined,
        title: l10n.homeEmptyTitle,
        description: l10n.homeEmptyDescription,
      );
    }

    // 최근 Journey 카드 표시
    final recentJourney = items.first;

    return _JourneyCard(journey: recentJourney);
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

    return AppCard(
      onTap: () => context.go('${AppRoutes.journeyList}/${journey.journeyId}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            journey.content,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppPill(
                label: statusLabel,
                tone: journey.statusCode == 'COMPLETED'
                    ? AppPillTone.success
                    : AppPillTone.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  dateFormat.format(journey.createdAt.toLocal()),
                  style: AppTextStyles.meta.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.iconMuted,
              ),
            ],
          ),
        ],
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

/// 액션 카드 (Inbox)
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AppIconBadge(
            icon: icon,
            backgroundColor: AppColors.primaryContainer,
            iconColor: AppColors.onPrimaryContainer,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeCount > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppPill(
                        label: l10n.homeInboxCount(badgeCount),
                        tone: AppPillTone.danger,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.iconMuted),
        ],
      ),
    );
  }
}
