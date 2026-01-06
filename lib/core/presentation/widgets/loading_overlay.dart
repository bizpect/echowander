import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

/// 전체 화면 로딩 오버레이
///
/// 로딩 중일 때 화면 전체를 덮는 오버레이를 표시하고
/// 모든 사용자 입력(터치, 뒤로가기)을 차단합니다.
///
/// 사용 예시:
/// ```dart
/// LoadingOverlay(
///   isLoading: controller.isLoading,
///   child: Scaffold(...),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 로딩 중에는 뒤로가기 완전 차단
      canPop: !isLoading,
      child: Stack(
        children: [
          child,
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 커스텀 로딩 인디케이터
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.spacing16),
                      Text(
                        message!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
