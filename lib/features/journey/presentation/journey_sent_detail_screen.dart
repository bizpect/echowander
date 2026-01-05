import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../core/ads/rewarded_ad_service.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/fullscreen_loading.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';

class JourneySentDetailScreen extends ConsumerStatefulWidget {
  const JourneySentDetailScreen({
    super.key,
    required this.journeyId,
    this.summary,
  });

  final String journeyId;
  final JourneySummary? summary;

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

  @override
  void initState() {
    super.initState();
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
      onPopInvoked: (didPop) {
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
          ),
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FullScreenLoadingOverlay(
          isLoading: _isLoading || _isAdLoading,
          child: SafeArea(
            child: _loadFailed
                ? _buildError(l10n)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: _progress == null
                              ? const SizedBox.shrink()
                              : _buildContent(l10n, constraints.maxWidth),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.journeyDetailLoadFailed,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _load,
            child: Text(l10n.journeyDetailRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, double maxWidth) {
    final progress = _progress!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();
    final summary = widget.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.journeyDetailMessageLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Container(
          width: maxWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            summary?.content ?? l10n.journeyDetailMessageUnavailable,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.journeyDetailProgressTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildKeyValue(
          l10n.journeyDetailStatusLabel,
          _statusLabel(l10n, progress.statusCode),
        ),
        const SizedBox(height: 8),
        _buildKeyValue(
          l10n.journeyDetailDeadlineLabel,
          dateFormat.format(progress.relayDeadlineAt.toLocal()),
        ),
        const SizedBox(height: 8),
        _buildKeyValue(
          l10n.journeyDetailResponseTargetLabel,
          progress.responseTarget.toString(),
        ),
        const SizedBox(height: 8),
        _buildKeyValue(
          l10n.journeyDetailRespondedLabel,
          progress.respondedCount.toString(),
        ),
        const SizedBox(height: 8),
        _buildKeyValue(
          l10n.journeyDetailAssignedLabel,
          progress.assignedCount.toString(),
        ),
        const SizedBox(height: 8),
        _buildKeyValue(
          l10n.journeyDetailPassedLabel,
          progress.passedCount.toString(),
        ),
        const SizedBox(height: 8),
        _buildKeyValue(
          l10n.journeyDetailReportedLabel,
          progress.reportedCount.toString(),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.journeyDetailCountriesLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (progress.countryCodes.isEmpty)
          Text(l10n.journeyDetailCountriesEmpty)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: progress.countryCodes
                .map((code) => Chip(label: Text(code)))
                .toList(),
          ),
        const SizedBox(height: 20),
        Text(
          l10n.journeyDetailResultsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (progress.statusCode != 'COMPLETED')
          Text(l10n.journeyDetailResultsLocked)
        else if (!_adUnlocked)
          _buildAdGate(l10n)
        else if (_resultLoadFailed)
          Text(l10n.journeyDetailResultsLoadFailed)
        else if (_results.isEmpty)
          Text(l10n.journeyDetailResultsEmpty)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final result = _results[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(result.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.content,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    if (result.responseId > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _handleReportResult(result.responseId),
                          child: Text(l10n.journeyResultReportCta),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAdGate(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.journeyDetailAdRequired),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _handleUnlockResults,
          child: Text(l10n.journeyDetailAdCta),
        ),
      ],
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

  Widget _buildKeyValue(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
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
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.inboxReportTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('SPAM'),
            child: Text(l10n.inboxReportSpam),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('ABUSE'),
            child: Text(l10n.inboxReportAbuse),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('OTHER'),
            child: Text(l10n.inboxReportOther),
          ),
        ],
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

  String _statusLabel(AppLocalizations l10n, String statusCode) {
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
