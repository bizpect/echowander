import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/permissions/app_permission_service.dart';
import '../../../core/presentation/widgets/app_button.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/validation/nickname_validator.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

import '../application/avatar_signed_url_provider.dart';
import '../application/profile_edit_controller.dart';
import '../data/supabase_profile_repository.dart' show ProfileError;

const _logPrefix = '[ProfileEditScreen]';

/// 프로필 편집 화면 (토스 스타일)
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    // 초기 닉네임 설정 (컨트롤러 로드 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(profileEditControllerProvider);
      if (state.nickname.isNotEmpty) {
        _nicknameController.text = state.nickname;
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(profileEditControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 닉네임 컨트롤러 동기화
    if (_nicknameController.text != state.nickname) {
      _nicknameController.text = state.nickname;
    }

    return AppScaffold(
      appBar: AppHeader(
        title: l10n.profileEditTitle,
        alignTitleLeft: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.pagePadding.copyWith(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xl,
                ),
                children: [
                  // 프로필 사진 카드
                  _ProfileAvatarCard(
                    avatarBytes: state.avatarBytes,
                    originalAvatarPath: state.originalAvatarPath,
                    onTap: () => _pickImage(context, l10n),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 닉네임 카드
                  _NicknameCard(
                    controller: _nicknameController,
                    validation: state.nicknameValidation,
                    availability: state.nicknameAvailability,
                    availabilityNorm: state.availabilityNorm,
                    currentNickname: state.nickname,
                    onChanged: (value) {
                      ref.read(profileEditControllerProvider.notifier)
                          .updateNickname(value);
                    },
                    l10n: l10n,
                  ),
                ],
              ),
            ),

            // 하단 고정 CTA
            Container(
              padding: AppSpacing.pagePadding.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text(l10n.profileEditCancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 1,
                      child: AppFilledButton(
                        onPressed: state.canSave
                            ? () => _handleSave(context, l10n)
                            : null,
                        isLoading: state.isSaving,
                        child: Text(l10n.profileEditSave),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final permissionService = ref.read(appPermissionServiceProvider);
    final permission = await permissionService.requestPhotoPermission();
    if (!permission.isGranted && !permission.isLimited) {
      if (!permission.isPermanentlyDenied && context.mounted) {
        await showAppAlertDialog(
          context: context,
          title: l10n.profileEditTitle,
          message: l10n.profileEditSaveFailed,
          confirmLabel: l10n.commonOk,
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !context.mounted) {
      return;
    }

    // 원형 크롭 화면으로 이동
    final imageBytes = await picked.readAsBytes();
    if (!context.mounted) return;

    final croppedBytes = await context.push<Uint8List>(
      AppRoutes.profileEditCrop,
      extra: imageBytes,
    );

    if (croppedBytes != null) {
      ref.read(profileEditControllerProvider.notifier)
          .updateAvatar(croppedBytes);
    }
  }

  Future<void> _handleSave(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final success = await ref.read(profileEditControllerProvider.notifier)
        .save();

    if (!context.mounted) return;

    if (success) {
      await showAppAlertDialog(
        context: context,
        title: l10n.profileEditTitle,
        message: l10n.profileEditSaveSuccess,
        confirmLabel: l10n.commonOk,
      );
      if (!context.mounted) return;
      context.pop();
    } else {
      // 에러 메시지 결정
      String errorMessage = l10n.profileEditSaveFailed;
      final controller = ref.read(profileEditControllerProvider.notifier);
      final lastError = controller.lastError;
      
      if (lastError != null) {
        switch (lastError) {
          case ProfileError.imageTooLarge:
            errorMessage = l10n.profileEditImageTooLarge;
            break;
          case ProfileError.imageOptimizationFailed:
            errorMessage = l10n.profileEditImageOptimizationFailed;
            break;
          case ProfileError.nicknameForbidden:
            errorMessage = l10n.nicknameForbiddenMessage;
            break;
          case ProfileError.nicknameTaken:
            errorMessage = l10n.nicknameTakenMessage;
            break;
          default:
            errorMessage = l10n.profileEditSaveFailed;
        }
      }

      await showAppAlertDialog(
        context: context,
        title: l10n.profileEditTitle,
        message: errorMessage,
        confirmLabel: l10n.commonOk,
      );
    }
  }
}

/// 프로필 사진 카드
class _ProfileAvatarCard extends ConsumerWidget {
  const _ProfileAvatarCard({
    required this.avatarBytes,
    required this.originalAvatarPath,
    required this.onTap,
  });

  final Uint8List? avatarBytes;
  final String? originalAvatarPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // signed URL 가져오기
    final signedUrlAsync = ref.watch(
      avatarSignedUrlProvider(originalAvatarPath),
    );
    
    // 오버레이 컨텍스트 규칙: scrim 배경 + onInverseSurface 전경 (오버레이 위 콘텐츠 대비)
    final overlayBg = colorScheme.scrim; // 오버레이 배경 (딤 처리)
    final overlayFg = colorScheme.onInverseSurface; // 오버레이 위 아이콘/텍스트 전경색
    // NOTE: 프로젝트에서는 onInverseSurface를 scrim overlay 전경색으로 사용(일반 Material 의미와 다를 수 있음)

    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          // 원형 아바타
          GestureDetector(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: avatarBytes != null
                      ? MemoryImage(avatarBytes!)
                      : (signedUrlAsync.value != null
                          ? Image.network(
                              signedUrlAsync.value!,
                              errorBuilder: (context, error, stackTrace) {
                                // 404 등 에러 시 기본 아바타로 폴백
                                if (kDebugMode) {
                                  debugPrint(
                                    '$_logPrefix NetworkImage 에러: $error',
                                  );
                                }
                                // 빈 위젯 반환 → backgroundImage가 null이 되어 child가 표시됨
                                return const SizedBox.shrink();
                              },
                            ).image
                          : null),
                  child: avatarBytes == null &&
                          (signedUrlAsync.value == null ||
                              signedUrlAsync.value!.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                // 오버레이 (사진 변경 힌트)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: overlayBg,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: overlayFg,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 사진 변경 버튼
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.edit, size: 18),
            label: Text(
              AppLocalizations.of(context)!.profileEditAvatarChange,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// 닉네임 카드
class _NicknameCard extends StatelessWidget {
  const _NicknameCard({
    required this.controller,
    required this.validation,
    required this.availability,
    required this.availabilityNorm,
    required this.currentNickname,
    required this.onChanged,
    required this.l10n,
  });

  final TextEditingController controller;
  final NicknameValidationResult validation;
  final NicknameAvailabilityStatus availability;
  final String? availabilityNorm; // available/taken 결과가 어떤 norm에 대한 것인지
  final String currentNickname; // 현재 입력값
  final ValueChanged<String> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라벨
          Text(
            l10n.profileEditNicknameLabel,
            style: AppTextStyles.titleSm.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // TextField
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: l10n.profileEditNicknameHint,
              errorText: _getErrorText(),
              helperText: _getHelperText(),
              helperMaxLines: 2,
            ),
            maxLength: NicknameValidator.maxLength,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NicknameValidator.maxLength),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 규칙 안내
          Text(
            l10n.profileEditNicknameInvalidCharacters,
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String? _getErrorText() {
    if (!validation.isValid && validation.error != null) {
      final l10n = this.l10n;
      switch (validation.error!) {
        case NicknameValidationError.empty:
          return l10n.profileEditNicknameEmpty;
        case NicknameValidationError.tooShort:
          return l10n.profileEditNicknameTooShort(NicknameValidator.minLength);
        case NicknameValidationError.tooLong:
          return l10n.profileEditNicknameTooLong(NicknameValidator.maxLength);
        case NicknameValidationError.consecutiveSpaces:
          return l10n.profileEditNicknameConsecutiveSpaces;
        case NicknameValidationError.invalidCharacters:
          return l10n.profileEditNicknameInvalidCharacters;
        case NicknameValidationError.underscoreAtEnds:
          return l10n.profileEditNicknameUnderscoreAtEnds;
        case NicknameValidationError.consecutiveUnderscores:
          return l10n.profileEditNicknameConsecutiveUnderscores;
        case NicknameValidationError.forbiddenWord:
          return l10n.profileEditNicknameForbidden;
      }
    }
    return null;
  }

  String? _getHelperText() {
    if (!validation.isValid) {
      return null;
    }

    // ✅ UI 표시 조건을 canSave와 동일하게: availabilityNorm == currentNorm일 때만 표시
    final currentNorm = NicknameValidator.normalize(currentNickname.trim());
    
    switch (availability) {
      case NicknameAvailabilityStatus.checking:
        return l10n.profileEditNicknameChecking;
      case NicknameAvailabilityStatus.available:
        // "사용 가능" 표시는 availabilityNorm == currentNorm일 때만
        if (availabilityNorm == currentNorm) {
          return l10n.profileEditNicknameAvailable;
        }
        // availabilityNorm 불일치 시 표시하지 않음 (스테일 표시 방지)
        return null;
      case NicknameAvailabilityStatus.taken:
        // "사용 중" 표시도 availabilityNorm == currentNorm일 때만
        if (availabilityNorm == currentNorm) {
          return l10n.profileEditNicknameTaken;
        }
        // availabilityNorm 불일치 시 표시하지 않음
        return null;
      case NicknameAvailabilityStatus.error:
        return l10n.profileEditNicknameError;
      case NicknameAvailabilityStatus.idle:
        return null;
    }
  }
}
