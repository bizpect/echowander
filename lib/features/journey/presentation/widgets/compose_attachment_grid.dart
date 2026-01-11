import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/compose_picked_image.dart';

const int journeyMaxImages = 3;
const double _imageCardHeight = 200.0; // 이미지 카드 높이
const double _pageViewPadding = 16.0; // PageView 좌우 패딩

/// 첨부 이미지 그리드 (PageView 기반)
///
/// 상단: 점선 테두리 등록 카드 (빈 상태)
/// 하단: PageView로 이미지 카드 슬라이드 (한 화면에 하나씩)
class ComposeAttachmentGrid extends StatefulWidget {
  const ComposeAttachmentGrid({
    super.key,
    required this.images,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  final List<ComposePickedImage> images;
  final VoidCallback onAddImage;
  final void Function(int index) onRemoveImage;

  @override
  State<ComposeAttachmentGrid> createState() => _ComposeAttachmentGridState();
}

class _ComposeAttachmentGridState extends State<ComposeAttachmentGrid> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentPage = 0;
  }

  @override
  void didUpdateWidget(ComposeAttachmentGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 이미지 개수가 변경되었을 때 인덱스 보정
    if (widget.images.length != oldWidget.images.length) {
      final newLength = widget.images.length;
      if (newLength == 0) {
        _currentPage = 0;
      } else if (_currentPage >= newLength) {
        _currentPage = newLength - 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients && mounted) {
            _pageController.jumpToPage(_currentPage);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleRemoveImage(int index) {
    widget.onRemoveImage(index);
    // 삭제 후 인덱스 보정
    final newLength = widget.images.length - 1;
    if (newLength > 0) {
      if (_currentPage >= newLength) {
        _currentPage = newLength - 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients && mounted) {
            _pageController.jumpToPage(_currentPage);
          }
        });
      }
    } else {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canAddMore = widget.images.length < journeyMaxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 상단: 점선 테두리 등록 카드 (빈 상태 또는 추가 진입)
        if (widget.images.isEmpty || canAddMore)
          _ImageUploadCard(
            onTap: canAddMore ? widget.onAddImage : null,
            label: l10n.composeImageUploadHint,
          ),
        // 하단: PageView로 이미지 카드 슬라이드
        if (widget.images.isNotEmpty) ...[
          // 섹션 구분: 충분한 간격 (텍스트/Divider 없이 spacing만)
          const SizedBox(height: AppSpacing.sectionGap),
          // 이미지 카드 슬라이드
          SizedBox(
            height: _imageCardHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _pageViewPadding,
                  ),
                  child: _ImageCard(
                    image: widget.images[index],
                    onRemove: () => _handleRemoveImage(index),
                    deleteLabel: l10n.composeImageDelete,
                  ),
                );
              },
            ),
          ),
          // 페이지 인디케이터
          if (widget.images.length > 1) ...[
            const SizedBox(height: AppSpacing.spacing12),
            _PageIndicator(
              currentIndex: _currentPage,
              itemCount: widget.images.length,
            ),
          ],
        ],
      ],
    );
  }
}

/// 점선 테두리 이미지 업로드 카드
class _ImageUploadCard extends StatelessWidget {
  const _ImageUploadCard({
    required this.onTap,
    required this.label,
  });

  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;

    return Semantics(
      label: label,
      button: isEnabled,
      enabled: isEnabled,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.large,
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: isEnabled
                  ? AppColors.outline
                  : AppColors.outlineVariant,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: isEnabled
                        ? AppColors.iconPrimary
                        : AppColors.iconMuted,
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 점선 테두리 CustomPainter
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          AppRadius.largeRadius,
        ),
      );

    // 점선 패턴: dashLength = 8, gapLength = 4
    final dashLength = 8.0;
    final gapLength = 4.0;
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      var distance = 0.0;
      while (distance < pathMetric.length) {
        final extractLength = (distance + dashLength < pathMetric.length)
            ? dashLength
            : pathMetric.length - distance;
        final extractPath = pathMetric.extractPath(
          distance,
          distance + extractLength,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// 이미지 카드 (PageView용)
class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.image,
    required this.onRemove,
    required this.deleteLabel,
  });

  final ComposePickedImage image;
  final VoidCallback onRemove;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: AppColors.overlaySubtle,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.large,
        child: Stack(
          children: [
            // 이미지
            Positioned.fill(
              child: Image.file(
                File(image.localPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceVariant,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.iconMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
            // 삭제 버튼 (우상단 오버레이)
            Positioned(
              top: AppSpacing.spacing8,
              right: AppSpacing.spacing8,
              child: Semantics(
                label: deleteLabel,
                button: true,
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    borderRadius: AppRadius.full,
                    child: Container(
                      width: AppSpacing.minTouchTarget,
                      height: AppSpacing.minTouchTarget,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.overlaySubtle,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 페이지 인디케이터
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentIndex,
    required this.itemCount,
  });

  final int currentIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < itemCount; i += 1) ...[
          Container(
            width: i == currentIndex ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i == currentIndex
                  ? AppColors.primary
                  : AppColors.outlineVariant,
              borderRadius: AppRadius.full,
            ),
          ),
        ],
      ],
    );
  }
}
