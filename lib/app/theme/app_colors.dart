import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 토큰
/// 다크 테마 기반의 Material 3 컬러 시스템
class AppColors {
  // 기본 배경 및 서피스
  static const black = Color(0xFF000000); // 완전 블랙 배경 (온보딩 등 특수 화면용)
  static const background = Color(0xFF000000); // 메인 배경 (완전 블랙 배경)
  static const surface = Color(0xFF1C1F26); // 카드/컨테이너 배경
  static const surfaceVariant = Color(0xFF2A2D35); // 보조 서피스
  static const surfaceDim = Color(0xFF161920); // 딤 처리된 서피스
  static const surfacePressed = surfaceDim; // 눌림 상태
  static const surfaceCard = surface; // 카드 기본 배경
  static const surfaceCardPressed = surfaceDim; // 카드 눌림 배경
  static const surfaceElevated = surfaceVariant; // 높은 레이어

  // 텍스트 색상
  static const onBackground = Color(0xFFE8E9ED); // 메인 텍스트 (거의 흰색)
  static const onSurface = Color(0xFFE8E9ED); // 서피스 위 텍스트
  static const onSurfaceVariant = Color(0xFF9CA3AF); // 보조 텍스트 (회색)
  static const onSurfaceDim = Color(0xFF6B7280); // 비활성 텍스트
  static const textPrimary = onSurface; // 본문 텍스트
  static const textSecondary = onSurfaceVariant; // 보조 텍스트
  static const textMuted = onSurfaceDim; // 캡션/비활성 텍스트
  static const iconPrimary = onSurface;
  static const iconMuted = onSurfaceVariant;

  // 테두리 및 구분선
  static const outline = Color(0xFF374151); // 기본 테두리
  static const outlineVariant = Color(0xFF2A2D35); // 보조 테두리
  static const divider = Color(0xFF1F2937); // 구분선
  static const borderSubtle = outlineVariant; // 얇은 보더

  // Primary (메인 브랜드 컬러 - 청록색)
  static const primary = Color(0xFF2DD4BF); // 주요 액션, 강조
  static const onPrimary = Color(0xFF0E1116); // primary 위 텍스트
  static const primaryContainer = Color(0xFF134E4A); // primary 컨테이너
  static const onPrimaryContainer = Color(0xFF99F6E4); // primaryContainer 위 텍스트

  // Secondary (보조 컬러 - 보라)
  static const secondary = Color(0xFFA78BFA); // 보조 강조
  static const onSecondary = Color(0xFF0E1116);
  static const secondaryContainer = Color(0xFF4C1D95);
  static const onSecondaryContainer = Color(0xFFDDD6FE);
  static const secondaryGlowStrong = Color(0x2EA78BFA); // 보라 글로우 (강)
  static const secondaryGlowSoft = Color(0x1FA78BFA); // 보라 글로우 (약)

  // 상태 컬러 - Success (완료, 성공)
  static const success = Color(0xFF059669); // 명도 낮춤 (기존: #10B981)
  static const onSuccess = Color(0xFF0E1116);
  static const successContainer = Color(0xFF064E3B);
  static const onSuccessContainer = Color(0xFF6EE7B7);

  // 상태 컬러 - Warning (검토 중, 주의)
  static const warning = Color(0xFFD97706); // 채도 감소 (기존: #F59E0B)
  static const onWarning = Color(0xFF0E1116);
  static const warningContainer = Color(0xFF78350F);
  static const onWarningContainer = Color(0xFFFCD34D);

  // 상태 컬러 - Error (에러, 삭제)
  static const error = Color(0xFFDC2626); // 밝기 조정 (기존: #EF4444)
  static const onError = Color(0xFF0E1116);
  static const errorContainer = Color(0xFF7F1D1D);
  static const onErrorContainer = Color(0xFFFECACA);

  // 상태/배지
  static const pillSuccessBackground = successContainer;
  static const pillSuccessForeground = onSuccessContainer;
  static const pillWarningBackground = warningContainer;
  static const pillWarningForeground = onWarningContainer;
  static const pillDangerBackground = errorContainer;
  static const pillDangerForeground = onErrorContainer;
  static const pillNeutralBackground = surfaceVariant;
  static const pillNeutralForeground = onSurfaceVariant;

  // 스켈레톤/오버레이
  static const skeletonBase = surfaceVariant;
  static const skeletonHighlight = surface;
  static const overlayScrim = Color(0xB3000000); // 다이얼로그/로딩 스크림
  static const overlaySubtle = Color(0x66000000); // 약한 스크림
  static const transparent = Color(0x00000000); // 투명
  static const surfaceInverted = onBackground; // 역배경 (라이트 버튼 등)
  static const onSurfaceInverted = black; // 역배경 위 텍스트
  static const inlineErrorBackground = Color(0x8C7F1D1D); // 인라인 에러 배경
  static const inlineErrorBorder = Color(0x66DC2626); // 인라인 에러 보더
  static const inlineInfoBackground = Color(0x8C4C1D95); // 인라인 안내 배경
  static const inlineInfoBorder = Color(0x66A78BFA); // 인라인 안내 보더

  // 소셜 로그인 브랜드
  static const googleBlue = Color(0xFF4285F4);
  static const kakaoYellow = Color(0xFFFEE500);
  static const kakaoText = Color(0xFF000000);

  // Material 3 ColorScheme 생성 헬퍼
  static ColorScheme darkColorScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      // Primary
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      // Secondary
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      // Error
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      // Surface
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      // Outline
      outline: outline,
      outlineVariant: outlineVariant,
    );
  }
}
