import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/presentation/navigation/tab_navigation_helper.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_dialog.dart';
import '../../../../core/presentation/widgets/app_header.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/chat_date_divider.dart';
import '../../../../core/presentation/widgets/loading_overlay.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/sent_journey_detail_controller.dart';
import '../../domain/sent_journey_detail.dart';
import '../../domain/sent_journey_response.dart';

class SentJourneyDetailScreen extends ConsumerStatefulWidget {
  const SentJourneyDetailScreen({
    super.key,
    required this.journeyId,
    this.fromNotification = false,
  });

  final String journeyId;
  final bool fromNotification;

  @override
  ConsumerState<SentJourneyDetailScreen> createState() =>
      _SentJourneyDetailScreenState();
}

class _SentJourneyDetailScreenState
    extends ConsumerState<SentJourneyDetailScreen> {
  late final String _reqId;
  bool _didShowMissingAlert = false;

  @override
  void initState() {
    super.initState();
    _reqId = DateTime.now().microsecondsSinceEpoch.toString();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      await showAppAlertDialog(
        context: context,
        title: l10n.errorTitle,
        message: l10n.errorSessionExpired,
        confirmLabel: l10n.composeOk,
      );
      return;
    }
    await ref
        .read(sentJourneyDetailControllerProvider.notifier)
        .load(
          journeyId: widget.journeyId,
          accessToken: accessToken,
          reqId: _reqId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sentJourneyDetailControllerProvider);
    if ((state.responsesMissing || state.responsesLoadFailed) &&
        !_didShowMissingAlert) {
      _didShowMissingAlert = true;
      Future.microtask(() => _showMissingResponsesAlert(l10n));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        TabNavigationHelper.goToSentRoot(context, ref);
      },
      child: AppScaffold(
        appBar: AppHeader(
          title: l10n.journeyDetailTitle,
          leadingIcon: Icons.arrow_back,
          onLeadingTap: () => TabNavigationHelper.goToSentRoot(context, ref),
          leadingSemanticLabel: MaterialLocalizations.of(
            context,
          ).backButtonTooltip,
        ),
        body: LoadingOverlay(
          isLoading: state.isLoading,
          child: state.loadFailed
              ? _buildError(l10n)
              : state.detail == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: _buildContent(
                    l10n,
                    state.detail!,
                    state.responses,
                    state.responsesLoadFailed,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: AppSpacing.spacing16),
            Text(
              l10n.journeyDetailLoadFailed,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacing24),
            AppFilledButton(
              onPressed: _load,
              child: Text(l10n.journeyDetailRetry),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMissingResponsesAlert(AppLocalizations l10n) async {
    if (!mounted) {
      return;
    }
    await showAppAlertDialog(
      context: context,
      title: l10n.commonTemporaryErrorTitle,
      message: l10n.sentDetailRepliesLoadFailedMessage,
      confirmLabel: l10n.commonOk,
      onConfirm: () => TabNavigationHelper.goToSentRoot(context, ref),
    );
  }

  Widget _buildContent(
    AppLocalizations l10n,
    SentJourneyDetail detail,
    List<SentJourneyResponse> responses,
    bool responsesLoadFailed,
  ) {
    final isCompleted = detail.statusCode == 'COMPLETED';
    final isUnlocked = detail.isRewardUnlocked;

    // COMPLETED(=RESPONDED) 상태: 채팅 UI만 표시
    if (isCompleted) {
      return _buildResponsesSection(
        l10n,
        isCompleted: isCompleted,
        isUnlocked: isUnlocked,
        responses: responses,
        responsesLoadFailed: responsesLoadFailed,
      );
    }

    // 다른 상태(WAITING/CREATED 등): 기존 UI 유지
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(l10n, detail),
        SizedBox(height: AppSpacing.spacing20),
        _buildContentCard(detail),
        SizedBox(height: AppSpacing.spacing20),
        _buildResponsesSection(
          l10n,
          isCompleted: isCompleted,
          isUnlocked: isUnlocked,
          responses: responses,
          responsesLoadFailed: responsesLoadFailed,
        ),
      ],
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    SentJourneyDetail detail,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [_buildStatusBadge(l10n, detail.statusCode)]),
        SizedBox(height: AppSpacing.spacing12),
        Row(
          children: [
            Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
            SizedBox(width: AppSpacing.spacing4),
            Text(
              AppDateFormatter.formatCardTimestamp(
                detail.createdAt,
                l10n.localeName,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentCard(SentJourneyDetail detail) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.content,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            if (detail.imageCount > 0) ...[
              SizedBox(height: AppSpacing.spacing12),
              Row(
                children: [
                  Icon(
                    Icons.image,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  SizedBox(width: AppSpacing.spacing4),
                  Text(
                    '${detail.imageCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesSection(
    AppLocalizations l10n, {
    required bool isCompleted,
    required bool isUnlocked,
    required List<SentJourneyResponse> responses,
    required bool responsesLoadFailed,
  }) {
    final canShowResponses = isCompleted && isUnlocked;
    final highlightDecoration = widget.fromNotification
        ? BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.medium,
            border: Border.all(color: AppColors.primary, width: 1.5),
          )
        : null;
    return Container(
      padding: widget.fromNotification
          ? EdgeInsets.all(AppSpacing.spacing16)
          : EdgeInsets.zero,
      decoration: highlightDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 채팅 UI만 표시 (섹션 타이틀 제거)
          if (!canShowResponses)
            _buildLocked(l10n)
          else if (responsesLoadFailed || responses.isEmpty)
            const SizedBox.shrink()
          else
            _buildChatThreadView(l10n, responses),
        ],
      ),
    );
  }

  Widget _buildLocked(AppLocalizations l10n) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.warning),
            SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                l10n.journeyDetailResultsLocked,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 채팅 스레드 UI: 내 메시지(오른쪽) + 답글들(왼쪽)
  /// 날짜 그룹화 구분선 포함 (카카오톡 스타일)
  Widget _buildChatThreadView(
    AppLocalizations l10n,
    List<SentJourneyResponse> responses,
  ) {
    final state = ref.watch(sentJourneyDetailControllerProvider);
    final detail = state.detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    // 채팅 아이템 모델 (내 메시지 + 답글들)
    final chatItems = <_ChatItem>[
      _ChatItem(
        createdAt: detail.createdAt,
        isMyMessage: true,
        detail: detail,
      ),
      ...responses.map(
        (response) => _ChatItem(
          createdAt: response.createdAt,
          isMyMessage: false,
          response: response,
        ),
      ),
    ];

    // createdAt 오름차순 정렬 (과거 → 현재)
    chatItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 위젯 리스트 생성: 날짜 구분선 + 채팅 버블
    final widgets = <Widget>[];
    DateTime? previousDate;

    for (var i = 0; i < chatItems.length; i++) {
      final item = chatItems[i];
      // UTC → 로컬 변환 (날짜 비교용)
      final localTime = item.createdAt.isUtc
          ? item.createdAt.toLocal()
          : item.createdAt;
      final currentDate = DateTime(
        localTime.year,
        localTime.month,
        localTime.day,
      );

      // 첫 아이템이거나 날짜가 바뀌면 구분선 삽입
      if (previousDate == null || currentDate != previousDate) {
        final dateText = AppDateFormatter.formatChatDateDivider(
          item.createdAt,
          l10n.localeName,
        );
        widgets.add(ChatDateDivider(dateText: dateText));
        previousDate = currentDate;
      }

      // 채팅 버블
      if (item.isMyMessage) {
        widgets.add(_buildMyChatBubble(item.detail!, l10n));
      } else {
        widgets.add(_buildOtherChatBubble(item.response!, l10n));
      }

      // 버블 간 spacing (마지막 아이템 제외)
      if (i < chatItems.length - 1) {
        widgets.add(SizedBox(height: AppSpacing.spacing12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  /// 내 메시지 버블 (오른쪽 정렬, primary 계열)
  Widget _buildMyChatBubble(SentJourneyDetail detail, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                detail.displayContent,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppSpacing.spacing4),
              Text(
                AppDateFormatter.formatCardTimestamp(
                  detail.createdAt,
                  l10n.localeName,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상대 답글 버블 (왼쪽 정렬, surface 계열)
  Widget _buildOtherChatBubble(SentJourneyResponse response, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 닉네임
              Text(
                response.responderNickname,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.spacing8),
              // 답글 내용
              Text(
                response.displayContent,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppSpacing.spacing4),
              // 시간
              Text(
                AppDateFormatter.formatCardTimestamp(
                  response.createdAt,
                  l10n.localeName,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppLocalizations l10n, String statusCode) {
    final isCompleted = statusCode == 'COMPLETED';
    final statusLabel = _statusLabel(l10n, statusCode);
    final statusColor = isCompleted ? AppColors.success : AppColors.warning;
    final statusIcon = isCompleted ? Icons.check_circle : Icons.schedule;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          SizedBox(width: AppSpacing.spacing4),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
}

/// 채팅 아이템 헬퍼 클래스 (날짜 그룹화용)
class _ChatItem {
  _ChatItem({
    required this.createdAt,
    required this.isMyMessage,
    this.detail,
    this.response,
  });

  final DateTime createdAt;
  final bool isMyMessage;
  final SentJourneyDetail? detail; // 내 메시지인 경우
  final SentJourneyResponse? response; // 답글인 경우
}
