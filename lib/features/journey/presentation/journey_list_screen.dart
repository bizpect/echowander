import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/ads/ad_reward_constants.dart';
import '../../../core/ads/rewarded_ad_gate.dart';
import '../../../core/formatters/app_date_formatter.dart';
import '../../../core/presentation/navigation/tab_navigation_helper.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_empty_state.dart';
import '../../../core/presentation/widgets/app_list_item.dart';
import '../../../core/presentation/widgets/app_pill.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_skeleton.dart';
import '../../../core/presentation/widgets/app_segmented_tabs.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_list_controller.dart';
import '../domain/journey_repository.dart';

enum SentTab { inProgress, completed }

class SentTabController extends Notifier<SentTab> {
  @override
  SentTab build() => SentTab.inProgress;

  void setTab(SentTab tab) {
    if (state == tab) {
      return;
    }
    state = tab;
  }
}

final sentTabProvider =
    NotifierProvider<SentTabController, SentTab>(SentTabController.new);

class JourneyListScreen extends ConsumerStatefulWidget {
  const JourneyListScreen({super.key});

  @override
  ConsumerState<JourneyListScreen> createState() => _JourneyListScreenState();
}

class _JourneyListScreenState extends ConsumerState<JourneyListScreen> {
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(journeyListControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journeyListControllerProvider);
    final controller = ref.read(journeyListControllerProvider.notifier);
    final selectedTab = ref.watch(sentTabProvider);

