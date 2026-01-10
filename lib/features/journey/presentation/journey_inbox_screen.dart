import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/presentation/navigation/tab_navigation_helper.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/app_empty_state.dart';
import '../../../core/presentation/widgets/app_list_item.dart';
import '../../../core/presentation/widgets/app_pill.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/presentation/widgets/app_skeleton.dart';
import '../../../core/presentation/widgets/app_segmented_tabs.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_inbox_controller.dart';
import '../domain/journey_repository.dart';

enum ReceivedTab { pending, completed }

class ReceivedTabController extends Notifier<ReceivedTab> {
  @override
  ReceivedTab build() => ReceivedTab.pending;

  void setTab(ReceivedTab tab) {
    if (state == tab) {
      return;
    }
    state = tab;
  }
}

final receivedTabProvider =
    NotifierProvider<ReceivedTabController, ReceivedTab>(ReceivedTabController.new);

/// Inbox 화면 - 받은 Journey 목록
///
/// 특징:
/// - 상태별 시각적 구분 (아이콘, 색상)
/// - 딥링크 하이라이트
/// - RefreshIndicator
/// - 접근성 최적화
class JourneyInboxScreen extends ConsumerStatefulWidget {
  const JourneyInboxScreen({super.key, this.highlightJourneyId});

  final String? highlightJourneyId;

  @override
  ConsumerState<JourneyInboxScreen> createState() => _JourneyInboxScreenState();
}

