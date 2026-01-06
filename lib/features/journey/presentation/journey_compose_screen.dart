import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/presentation/widgets/app_button.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/validation/text_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_compose_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journeyComposeControllerProvider);
    final controller = ref.read(journeyComposeControllerProvider.notifier);

    ref.listen<JourneyComposeState>(journeyComposeControllerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) {
        return;
      }
      unawaited(_handleMessage(l10n, next.message!));
      controller.clearMessage();
    });

    if (_controller.text != state.content) {
      _controller.value = _controller.value.copyWith(
        text: state.content,
        selection: TextSelection.collapsed(offset: state.content.length),
      );
    }

    final validationError = _validationError(l10n, state.content);
    final canSubmit = validationError == null &&
        state.content.trim().isNotEmpty &&
        state.recipientCount != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context, state);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.composeTitle),
          leading: IconButton(
            onPressed: () => _handleBack(context, state),
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: LoadingOverlay(
          isLoading: state.isSubmitting,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.spacing16,
                    AppSpacing.spacing16,
                    AppSpacing.spacing16,
                    AppSpacing.spacing24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 텍스트 입력 필드
                        TextField(
                          controller: _controller,
                          onChanged: controller.updateContent,
                          maxLength: journeyMaxLength,
                          maxLines: 6,
                          textInputAction: TextInputAction.newline,
                          buildCounter: (
                            context, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) =>
                              null,
                          decoration: InputDecoration(
                            labelText: l10n.composeLabel,
                            hintText: l10n.composeHint,
                            errorText: validationError,
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacing8),

                        // 글자수 카운터
                        Text(
                          l10n.composeCharacterCount(
                            state.content.length,
                            journeyMaxLength,
                          ),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: state.content.length > journeyMaxLength
                                    ? AppColors.error
                                    : AppColors.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: AppSpacing.spacing16),

                        // 이미지 섹션
                        _ImageSection(
                          images: state.images,
                          onAddImage: () async {
                            final status = await controller.pickImages();
                            if (status.isPermanentlyDenied) {
                              _showSettingsDialog(l10n);
                            }
                          },
                          onRemoveImage: controller.removeImageAt,
                        ),
                        const SizedBox(height: AppSpacing.spacing16),

                        // 릴레이 수 선택
                        DropdownButtonFormField<int>(
                          key: ValueKey(state.recipientCount),
                          initialValue: state.recipientCount,
                          items: List.generate(
                            5,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text(
                                l10n.composeRecipientCountOption(index + 1),
                              ),
                            ),
                          ),
                          onChanged: controller.updateRecipientCount,
                          decoration: InputDecoration(
                            labelText: l10n.composeRecipientCountLabel,
                            hintText: l10n.composeRecipientCountHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacing24),

                        // 전송 버튼
                        AppFilledButton(
                          onPressed: canSubmit
                              ? () => controller.submit(
                                    languageTag:
                                        Localizations.localeOf(context).toLanguageTag(),
                                  )
                              : null,
                          isLoading: state.isSubmitting,
                          child: Text(l10n.composeSubmit),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
    final l10n = AppLocalizations.of(context)!;

    // 입력이 있으면 확인 다이얼로그 표시
    final hasInput = state.content.trim().isNotEmpty || state.images.isNotEmpty;

    if (hasInput) {
      final confirmed = await showAppConfirmDialog(
        context: context,
        title: l10n.exitConfirmTitle,
        message: l10n.exitConfirmMessage,
        confirmLabel: l10n.exitConfirmLeave,
        cancelLabel: l10n.exitConfirmContinue,
      );

      if (!mounted) {
        return;
      }

      if (confirmed != true) {
        return;
      }
    }

    // 뒤로가기 실행 (BuildContext 사용 전 mounted 체크 완료)
    // ignore: use_build_context_synchronously
    final canPop = context.canPop();
    if (canPop) {
      // ignore: use_build_context_synchronously
      context.pop();
    } else {
      // ignore: use_build_context_synchronously
      context.go(AppRoutes.home);
    }
  }
}

/// 이미지 섹션
class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.images,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  final List<XFile> images;
  final VoidCallback onAddImage;
  final void Function(int index) onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.composeImagesTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Wrap(
          spacing: AppSpacing.spacing12,
          runSpacing: AppSpacing.spacing12,
          children: [
            for (var i = 0; i < images.length; i += 1)
              _ImageTile(
                file: images[i],
                onRemove: () => onRemoveImage(i),
              ),
            if (images.length < journeyMaxImages)
              _AddImageTile(
                label: l10n.composeAddImage,
                onPressed: onAddImage,
              ),
          ],
        ),
      ],
    );
  }
}

/// 이미지 타일 (미리보기 + 제거 버튼)
class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.file,
    required this.onRemove,
  });

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppRadius.medium,
          child: Image.file(
            File(file.path),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: AppSpacing.spacing4,
          right: AppSpacing.spacing4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 이미지 추가 타일
class _AddImageTile extends StatelessWidget {
  const _AddImageTile({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
        ),
        minimumSize: const Size(96, 96),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_photo_alternate, size: 32),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
