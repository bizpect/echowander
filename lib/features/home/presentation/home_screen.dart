import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_typography.dart';
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
        .map((controller) => CurvedAnimation(
              parent: controller,
              curve: Curves.easeOut,
            ))
        .toList();

    // Slide Up 애니메이션
    _slideAnimations = _controllers
        .map((controller) => Tween<Offset>(
              begin: const Offset(0, 0.1), // 약간 아래에서 시작
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeOut,
            )))
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
    Future.microtask(() {
      ref.read(journeyListControllerProvider.notifier).load(limit: 3);
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

    return Scaffold(
      backgroundColor: AppColors.black,
      // AppBar 제거, 상단 헤더는 body 내부에 얇게 배치
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 상단 헤더 (얇고 밀도 높은 헤더)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingHorizontal,
                  AppSpacing.screenPaddingTop,
                  AppSpacing.screenPaddingHorizontal,
                  AppSpacing.spacing16,
                ),
                child: Text(
                  l10n.homeTitle,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              // 컨텐츠 영역 (정보 밀도 높게)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingHorizontal,
                ),
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
                    const SizedBox(height: AppSpacing.spacing16),

                    // Inbox 액션 카드 (애니메이션 index 1)
                    _buildAnimatedCard(
                      index: 1,
                      child: _ActionCard(
                        icon: Icons.inbox,
                        title: l10n.homeInboxCardTitle,
                        description: l10n.homeInboxCardDescription,
                        badgeCount: inboxState.items.length,
                        onTap: () => context.go(AppRoutes.inbox),
                      ),
                    ),
                    // 하단 여백 (FAB 공간 확보)
                    SizedBox(height: AppSpacing.screenPaddingBottom + 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // 작성 버튼: 독립적으로 떠 있는 FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.compose),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.edit),
        label: Text(l10n.homeCreateCardTitle),
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
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }
}

/// 최근 보낸 Journey 섹션
class _RecentJourneysSection extends StatelessWidget {
  const _RecentJourneysSection({
    required this.items,
    required this.hasError,
  });

  final List<dynamic> items;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 에러 상태 (새로고침 버튼 제거)
    if (hasError) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: l10n.homeLoadFailed,
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
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.onSurface,
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
      color: AppColors.surface,
      child: InkWell(
        onTap: () => context.go('${AppRoutes.journeyList}/${journey.journeyId}'),
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메시지 내용 (정보 밀도 높게: maxLines 증가)
              Text(
                journey.content,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.spacing12),

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
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing8),

                  // 날짜
                  Expanded(
                    child: Text(
                      dateFormat.format(journey.createdAt.toLocal()),
                      style: AppTypography.bodySmall.copyWith(
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

    return Card(
      color: AppColors.surface,
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
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  icon,
                  color: AppColors.onPrimaryContainer,
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
                        Flexible(
                          child: Text(
                            title,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                              borderRadius: AppRadius.small,
                            ),
                            child: Text(
                              l10n.homeInboxCount(badgeCount),
                              style: AppTypography.labelSmall.copyWith(
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
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 화살표 아이콘
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
