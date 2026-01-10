import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';

const int journeyMaxImages = 3;

/// 첨부 이미지 그리드
///
/// 최대 3장의 이미지를 그리드 형태로 표시하고,
/// 추가/삭제 기능을 제공합니다.
class ComposeAttachmentGrid extends StatelessWidget {
  const ComposeAttachmentGrid({
    super.key,
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
    final canAddMore = images.length < journeyMaxImages;

    if (images.isEmpty && !canAddMore) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 개수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.composeImagesTitle,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (images.isNotEmpty)
                Text(
                  '${images.length}/$journeyMaxImages',
                  style: AppTextStyles.meta.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          // 이미지 그리드
          Wrap(
            spacing: AppSpacing.spacing12,
            runSpacing: AppSpacing.spacing12,
            children: [
              // 기존 이미지들
              for (var i = 0; i < images.length; i += 1)
                _ImageTile(file: images[i], onRemove: () => onRemoveImage(i)),
              // 추가 버튼
              if (canAddMore)
                _AddImageTile(
                  label: l10n.composeAddImage,
                  onPressed: onAddImage,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 이미지 타일 (미리보기 + 제거 버튼)
class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.file, required this.onRemove});

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
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: AppSpacing.spacing4,
          right: AppSpacing.spacing4,
          child: Semantics(
            label: MaterialLocalizations.of(context).deleteButtonTooltip,
            button: true,
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                borderRadius: AppRadius.full,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.onErrorContainer,
                  ),
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
  const _AddImageTile({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.medium,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: AppColors.outline,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
