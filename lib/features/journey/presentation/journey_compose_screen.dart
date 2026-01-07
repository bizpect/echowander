import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/validation/text_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_compose_controller.dart';
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
  ConsumerState<JourneyComposeScreen> createState() => _JourneyComposeScreenState();
}

class _JourneyComposeScreenState extends ConsumerState<JourneyComposeScreen> {
  late final TextEditingController _controller;
  ProviderSubscription<JourneyComposeState>? _messageSubscription;
  ProviderSubscription<String>? _contentSubscription;
  bool _isUpdatingController = false;
  bool _allowPop = false;
  bool _isHandlingBack = false;

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
    // 화면 이탈 시 작성 상태 초기화 (방어적 처리)
    final controller = ref.read(journeyComposeControllerProvider.notifier);
    controller.reset();
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
      ref.read(journeyComposeControllerProvider.notifier).updateContent(currentText);
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
        unawaited(_handleMessage(l10n, next.message!));
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
    final canSubmit = validationError == null &&
        state.content.trim().isNotEmpty &&
        state.recipientCount != null;

    return PopScope(
      canPop: _allowPop,
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
        // pop이 막혔으므로 confirm 후 처리
        _isHandlingBack = true;
        try {
          await _handleBack(context, state);
        } finally {
          _isHandlingBack = false;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.composeTitle),
          leading: Semantics(
            label: MaterialLocalizations.of(context).closeButtonTooltip,
            button: true,
            child: IconButton(
              onPressed: () => _handleBack(context, state),
              icon: const Icon(Icons.close),
            ),
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: LoadingOverlay(
          isLoading: state.isSubmitting,
          child: SafeArea(
            child: Column(
              children: [
                // 스크롤 가능한 본문 영역
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingHorizontal,
                      AppSpacing.screenPaddingTop,
                      AppSpacing.screenPaddingHorizontal,
                      AppSpacing.sectionGap,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 수신자 선택 카드
                        ComposeRecipientCard(
                          recipientCount: state.recipientCount,
                          onChanged: (count) => ref
                              .read(journeyComposeControllerProvider.notifier)
                              .updateRecipientCount(count),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // 메시지 입력 카드
                        ComposeMessageCard(
                          controller: _controller,
                          content: state.content,
                          onChanged: (value) => ref
                              .read(journeyComposeControllerProvider.notifier)
                              .updateContent(value),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),

                        // 첨부 이미지 그리드
                        ComposeAttachmentGrid(
                          images: state.images,
                          onAddImage: () async {
                            final status = await ref
                                .read(journeyComposeControllerProvider.notifier)
                                .pickImages();
                            if (status.isPermanentlyDenied) {
                              _showSettingsDialog(l10n);
                            }
                          },
                          onRemoveImage: (index) => ref
                              .read(journeyComposeControllerProvider.notifier)
                              .removeImageAt(index),
                        ),
                      ],
                    ),
                  ),
                ),

                // 고정 하단 액션 바
                ComposeBottomBar(
                  canSubmit: canSubmit,
                  isSubmitting: state.isSubmitting,
                  onSubmit: () => ref
                      .read(journeyComposeControllerProvider.notifier)
                      .submit(
                        languageTag:
                            Localizations.localeOf(context).toLanguageTag(),
                      ),
                ),
              ],
            ),
          ),
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

  Future<void> _handleMessage(AppLocalizations l10n, JourneyComposeMessage message) async {
    switch (message) {
      case JourneyComposeMessage.emptyContent:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeEmpty,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.invalidContent:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeInvalid,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.tooLong:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeTooLong,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.forbidden:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeForbidden,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.imageLimitExceeded:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeImageLimit,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.permissionDenied:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composePermissionDenied,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeSessionMissing,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.serverMisconfigured:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeServerMisconfigured,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.missingRecipientCount:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeRecipientRequired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.invalidRecipientCount:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeRecipientInvalid,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.submitFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.composeSubmitFailed,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyComposeMessage.submitSuccess:
        await showAppAlertDialog(
          context: context,
          title: l10n.composeSuccessTitle,
          message: l10n.composeSubmitSuccess,
          confirmLabel: l10n.composeOk,
        );
        if (!mounted) {
          return;
        }
        context.go(AppRoutes.journeyList);
        return;
    }
  }

  Future<void> _showSettingsDialog(AppLocalizations l10n) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.composePermissionTitle,
      message: l10n.composePermissionMessage,
      confirmLabel: l10n.composeOpenSettings,
      cancelLabel: l10n.composeCancel,
    );
    if (confirmed == true) {
      await openAppSettings();
    }
  }

  Future<void> _handleBack(BuildContext context, JourneyComposeState state) async {
    if (kDebugMode) {
      debugPrint('[ComposeBackTrace] _handleBack 시작');
    }

    // await 이전에 navigator 참조 확보 (lint 회피)
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(journeyComposeControllerProvider.notifier);

    // 입력이 있으면 확인 다이얼로그 표시
    final hasInput = state.content.trim().isNotEmpty || state.images.isNotEmpty;

    if (hasInput) {
      if (kDebugMode) {
        debugPrint('[ComposeBackTrace] 입력 있음, confirm 다이얼로그 표시');
      }

      final confirmed = await showAppConfirmDialog(
        context: context,
        title: l10n.exitConfirmTitle,
        message: l10n.exitConfirmMessage,
        confirmLabel: l10n.exitConfirmLeave,
        cancelLabel: l10n.exitConfirmContinue,
      );

      if (kDebugMode) {
        debugPrint('[ComposeBackTrace] confirm 결과: $confirmed');
      }

      if (!mounted) {
        if (kDebugMode) {
          debugPrint('[ComposeBackTrace] mounted 아님, 종료');
        }
        return;
      }

      // 취소(계속 작성) 선택 시 화면 유지
      if (confirmed != true) {
        if (kDebugMode) {
          debugPrint('[ComposeBackTrace] 취소 선택, 화면 유지');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('[ComposeBackTrace] 나가기 확정, reset 및 navigate 시작');
      }
    }

    // 나가기 확정: 순서 중요!
    // 1) Focus/Keyboard 먼저 끊기
    if (kDebugMode) {
      debugPrint('[ComposeBackTrace] Focus unfocus 시작');
    }
    FocusManager.instance.primaryFocus?.unfocus();

    // 2) Controller를 안전하게 비움 (text='' + selection=0)
    if (kDebugMode) {
      debugPrint('[ComposeBackTrace] Controller 안전하게 비우기');
    }
    _isUpdatingController = true;
    _controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _isUpdatingController = false;

    // 3) Provider reset
    if (kDebugMode) {
      debugPrint('[ComposeBackTrace] Provider reset 시작');
    }
    controller.reset();

    if (kDebugMode) {
      debugPrint('[ComposeBackTrace] reset 완료, mounted 체크');
    }

    if (!mounted) {
      if (kDebugMode) {
        debugPrint('[ComposeBackTrace] reset 후 mounted 아님, 종료');
      }
      return;
    }

    // 4) PopScope가 pop을 통과하도록 허용
    if (kDebugMode) {
      debugPrint('[ComposeBackTrace] _allowPop = true 설정');
    }
    setState(() {
      _allowPop = true;
    });

    // 5) Navigator.pop() 직접 호출 (maybePop 금지)
    if (kDebugMode) {
      debugPrint('[ComposeBackTrace] Navigator.pop() 시도');
    }
    // pop이 불가능한 경우를 대비해 fallback
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      if (kDebugMode) {
        debugPrint('[ComposeBackTrace] pop 불가, router.go(home) 실행');
      }
      router.go(AppRoutes.home);
    }
  }
}