    ref.listen<JourneyListState>(journeyListControllerProvider, (
      previous,
      next,
    ) {
      if (next.message == null || next.message == previous?.message) {
        return;
      }
      unawaited(_handleMessage(l10n, next.message!));
      controller.clearMessage();
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: AppScaffold(
        appBar: AppHeader(
          title: l10n.journeyListTitle,
          alignTitleLeft: true,
        ),
        bodyPadding: EdgeInsets.zero,
        body: LoadingOverlay(
          isLoading: state.isLoading || _isAdLoading,
          child: Column(
            children: [
              Padding(
                padding: AppSpacing.pagePadding.copyWith(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    assert(() {
                      debugPrint(
                        '[SentTabsParent] maxWidth=${constraints.maxWidth} '
                        'padding=${AppSpacing.pagePadding.horizontal}',
                      );
                      return true;
                    }());
                    return AppSegmentedTabs(
                      tabs: [
                        AppSegmentedTab(label: l10n.sentTabInProgress),
                        AppSegmentedTab(label: l10n.sentTabCompleted),
                      ],
                      selectedIndex:
                          selectedTab == SentTab.inProgress ? 0 : 1,
                      onChanged: (index) {
                        ref
                            .read(sentTabProvider.notifier)
                            .setTab(
                              index == 0
                                  ? SentTab.inProgress
                                  : SentTab.completed,
                            );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Pull-to-Refresh: 보낸메세지 리스트 갱신
                    await controller.load();
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                    child: KeyedSubtree(
                      key: ValueKey(selectedTab),
                      child: _buildBody(
                        context: context,
                        l10n: l10n,
                        state: state,
                        selectedTab: selectedTab,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    TabNavigationHelper.goToHomeTab(context, ref);
  }

  Widget _buildBody({
    required BuildContext context,
    required AppLocalizations l10n,
    required JourneyListState state,
    required SentTab selectedTab,
  }) {
    final filteredItems = _filterItems(state.items, selectedTab);
    if (kDebugMode) {
      debugPrint(
        '[SentTrace][UI] tab=$selectedTab total=${state.items.length} filtered=${filteredItems.length}',
      );
    }

    if (state.isLoading && state.items.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: const [
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: AppListSkeleton(),
            ),
          ),
        ],
      );
    }

    if (filteredItems.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.send_outlined,
              title: selectedTab == SentTab.inProgress
                  ? l10n.sentEmptyInProgressTitle
                  : l10n.sentEmptyCompletedTitle,
              description: selectedTab == SentTab.inProgress
                  ? l10n.sentEmptyInProgressDescription
                  : l10n.sentEmptyCompletedDescription,
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: AppSpacing.pagePadding.copyWith(
            top: 0,
            bottom: AppSpacing.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final itemIndex = index ~/ 2;
                if (index.isOdd) {
                  return const SizedBox(height: AppSpacing.md);
                }
                final item = filteredItems[itemIndex];
                final isOngoing = item.statusCode != 'COMPLETED';
                
                // 진행중 카드는 전용 위젯 사용
                if (isOngoing) {
                  return _OngoingJourneyCard(
                    item: item,
                    l10n: l10n,
                  );
                }
                
                // 완료 카드는 기존 로직 유지
                final meta = AppDateFormatter.formatCardTimestamp(
                  item.createdAt,
                  l10n.localeName,
                );
                final status = _buildStatusPills(
                  l10n: l10n,
                  statusCode: item.statusCode,
                  filterCode: item.filterCode,
                );
                return AppListItem(
                  title: _statusLabel(l10n, item.statusCode),
                  subtitle: item.content,
                  meta: meta,
                  status: status,
                  leading: _ListLeadingIcon(
                    icon: Icons.check_circle,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.iconMuted,
                    size: 20,
                  ),
                  onTap: () => _handleCompletedTap(item),
                );
              },
              childCount: filteredItems.isEmpty
                  ? 0
                  : (filteredItems.length * 2) - 1,
            ),
          ),
        ),
      ],
    );
  }

  List<JourneySummary> _filterItems(
    List<JourneySummary> items,
    SentTab selectedTab,
  ) {
    if (selectedTab == SentTab.completed) {
      return items.where((item) => item.statusCode == 'COMPLETED').toList();
    }
    return items.where((item) => item.statusCode != 'COMPLETED').toList();
  }

  Future<void> _handleMessage(
    AppLocalizations l10n,
    JourneyListMessage message,
  ) async {
    switch (message) {
      case JourneyListMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorSessionExpired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyListMessage.loadFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorGeneric,
          confirmLabel: l10n.composeOk,
        );
        return;
    }
  }

  Future<void> _handleCompletedTap(JourneySummary item) async {
    if (_isAdLoading) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final reqId = DateTime.now().microsecondsSinceEpoch.toString();
    if (kDebugMode) {
      debugPrint(
        '[RewardFlow] click reqId=$reqId journeyId=${item.journeyId} status=${item.statusCode} '
        'unlockedCached=${item.isRewardUnlocked}',
      );
    }
    final controller = ref.read(journeyListControllerProvider.notifier);
    if (item.isRewardUnlocked) {
      _goToDetail(item, reqId: reqId);
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      await showAppAlertDialog(
        context: context,
        title: l10n.errorTitle,
        message: l10n.errorSessionExpired,
        confirmLabel: l10n.composeOk,
      );
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.journeyDetailGateDialogTitle,
      message: l10n.journeyDetailGateDialogBody,
      confirmLabel: l10n.journeyDetailGateDialogConfirm,
      cancelLabel: l10n.composeCancel,
    );
    if (!mounted) {
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[RewardFlow] dialog_unlock reqId=$reqId journeyId=${item.journeyId} '
        'action=${confirmed == true ? 'CONFIRM' : 'CANCEL'}',
      );
    }
    if (confirmed != true) {
      return;
    }

    setState(() {
      _isAdLoading = true;
    });
    final gate = ref.read(rewardedAdGateProvider);
    final outcome = await gate.showRewardedAndReturnResult(
      placementCode: AdPlacementCodes.sentDetailGate,
      contentId: item.journeyId,
      accessToken: accessToken,
      reqId: reqId,
    );
    if (!mounted) {
      return;
    }
    final refreshedL10n = AppLocalizations.of(context)!;
    setState(() {
      _isAdLoading = false;
    });

    if (outcome.unlockFailed) {
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: refreshedL10n.journeyDetailUnlockFailedTitle,
        message: refreshedL10n.journeyDetailUnlockFailedBody,
        confirmLabel: refreshedL10n.composeOk,
      );
      return;
    }

    switch (outcome.result) {
      case RewardGateResult.earned:
        controller.markRewardUnlocked(item.journeyId, reqId: reqId);
        _goToDetail(item, reqId: reqId);
        return;
      case RewardGateResult.dismissed:
        return;
      case RewardGateResult.failLoad:
      case RewardGateResult.failShow:
      case RewardGateResult.failConfig:
        if (outcome.allowNavigationWithoutAd) {
          _goToDetail(item, reqId: reqId);
          return;
        }
        if (!outcome.shouldAlert) {
          return;
        }
        if (!mounted) {
          return;
        }
        await showAppAlertDialog(
          context: context,
          title: refreshedL10n.journeyDetailGateFailedTitle,
          message: refreshedL10n.journeyDetailGateFailedBody,
          confirmLabel: refreshedL10n.composeOk,
        );
        return;
    }
  }

  void _goToDetail(JourneySummary item, {required String reqId}) {
    if (kDebugMode) {
      debugPrint('[Nav] toDetail reqId=$reqId journeyId=${item.journeyId}');
    }
    context.go('${AppRoutes.journeyList}/${item.journeyId}', extra: item);
  }

  Widget _buildStatusPills({
    required AppLocalizations l10n,
    required String statusCode,
    required String filterCode,
  }) {
    final isCompleted = statusCode == 'COMPLETED';
    final statusTone = isCompleted ? AppPillTone.success : AppPillTone.warning;
    final filterTone = filterCode == 'OK' ? null : AppPillTone.danger;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPill(label: _statusLabel(l10n, statusCode), tone: statusTone),
        if (filterTone != null) ...[
          const SizedBox(width: AppSpacing.sm),
          AppPill(label: _filterLabel(l10n, filterCode), tone: filterTone),
        ],
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'CREATED':
      case 'WAITING':
        return l10n.journeyStatusInProgress;
      case 'COMPLETED':
        return l10n.journeyStatusCompleted;
      default:
        return l10n.journeyStatusUnknown;
    }
  }

  String _filterLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'OK':
        return l10n.journeyFilterOk;
      case 'HELD':
        return l10n.journeyFilterHeld;
      case 'REMOVED':
        return l10n.journeyFilterRemoved;
      default:
        return l10n.journeyFilterUnknown;
    }
  }
}

class _ListLeadingIcon extends StatelessWidget {
  const _ListLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.full,
      ),
      child: Icon(icon, size: 18, color: AppColors.iconPrimary),
    );
  }
}

/// 진행중 카드 전용 위젯
class _OngoingJourneyCard extends StatelessWidget {
  const _OngoingJourneyCard({
    required this.item,
    required this.l10n,
  });

  final JourneySummary item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AppCard(
      onTap: null, // 진행중 카드는 탭 비활성
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메시지 내용 (1줄만, ellipsis)
          Text(
            item.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 하단 노란 보더라인 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.inboxSentOngoingForwardedCountLabel(item.sentCount),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.inboxSentOngoingRespondedCountLabel(item.respondedCount),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
