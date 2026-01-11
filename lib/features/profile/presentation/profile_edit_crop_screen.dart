import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/presentation/widgets/app_button.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 원형 크롭 편집 화면 (카카오톡식)
class ProfileEditCropScreen extends StatefulWidget {
  const ProfileEditCropScreen({
    super.key,
    this.imageBytes,
  });

  final Uint8List? imageBytes;

  @override
  State<ProfileEditCropScreen> createState() => _ProfileEditCropScreenState();
}

class _ProfileEditCropScreenState extends State<ProfileEditCropScreen> {
  final _cropController = CropController();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isCropping = false; // 중복 탭 방지
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.imageBytes == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '이미지가 없습니다';
      });
      return;
    }

    try {
      setState(() {
        _imageBytes = widget.imageBytes;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileEditCropScreen] 이미지 로드 실패: $e');
      }
      setState(() {
        _isLoading = false;
        _errorMessage = '이미지를 불러올 수 없습니다';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return AppScaffold(
        appBar: AppBar(
          title: Text(l10n.profileEditCropTitle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _imageBytes == null) {
      return AppScaffold(
        appBar: AppBar(
          title: Text(l10n.profileEditCropTitle),
        ),
        body: Center(
          child: Text(
            _errorMessage ?? l10n.profileEditCropDescription,
            style: AppTextStyles.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.profileEditCropTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 설명 텍스트
            Padding(
              padding: AppSpacing.pagePadding.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                l10n.profileEditCropDescription,
                style: AppTextStyles.body.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // 크롭 영역
            Expanded(
              child: Center(
                child: Crop(
                  image: _imageBytes!,
                  controller: _cropController,
                  withCircleUi: true, // 원형 UI
                  radius: 200, // 원형 크롭 반지름
                  onCropped: (dynamic result) {
                    // 완료 시 결과 반환
                    // crop_your_image 2.0.0: onCropped는 CropSuccess 또는 CropFailure를 반환
                    // 정식 타입 분기 처리
                    Uint8List? bytes;

                    // 타입 안전 분기: CropSuccess / CropFailure / Uint8List 직접 반환
                    if (result is Uint8List) {
                      // 직접 Uint8List 반환 (구버전 호환)
                      bytes = result;
                    } else {
                      // CropSuccess 또는 CropFailure 타입인 경우
                      try {
                        final dynamic cropResult = result;
                        // CropSuccess는 croppedImage 속성을 가짐
                        // 런타임에 속성 존재 여부 확인
                        if (cropResult.croppedImage != null && cropResult.croppedImage is Uint8List) {
                          bytes = cropResult.croppedImage as Uint8List;
                        } else {
                          // CropFailure 또는 예상치 못한 구조
                          if (kDebugMode) {
                            debugPrint('[ProfileEditCropScreen] onCropped: 크롭 실패 또는 예상치 못한 타입 ${result.runtimeType}');
                          }
                          if (!mounted) return;
                          setState(() => _isCropping = false);
                          _showCropFailed(context);
                          return;
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          debugPrint('[ProfileEditCropScreen] onCropped: 타입 처리 실패 $e (타입: ${result.runtimeType})');
                        }
                        if (!mounted) return;
                        setState(() => _isCropping = false);
                        _showCropFailed(context);
                        return;
                      }
                    }

                    // bytes는 위에서 이미 할당되었으므로 non-nullable
                    // (할당되지 않은 경우는 이미 return으로 빠져나감)
                    final finalBytes = bytes;
                    if (kDebugMode) {
                      debugPrint('[ProfileEditCropScreen] onCropped 호출됨, bytes 길이: ${finalBytes.length}');
                    }

                    if (!context.mounted) {
                      if (kDebugMode) {
                        debugPrint('[ProfileEditCropScreen] context.mounted=false, pop 스킵');
                      }
                      setState(() => _isCropping = false);
                      return;
                    }

                    // pop 전에 setState로 상태 복구 (pop 이후 setState 금지)
                    setState(() => _isCropping = false);

                    if (kDebugMode) {
                      debugPrint('[ProfileEditCropScreen] pop 실행됨');
                    }
                    context.pop<Uint8List>(finalBytes);
                    // ⚠️ pop 이후 setState 절대 호출 금지 (dispose 이후 호출로 이어질 수 있음)
                  },
                ),
              ),
            ),

            // 하단 CTA
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
                        child: Text(l10n.profileEditCropCancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 1,
                      child: AppFilledButton(
                        onPressed: _isCropping
                            ? null
                            : () {
                                setState(() => _isCropping = true);
                                if (kDebugMode) {
                                  debugPrint('[ProfileEditCropScreen] 완료 버튼 탭됨');
                                }
                                if (kDebugMode) {
                                  debugPrint('[ProfileEditCropScreen] cropCircle() 호출');
                                }
                                _cropController.cropCircle(); // ✅ 필수: crop 트리거
                              },
                        child: Text(l10n.profileEditCropComplete),
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

  /// 크롭 실패 시 사용자에게 안내 (프로젝트 표준 다이얼로그 사용)
  void _showCropFailed(BuildContext context) {
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context)!;

    showAppAlertDialog(
      context: context,
      title: l10n.profileEditCropFailedTitle,
      message: l10n.profileEditCropFailedMessage,
      confirmLabel: l10n.profileEditCropFailedAction,
    );
  }
}
