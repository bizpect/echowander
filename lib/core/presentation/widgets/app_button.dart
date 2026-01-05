import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// 앱 전용 FilledButton
///
/// 로딩 상태를 지원하는 주요 액션 버튼입니다.
///
/// 사용 예시:
/// ```dart
/// AppFilledButton(
///   onPressed: () => controller.submit(),
///   isLoading: controller.isLoading,
///   child: Text('전송하기'),
/// )
/// ```
class AppFilledButton extends StatelessWidget {
  const AppFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.onPrimary,
                ),
              ),
            )
          : child,
    );
  }
}

/// 앱 전용 OutlinedButton
///
/// 보조 액션 버튼입니다.
///
/// 사용 예시:
/// ```dart
/// AppOutlinedButton(
///   onPressed: () => Navigator.pop(context),
///   child: Text('취소'),
/// )
/// ```
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
