import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/router/app_router.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/fullscreen_loading.dart';
import '../../../core/validation/text_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_compose_controller.dart';

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
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.composeTitle),
          leading: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: FullScreenLoadingOverlay(
          isLoading: state.isSubmitting,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    32 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        const SizedBox(height: 8),
                        Text(
                          l10n.composeCharacterCount(
                            state.content.length,
                            journeyMaxLength,
                          ),
                          style: Theme.of(context).textTheme.labelMedium,
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 16),
                        _buildImageSection(
                          context: context,
                          l10n: l10n,
                          state: state,
                          controller: controller,
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: canSubmit
                              ? () => controller.submit(
                                    languageTag:
                                        Localizations.localeOf(context).toLanguageTag(),
                                  )
                              : null,
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

  Widget _buildImageSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required JourneyComposeState state,
    required JourneyComposeController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.composeImagesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < state.images.length; i += 1)
              _ImageTile(
                file: state.images[i],
                onRemove: () => controller.removeImageAt(i),
              ),
            if (state.images.length < journeyMaxImages)
              _AddImageTile(
                label: l10n.composeAddImage,
                onPressed: () async {
                  final status = await controller.pickImages();
                  if (status.isPermanentlyDenied) {
                    _showSettingsDialog(l10n);
                  }
                },
              ),
          ],
        ),
      ],
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

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }
}

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
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file.path),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            const Icon(Icons.add_photo_alternate),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
