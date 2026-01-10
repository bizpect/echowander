import 'package:flutter/material.dart';

import 'app_typography.dart';

/// 앱 공통 텍스트 스타일 토큰
class AppTextStyles {
  static TextStyle get titleLg => AppTypography.headlineLarge;
  static TextStyle get titleMd => AppTypography.headlineMedium;
  static TextStyle get titleSm => AppTypography.headlineSmall;
  static TextStyle get bodyLg => AppTypography.bodyLarge;
  static TextStyle get body => AppTypography.bodyMedium;
  static TextStyle get bodyStrong =>
      AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get caption => AppTypography.bodySmall;
  static TextStyle get meta => AppTypography.labelSmall;
  static TextStyle get pill => AppTypography.labelSmall;
}
