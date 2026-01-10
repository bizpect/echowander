import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/presentation/navigation/tab_navigation_helper.dart';
import '../../../core/presentation/scaffolds/main_tab_controller.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/validation/text_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_compose_controller.dart';
import '../application/journey_list_controller.dart';
import 'widgets/compose_attachment_grid.dart';
import 'widgets/compose_bottom_bar.dart';
import 'widgets/compose_message_card.dart';
import 'widgets/compose_recipient_card.dart';

/// Journey 작성 화면
///
/// 특징:
/// - 텍스트 입력 + 이미지 최대 3장
/// - 실시간 입력 검증 (금지 패턴, 글자수)
/// - 이탈 방지 (입력 중 뒤로가기 확인)
/// - LoadingOverlay로 전송 중 입력 차단
class JourneyComposeScreen extends ConsumerStatefulWidget {
  const JourneyComposeScreen({super.key});

  @override
  ConsumerState<JourneyComposeScreen> createState() =>
      _JourneyComposeScreenState();
}

class _JourneyComposeScreenState extends ConsumerState<JourneyComposeScreen> {
  late final TextEditingController _controller;
  ProviderSubscription<JourneyComposeState>? _messageSubscription;
  ProviderSubscription<String>? _contentSubscription;
  bool _isUpdatingController = false;
  bool _isHandlingBack = false;

  // 3-step wizard 상태 (UI 전용)
  int _stepIndex = 0;