class _JourneyInboxScreenState extends ConsumerState<JourneyInboxScreen> {
  bool _initLogged = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode && !_initLogged) {
      _initLogged = true;
      final session = ref.read(sessionManagerProvider);
      final hasSession =
          session.accessToken != null && session.accessToken!.isNotEmpty;
      debugPrint(
        '[InboxTrace][UI] initState - highlightJourneyId: ${widget.highlightJourneyId}, hasSession: $hasSession',
      );
    }
    Future.microtask(
      () => ref.read(journeyInboxControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journeyInboxControllerProvider);
    final controller = ref.read(journeyInboxControllerProvider.notifier);
    final selectedTab = ref.watch(receivedTabProvider);

    if (kDebugMode) {
      debugPrint(
        '[InboxTrace][UI] build - isLoading: ${state.isLoading}, items: ${state.items.length}, message: ${state.message}, selectedTab: $selectedTab',
      );
    }

    ref.listen<JourneyInboxState>(journeyInboxControllerProvider, (
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
          title: l10n.inboxTitle,
          alignTitleLeft: true,
        ),
        bodyPadding: EdgeInsets.zero,
        body: LoadingOverlay(
          isLoading: state.isLoading,
          child: Column(
            children: [
              Padding(
                padding: AppSpacing.pagePadding.copyWith(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AppSegmentedTabs(
                      tabs: [
                        AppSegmentedTab(label: l10n.inboxTabPending),
                        AppSegmentedTab(label: l10n.inboxTabCompleted),
                      ],
                      selectedIndex:
                          selectedTab == ReceivedTab.pending ? 0 : 1,
                      onChanged: (index) {
                        ref
                            .read(receivedTabProvider.notifier)
                            .setTab(
                              index == 0
                                  ? ReceivedTab.pending
                                  : ReceivedTab.completed,
                            );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(journeyInboxControllerProvider.notifier).load(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                      child: KeyedSubtree(
                        key: ValueKey(selectedTab),
                        child: _buildBody(context, l10n, state, selectedTab),
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

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    JourneyInboxState state,
    ReceivedTab selectedTab,
  ) {
    if (kDebugMode) {
      final hasMessage = state.message != null;
      final isEmpty = state.items.isEmpty;
      final isLoading = state.isLoading;
      final emptyStateCondition = isEmpty && !isLoading;
      debugPrint(
        '[InboxTrace][UI] _buildBody - hasMessage: $hasMessage, isEmpty: $isEmpty, isLoading: $isLoading, emptyStateCondition: $emptyStateCondition',
      );
    }

    final filteredItems = _filterItems(state.items, selectedTab);
    if (kDebugMode) {
      debugPrint(
        '[InboxTrace][UI] _buildBody - tab=$selectedTab total=${state.items.length} filtered=${filteredItems.length}',
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

    // 에러 상태
    if (state.message != null) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][UI] _buildBody - showing error state');
      }
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppEmptyState(
              icon: Icons.error_outline,
              title: l10n.inboxLoadFailed,
              actionLabel: l10n.inboxRefresh,
              onAction: () =>
                  ref.read(journeyInboxControllerProvider.notifier).load(),
            ),
          ),
        ],
      );
    }

    // 빈 상태
    if (filteredItems.isEmpty && !state.isLoading) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][UI] _buildBody - showing empty state');
      }
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: selectedTab == ReceivedTab.pending
                  ? l10n.inboxEmptyPendingTitle
                  : l10n.inboxEmptyCompletedTitle,
              description: selectedTab == ReceivedTab.pending
                  ? l10n.inboxEmptyPendingDescription
                  : l10n.inboxEmptyCompletedDescription,
            ),
          ),
        ],
      );
    }

    // 정상 상태 - 리스트 표시
    if (kDebugMode) {
      debugPrint(
        '[InboxTrace][UI] _buildBody - showing list, itemCount: ${filteredItems.length}',
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
          sliver: SliverList.separated(
            itemCount: filteredItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final isHighlighted = item.journeyId == widget.highlightJourneyId;
              return _InboxCard(
                item: item,
                isHighlighted: isHighlighted,
                onTap: () {
                  context.go('${AppRoutes.inbox}/${item.journeyId}', extra: item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<JourneyInboxItem> _filterItems(
    List<JourneyInboxItem> items,
    ReceivedTab selectedTab,
  ) {
    if (selectedTab == ReceivedTab.completed) {
      return items.where((item) => item.recipientStatus == 'RESPONDED').toList();
    }
    return items.where((item) => item.recipientStatus != 'RESPONDED').toList();
  }

  Future<void> _handleMessage(
    AppLocalizations l10n,
    JourneyInboxMessage message,
  ) async {
    switch (message) {
      case JourneyInboxMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorSessionExpired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyInboxMessage.forbidden:
        await showAppAlertDialog(
          context: context,
          title: l10n.journeyInboxForbiddenTitle,
          message: l10n.journeyInboxForbiddenMessage,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyInboxMessage.loadFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorGeneric,
          confirmLabel: l10n.composeOk,
        );
        return;
    }
  }

  void _handleBack(BuildContext context) {
    TabNavigationHelper.goToHomeTab(context, ref);
  }
}

/// Inbox 아이템 카드
class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.isHighlighted,
    required this.onTap,
  });

  final JourneyInboxItem item;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    // recipientStatus에 따른 스타일 결정
    final statusInfo = _getStatusInfo(item.recipientStatus);
    final meta = item.imageCount > 0
        ? '${dateFormat.format(item.createdAt.toLocal())} · ${l10n.inboxImageCount(item.imageCount)}'
        : dateFormat.format(item.createdAt.toLocal());
    final title = _getStatusLabel(l10n, item.recipientStatus);
    final subtitle = item.recipientStatus == 'PASSED'
        ? l10n.inboxPassedTitle
        : item.content;

    return AppListItem(
      title: title,
      subtitle: subtitle,
      meta: meta,
      status: AppPill(label: title, tone: statusInfo.tone),
      leading: _ListLeadingIcon(icon: statusInfo.icon, color: statusInfo.color),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.iconMuted,
        size: 20,
      ),
      isHighlighted: isHighlighted,
      onTap: onTap,
    );
  }

  String _getStatusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'ASSIGNED':
        return l10n.inboxStatusAssigned;
      case 'RESPONDED':
        return l10n.inboxStatusResponded;
      case 'PASSED':
        return l10n.inboxStatusPassed;
      case 'REPORTED':
        return l10n.inboxStatusReported;
      default:
        return l10n.inboxStatusUnknown;
    }
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'ASSIGNED':
        return _StatusInfo(
          icon: Icons.notifications_active,
          color: AppColors.warning,
          tone: AppPillTone.warning,
        );
      case 'RESPONDED':
        return _StatusInfo(
          icon: Icons.check_circle,
          color: AppColors.success,
          tone: AppPillTone.success,
        );
      case 'PASSED':
        return _StatusInfo(
          icon: Icons.forward,
          color: AppColors.onSurfaceVariant,
          tone: AppPillTone.neutral,
        );
      case 'REPORTED':
        return _StatusInfo(
          icon: Icons.flag,
          color: AppColors.error,
          tone: AppPillTone.danger,
        );
      default:
        return _StatusInfo(
          icon: Icons.help_outline,
          color: AppColors.onSurfaceVariant,
          tone: AppPillTone.neutral,
        );
    }
  }
}

/// 상태 정보 (아이콘 + 색상)
class _StatusInfo {
  const _StatusInfo({
    required this.icon,
    required this.color,
    required this.tone,
  });

  final IconData icon;
  final Color color;
  final AppPillTone tone;
}

class _ListLeadingIcon extends StatelessWidget {
  const _ListLeadingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.full,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
