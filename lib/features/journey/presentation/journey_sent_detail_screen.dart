import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/ads/rewarded_ad_service.dart';
import '../../../core/presentation/widgets/app_button.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/presentation/widgets/empty_state.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';

/// Journey 결과 화면 (Return 화면)
///
/// 특징:
/// - 릴레이 완료 상태 명확한 시각화
/// - 응답 개수, 참여 국가 요약
/// - 응답 리스트 (익명, 카드형)
/// - Rewarded Ad 게이트 (실패 시 대체 UX)
/// - EmptyStateWidget로 빈 결과 처리
class JourneySentDetailScreen extends ConsumerStatefulWidget {
  const JourneySentDetailScreen({
    super.key,
    required this.journeyId,
    this.summary,
    this.fromNotification = false,
  });

  final String journeyId;
  final JourneySummary? summary;
  final bool fromNotification;

  @override
  ConsumerState<JourneySentDetailScreen> createState() => _JourneySentDetailScreenState();
}

class _JourneySentDetailScreenState extends ConsumerState<JourneySentDetailScreen> {
  bool _isLoading = false;
  bool _loadFailed = false;
  bool _resultLoadFailed = false;
  bool _adUnlocked = false;
  bool _isAdLoading = false;
  JourneyProgress? _progress;
  List<JourneyResultItem> _results = [];
  final RewardedAdService _rewardedAdService = RewardedAdService();
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    _load();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
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
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _resultLoadFailed = false;
    });
    try {
      final progress = await ref.read(journeyRepositoryProvider).fetchJourneyProgress(
            journeyId: widget.journeyId,
            accessToken: accessToken,
          );
      var results = <JourneyResultItem>[];
      var resultLoadFailed = false;
      if (progress.statusCode == 'COMPLETED') {
        try {
          results = await ref.read(journeyRepositoryProvider).fetchJourneyResults(
                journeyId: widget.journeyId,
                accessToken: accessToken,
              );
        } on JourneyResultException {
          resultLoadFailed = true;
        } catch (_) {
          resultLoadFailed = true;
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _progress = progress;
        _results = results;
        _resultLoadFailed = resultLoadFailed;
        _isLoading = false;
      });
    } on JourneyProgressException {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.journeyDetailTitle),
          leading: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.inboxRefresh,
            ),
          ],
        ),
        body: LoadingOverlay(
          isLoading: _isLoading || _isAdLoading,
          child: SafeArea(
            child: _loadFailed
                ? _buildError(l10n)
                : _progress == null
                    ? const SizedBox.shrink()
                    : _buildContent(l10n),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.spacing16),
            Text(
              l10n.journeyDetailLoadFailed,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
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

  Widget _buildContent(AppLocalizations l10n) {
    final progress = _progress!;
    final isCompleted = progress.statusCode == 'COMPLETED';

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 요약 카드
          _StatusSummaryCard(
            progress: progress,
            l10n: l10n,
            isHighlighted: widget.fromNotification,
          ),
          SizedBox(height: AppSpacing.spacing20),

          // 원본 메시지
          _buildOriginalMessage(l10n),
          SizedBox(height: AppSpacing.spacing20),

          // 진행 상황
          _buildProgressSection(l10n, progress),
          SizedBox(height: AppSpacing.spacing20),

          // 참여 국가
          _buildCountriesSection(l10n, progress),
          SizedBox(height: AppSpacing.spacing24),

          // 결과 섹션
          _buildResultsSection(l10n, progress, isCompleted),
        ],
      ),
    );
  }

  Widget _buildOriginalMessage(AppLocalizations l10n) {
    final summary = widget.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.message_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            SizedBox(width: AppSpacing.spacing8),
            Text(
              l10n.journeyDetailMessageLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.spacing12),
        Card(
          color: AppColors.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacing16),
            child: Text(
              summary?.content ?? l10n.journeyDetailMessageUnavailable,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    height: 1.5,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(AppLocalizations l10n, JourneyProgress progress) {
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.journeyDetailProgressTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppSpacing.spacing12),
        Card(
          color: AppColors.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              children: [
                _buildInfoRow(
                  l10n.journeyDetailDeadlineLabel,
                  dateFormat.format(progress.relayDeadlineAt.toLocal()),
                  Icons.schedule,
                ),
                SizedBox(height: AppSpacing.spacing12),
                _buildInfoRow(
                  l10n.journeyDetailResponseTargetLabel,
                  progress.responseTarget.toString(),
                  Icons.flag,
                ),
                SizedBox(height: AppSpacing.spacing12),
                _buildInfoRow(
                  l10n.journeyDetailRespondedLabel,
                  progress.respondedCount.toString(),
                  Icons.check_circle,
                  valueColor: AppColors.success,
                ),
                SizedBox(height: AppSpacing.spacing12),
                _buildInfoRow(
                  l10n.journeyDetailAssignedLabel,
                  progress.assignedCount.toString(),
                  Icons.person,
                ),
                SizedBox(height: AppSpacing.spacing12),
                _buildInfoRow(
                  l10n.journeyDetailPassedLabel,
                  progress.passedCount.toString(),
                  Icons.forward,
                ),
                SizedBox(height: AppSpacing.spacing12),
                _buildInfoRow(
                  l10n.journeyDetailReportedLabel,
                  progress.reportedCount.toString(),
                  Icons.flag,
                  valueColor: AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        SizedBox(width: AppSpacing.spacing8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor ?? AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildCountriesSection(AppLocalizations l10n, JourneyProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.public,
              size: 18,
              color: AppColors.primary,
            ),
            SizedBox(width: AppSpacing.spacing8),
            Text(
              l10n.journeyDetailCountriesLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.spacing12),
        if (progress.countryCodes.isEmpty)
          Text(
            l10n.journeyDetailCountriesEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          )
        else
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: progress.countryCodes
                .map((code) => Chip(
                      label: Text(code),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildResultsSection(AppLocalizations l10n, JourneyProgress progress, bool isCompleted) {
    final highlightDecoration = widget.fromNotification
        ? BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
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
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.spacing8),
              Text(
                l10n.journeyDetailResultsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing16),

          // 상태별 결과 표시
          if (!isCompleted)
            _buildResultsLocked(l10n)
          else if (!_adUnlocked)
            _buildAdGate(l10n)
          else if (_resultLoadFailed)
            _buildResultsError(l10n)
          else if (_results.isEmpty)
            _buildEmptyResults(l10n)
          else
            _buildResultsList(l10n),
        ],
      ),
    );
  }

  Widget _buildResultsLocked(AppLocalizations l10n) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.warning),
            SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                l10n.journeyDetailResultsLocked,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdGate(AppLocalizations l10n) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_outline, color: AppColors.primary),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Text(
                    l10n.journeyDetailAdRequired,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.spacing16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: AppFilledButton(
                onPressed: _handleUnlockResults,
                child: Text(l10n.journeyDetailAdCta),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsError(AppLocalizations l10n) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                l10n.journeyDetailResultsLoadFailed,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults(AppLocalizations l10n) {
    return EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: l10n.journeyDetailResultsEmpty,
      description: l10n.homeEmptyDescription,
      actionLabel: l10n.homeCreateCardTitle,
      onAction: () => context.go(AppRoutes.compose),
    );
  }

  Widget _buildResultsList(AppLocalizations l10n) {
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.spacing12),
      itemBuilder: (context, index) {
        final result = _results[index];
        return Card(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 + 익명 표시
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: AppSpacing.spacing4),
                    Text(
                      l10n.journeyDetailAnonymous,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    SizedBox(width: AppSpacing.spacing8),
                    Text(
                      '•',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    SizedBox(width: AppSpacing.spacing8),
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: AppSpacing.spacing4),
                    Text(
                      dateFormat.format(result.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacing12),

                // 응답 내용 (감정 전달을 위한 타이포그래피)
                Text(
                  result.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurface,
                        height: 1.6,
                        fontSize: 16,
                      ),
                ),

                // 신고 버튼
                if (result.responseId > 0) ...[
                  SizedBox(height: AppSpacing.spacing12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _handleReportResult(result.responseId),
                      icon: Icon(Icons.flag_outlined, size: 16),
                      label: Text(l10n.journeyResultReportCta),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleUnlockResults() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isAdLoading = true;
    });
    final result = await _rewardedAdService.showRewardedAd();
    if (!mounted) {
      return;
    }
    if (result) {
      setState(() {
        _adUnlocked = true;
        _isAdLoading = false;
      });
      return;
    }
    setState(() {
      _isAdLoading = false;
    });
    // 광고 실패 시 대체 UX (부드러운 안내, 차단 금지)
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.journeyDetailAdFailedTitle,
      message: l10n.journeyDetailAdFailedBody,
      confirmLabel: l10n.journeyDetailAdFailedConfirm,
      cancelLabel: l10n.composeCancel,
    );
    if (confirmed == true && mounted) {
      setState(() {
        _adUnlocked = true;
      });
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleReportResult(int responseId) async {
    final l10n = AppLocalizations.of(context)!;

    // 신고 사유 선택 다이얼로그
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inboxReportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.report_problem, color: AppColors.error),
              title: Text(l10n.inboxReportSpam),
              onTap: () => Navigator.of(context).pop('SPAM'),
            ),
            ListTile(
              leading: Icon(Icons.report, color: AppColors.error),
              title: Text(l10n.inboxReportAbuse),
              onTap: () => Navigator.of(context).pop('ABUSE'),
            ),
            ListTile(
              leading: Icon(Icons.more_horiz, color: AppColors.error),
              title: Text(l10n.inboxReportOther),
              onTap: () => Navigator.of(context).pop('OTHER'),
            ),
          ],
        ),
      ),
    );

    if (reason == null) {
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    setState(() {
      _isAdLoading = true;
    });
    try {
      await ref.read(journeyRepositoryProvider).reportJourneyResponse(
            responseId: responseId,
            reasonCode: reason,
            accessToken: accessToken,
          );
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.journeyResultReportSuccessTitle,
        message: l10n.journeyResultReportSuccessBody,
        confirmLabel: l10n.composeOk,
      );
    } on JourneyResultReportException {
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.journeyResultReportFailed,
        confirmLabel: l10n.composeOk,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.journeyResultReportFailed,
        confirmLabel: l10n.composeOk,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAdLoading = false;
        });
      }
    }
  }
}

/// 상태 요약 카드
class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.progress,
    required this.l10n,
    required this.isHighlighted,
  });

  final JourneyProgress progress;
  final AppLocalizations l10n;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress.statusCode == 'COMPLETED';
    final statusColor = isCompleted ? AppColors.success : AppColors.warning;
    final statusIcon = isCompleted ? Icons.check_circle : Icons.schedule;

    return Card(
      color: isHighlighted
          ? AppColors.primary.withValues(alpha: 0.12)
          : statusColor.withValues(alpha: 0.1),
      elevation: isHighlighted ? 3 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: isHighlighted
            ? BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          children: [
            // 상태 아이콘 + 텍스트
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Text(
                    _statusLabel(progress.statusCode),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.spacing16),

            // 요약 정보 (응답 개수, 국가 수)
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.chat_bubble,
                    label: l10n.journeyDetailRespondedLabel,
                    value: progress.respondedCount.toString(),
                  ),
                ),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.public,
                    label: l10n.journeyDetailCountriesLabel,
                    value: progress.countryCodes.length.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String statusCode) {
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

/// 요약 아이템
class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(height: AppSpacing.spacing4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.spacing4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