  // 인라인 메시지/에러 상태 (모달 금지 정책 준수)
  String? _inlineMessage;
  bool _inlineMessageIsError = true;
  bool _showPhotoSettingsCta = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // TextEditingController 변경 시 provider state 업데이트
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    // 리스너 구독 해제
    _messageSubscription?.close();
    _contentSubscription?.close();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_isUpdatingController) {
      return;
    }
    final currentText = _controller.text;
    final currentState = ref.read(journeyComposeControllerProvider);
    if (currentText != currentState.content) {
      ref
          .read(journeyComposeControllerProvider.notifier)
          .updateContent(currentText);
    }
  }

  void _setupListeners(AppLocalizations l10n) {
    // 메시지 이벤트 처리 리스너 (1회만 등록)
    _messageSubscription?.close();
    _messageSubscription = ref.listenManual<JourneyComposeState>(
      journeyComposeControllerProvider,
      (previous, next) {
        if (next.message == null || next.message == previous?.message) {
          return;
        }
        if (!mounted) {
          return;
        }
        _handleMessage(l10n, next.message!);
        ref.read(journeyComposeControllerProvider.notifier).clearMessage();
      },
    );

    // content 동기화 리스너 (provider → controller)
    _contentSubscription?.close();
    _contentSubscription = ref.listenManual<String>(
      journeyComposeControllerProvider.select((state) => state.content),
      (previous, next) {
        if (!mounted) {
          return;
        }
        if (_isUpdatingController) {
          return;
        }
        if (_controller.text != next) {
          _isUpdatingController = true;
          final max = next.length;
          final oldOffset = _controller.selection.baseOffset;
          // selection을 항상 clamp하여 out-of-range 방지
          final clampedOffset = oldOffset.clamp(0, max);
          _controller.value = _controller.value.copyWith(
            text: next,
            selection: TextSelection.collapsed(offset: clampedOffset),
          );
          _isUpdatingController = false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journeyComposeControllerProvider);

    // 리스너 설정 (1회만 등록되도록 보장)
    if (_messageSubscription == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setupListeners(l10n);
        }
      });
    }

    final validationError = _validationError(l10n, state.content);
    final canGoNextFromMessage =
        validationError == null && state.content.trim().isNotEmpty;
    final canGoNextFromRecipient = state.recipientCount != null;
    final canSubmit = canGoNextFromMessage && canGoNextFromRecipient;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // didPop이 true면 이미 pop이 일어났으므로 처리 불필요
        if (didPop) {
          return;
        }
        // 중복 실행 방지
        if (_isHandlingBack) {
          if (kDebugMode) {
            debugPrint('[ComposeBackTrace] PopScope 중복 실행 방지');
          }
          return;
        }
        // pop이 막혔으므로 화면 내 인라인 확인 바로 처리
        _isHandlingBack = true;
        try {
          await _handleBack(context, state);
        } finally {
          _isHandlingBack = false;
        }
      },
      child: AppScaffold(
        appBar: AppHeader(
          title: l10n.composeTitle,
          alignTitleLeft: true,
          trailingIcon: Icons.close,
          onTrailingTap: () => _handleBack(context, state),
          trailingSemanticLabel: l10n.commonClose,
        ),
        bodyPadding: EdgeInsets.zero,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // 배경 데코 (토큰 기반 글로우 색상 사용)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.8, -0.9),
                      radius: 1.2,
                      colors: [
                        AppColors.secondaryGlowStrong,
                        AppColors.background,
                      ],
                      stops: const [0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.9, 0.6),
                      radius: 1.1,
                      colors: [
                        AppColors.secondaryGlowSoft,
                        AppColors.background,
                      ],
                      stops: const [0, 0.75],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                // 상단 진행 표시 + 스토리 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingHorizontal,
                    AppSpacing.screenPaddingTop,
                    AppSpacing.screenPaddingHorizontal,
                    AppSpacing.spacing12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ComposeProgressIndicator(stepIndex: _stepIndex),
                      const SizedBox(height: AppSpacing.spacing12),
                      _StoryHeader(
                        title: _stepTitle(l10n, _stepIndex),
                        subtitle: _stepSubtitle(l10n, _stepIndex),
                      ),
                      if (_inlineMessage != null) ...[
                        const SizedBox(height: AppSpacing.spacing12),
                        _InlineMessageBanner(
                          message: _inlineMessage!,
                          isError: _inlineMessageIsError,
                          onRetry: _inlineMessageIsError
                              ? _onInlineRetry
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
                // 스크롤 가능한 본문 영역
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingHorizontal,
                      0,
                      AppSpacing.screenPaddingHorizontal,
                      AppSpacing.sectionGap,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        final fade = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        );
                        final slide = Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(fade);
                        return FadeTransition(
                          opacity: fade,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_stepIndex),
                        child: _buildStepBody(
                          context: context,
                          l10n: l10n,
                          state: state,
                          validationError: validationError,
                        ),
                      ),
                    ),
                  ),
                ),
                // 고정 하단 액션 바 (Back/Next/Send)
                ComposeBottomBar(
                  stepIndex: _stepIndex,
                  canGoNext: switch (_stepIndex) {
                    0 => canGoNextFromMessage,
                    1 => canGoNextFromRecipient,
                    _ => canSubmit,
                  },
                  canSubmit: canSubmit,
                  isSubmitting: state.isSubmitting,
                  onBack: _stepIndex > 0
                      ? () {
                          setState(() {
                            _stepIndex = (_stepIndex - 1).clamp(0, 2);
                          });
                        }
                      : null,
                  onNext: () => _handleNext(
                    l10n: l10n,
                    state: state,
                    validationError: validationError,
                  ),
                  onSubmit: () => ref
                      .read(journeyComposeControllerProvider.notifier)
                      .submit(
                        languageTag: Localizations.localeOf(
                          context,
                        ).toLanguageTag(),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validationError(AppLocalizations l10n, String content) {
    if (content.isEmpty) {
      return null;
    }
    if (content.length > journeyMaxLength) {
      return l10n.composeTooLong;
    }
    if (containsForbiddenPattern(content)) {
      return l10n.composeForbidden;
    }
    return null;
  }

  Future<void> _handleMessage(
    AppLocalizations l10n,
    JourneyComposeMessage message,
  ) async {
    switch (message) {
      case JourneyComposeMessage.emptyContent:
        setState(() {
          _inlineMessage = l10n.composeEmpty;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.invalidContent:
        setState(() {
          _inlineMessage = l10n.composeInvalid;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.tooLong:
        setState(() {
          _inlineMessage = l10n.composeTooLong;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.forbidden:
        setState(() {
          _inlineMessage = l10n.composeForbidden;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.imageLimitExceeded:
        setState(() {
          _inlineMessage = l10n.composeImageLimit;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.permissionDenied:
        setState(() {
          _inlineMessage = l10n.composePermissionDenied;
          _inlineMessageIsError = true;
          _showPhotoSettingsCta = false;
        });
        return;
      case JourneyComposeMessage.missingSession:
        setState(() {
          _inlineMessage = l10n.composeSessionMissing;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.serverMisconfigured:
        setState(() {
          _inlineMessage = l10n.composeServerMisconfigured;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.missingRecipientCount:
        setState(() {
          _inlineMessage = l10n.composeRecipientRequired;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.invalidRecipientCount:
        setState(() {
          _inlineMessage = l10n.composeRecipientInvalid;
          _inlineMessageIsError = true;
        });
        return;
      case JourneyComposeMessage.submitFailed:
        setState(() {
          _inlineMessage = l10n.composeSubmitFailed;
          _inlineMessageIsError = true;
          _stepIndex = 2;
        });
        return;
      case JourneyComposeMessage.submitSuccess:
        setState(() {
          _inlineMessage = l10n.composeSubmitSuccess;
          _inlineMessageIsError = false;
          _stepIndex = 2;
        });

        // router와 controller를 사전에 캡처하여 context 안전성 보장
        final router = GoRouter.of(context);
        final tabController = ref.read(mainTabControllerProvider.notifier);
        final listController = ref.read(journeyListControllerProvider.notifier);

        // 성공 알럿 표시 (확인 클릭 시 보낸메세지 탭으로 이동)
        await showAppAlertDialog(
          context: context,
          title: l10n.composeSubmitSuccess,
          message: '', // 제목만으로 충분
          confirmLabel: l10n.composeOk,
          onConfirm: () {
            // 알럿이 닫힌 후 실행됨
            // 작성 화면 닫기 및 보낸메세지 탭으로 이동
            if (context.canPop()) {
              context.pop();
            }
            // 메인 화면으로 이동 (탭 구조가 있는 경우)
            router.go(AppRoutes.home);
            // 보낸메세지 탭 활성화
            tabController.switchToSentTab();
            // 보낸메세지 리스트 갱신 (방금 보낸 메시지가 바로 보이도록)
            // limit: 20으로 명시적으로 로드하여 홈 화면의 limit:3 로드가 덮어쓰지 않도록 보장
            listController.load(limit: 20);
          },
        );
        return;
    }
  }

  Future<void> _handleBack(
    BuildContext context,
    JourneyComposeState state,
  ) async {
    if (kDebugMode) {
      debugPrint('[ComposeBackTrace] _handleBack 시작');
    }

    // await 이전에 router/controller 참조 확보 (lint 회피)
    final controller = ref.read(journeyComposeControllerProvider.notifier);

    // 입력이 있으면 확인 다이얼로그 표시
    final hasInput = state.content.trim().isNotEmpty || state.images.isNotEmpty;

    if (hasInput) {
      if (kDebugMode) {
        debugPrint('[ComposeBackTrace] 입력 있음, confirm 다이얼로그 표시');
      }
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showExitConfirmDialog(
        context,
        title: l10n.exitConfirmTitle,
        message: l10n.exitConfirmMessage,
        continueLabel: l10n.exitConfirmContinue,
        leaveLabel: l10n.exitConfirmLeave,
      );
      if (confirmed != true || !mounted) {
        return;
      }
      await _leaveComposeToHome(controller);
      return;
    }

    // 입력이 없는 경우: 즉시 나가기
    await _leaveComposeToHome(controller);
  }

  Widget _buildStepBody({
    required BuildContext context,
    required AppLocalizations l10n,
    required JourneyComposeState state,
    required String? validationError,
  }) {
    switch (_stepIndex) {
      case 0:
        return _StepCard(
          accentBorder: true,
          child: ComposeMessageCard(
            controller: _controller,
            content: state.content,
            onChanged: (value) => ref
                .read(journeyComposeControllerProvider.notifier)
                .updateContent(value),
          ),
        );
      case 1:
        return _StepCard(
          accentBorder: true,
          child: ComposeRecipientCard(
            recipientCount: state.recipientCount,
            onChanged: (count) => ref
                .read(journeyComposeControllerProvider.notifier)
                .updateRecipientCount(count),
          ),
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepCard(
              child: ComposeAttachmentGrid(
                images: state.images,
                onAddImage: () async {
                  // await 이후 context 사용 금지: 상태만 업데이트 후 mounted 체크
                  final status = await ref
                      .read(journeyComposeControllerProvider.notifier)
                      .pickImages();
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _showPhotoSettingsCta = status.isPermanentlyDenied;
                  });
                },
                onRemoveImage: (index) => ref
                    .read(journeyComposeControllerProvider.notifier)
                    .removeImageAt(index),
              ),
            ),
            if (_showPhotoSettingsCta) ...[
              const SizedBox(height: AppSpacing.spacing12),
              _InlineActionCard(
                title: l10n.composePermissionTitle,
                message: l10n.composePermissionMessage,
                actionLabel: l10n.composeOpenSettings,
                onAction: () => unawaited(openAppSettings()),
              ),
            ],
          ],
        );
    }
  }

  void _handleNext({
    required AppLocalizations l10n,
    required JourneyComposeState state,
    required String? validationError,
  }) {
    setState(() {
      _inlineMessage = null;
      _showPhotoSettingsCta = false;
    });

    if (_stepIndex == 0) {
      if (validationError != null) {
        setState(() {
          _inlineMessage = validationError;
          _inlineMessageIsError = true;
        });
        return;
      }
      if (state.content.trim().isEmpty) {
        setState(() {
          _inlineMessage = l10n.composeEmpty;
          _inlineMessageIsError = true;
        });
        return;
      }
      setState(() {
        _stepIndex = 1;
      });
      return;
    }

    if (_stepIndex == 1) {
      if (state.recipientCount == null) {
        setState(() {
          _inlineMessage = l10n.composeRecipientRequired;
          _inlineMessageIsError = true;
        });
        return;
      }
      setState(() {
        _stepIndex = 2;
      });
      return;
    }
  }

  void _onInlineRetry() {
    if (_stepIndex == 2) {
      setState(() {
        _inlineMessage = null;
      });
      ref
          .read(journeyComposeControllerProvider.notifier)
          .submit(languageTag: Localizations.localeOf(context).toLanguageTag());
    }
  }

  String _stepTitle(AppLocalizations l10n, int stepIndex) {
    switch (stepIndex) {
      case 0:
        return l10n.composeWizardStep1Title;
      case 1:
        return l10n.composeWizardStep2Title;
      case 2:
      default:
        return l10n.composeWizardStep3Title;
    }
  }

  String _stepSubtitle(AppLocalizations l10n, int stepIndex) {
    switch (stepIndex) {
      case 0:
        return l10n.composeWizardStep1Subtitle;
      case 1:
        return l10n.composeWizardStep2Subtitle;
      case 2:
      default:
        return l10n.composeWizardStep3Subtitle;
    }
  }

  Future<void> _leaveComposeToHome(
    JourneyComposeController controller,
  ) async {
    // 1) Focus/Keyboard 끊기
    FocusManager.instance.primaryFocus?.unfocus();

    // 2) Controller 안전 초기화
    _isUpdatingController = true;
    _controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _isUpdatingController = false;

    // 3) Provider reset
    controller.reset();

    if (!mounted) {
      return;
    }

    TabNavigationHelper.goToHomeTab(context, ref);
  }
}

class _ComposeProgressIndicator extends StatelessWidget {
  const _ComposeProgressIndicator({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i += 1) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 8,
              decoration: BoxDecoration(
                color: i <= stepIndex
                    ? AppColors.secondary
                    : AppColors.outlineVariant,
                borderRadius: AppRadius.full,
              ),
            ),
          ),
          if (i != 2) const SizedBox(width: AppSpacing.spacing8),
        ],
      ],
    );
  }
}

class _StoryHeader extends StatelessWidget {
  const _StoryHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleLg.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.child, this.accentBorder = false});

  final Widget child;
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: accentBorder ? AppColors.secondary : AppColors.borderSubtle,
      borderWidth: accentBorder ? 1.2 : 1,
      child: child,
    );
  }
}

class _InlineMessageBanner extends StatelessWidget {
  const _InlineMessageBanner({
    required this.message,
    required this.isError,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.inlineErrorBackground
            : AppColors.inlineInfoBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isError
              ? AppColors.inlineErrorBorder
              : AppColors.inlineInfoBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError
                ? AppColors.onErrorContainer
                : AppColors.onSecondaryContainer,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: isError
                    ? AppColors.onErrorContainer
                    : AppColors.onSecondaryContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.spacing8),
            TextButton(onPressed: onRetry, child: Text(l10n.errorRetry)),
          ],
        ],
      ),
    );
  }
}

class _InlineActionCard extends StatelessWidget {
  const _InlineActionCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      borderColor: AppColors.outlineVariant,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

