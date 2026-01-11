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

  // ========================================
  // 라이트 테마 전용 토큰
  // ========================================

  // 라이트 뉴트럴/배경
  static const backgroundLight = Color(0xFFF8FAFC); // 전체 배경
  static const surfaceLight = Color(0xFFFFFFFF); // 카드/컨테이너
  static const surfaceVariantLight = Color(0xFFF1F5F9); // 보조 서피스
  static const surfaceDimLight = Color(0xFFE2E8F0); // pressed/disabled
  static const onBackgroundLight = Color(0xFF0F172A); // 기본 본문 텍스트
  static const onSurfaceLight = Color(0xFF0F172A);
  static const onSurfaceVariantLight = Color(0xFF334155); // 보조 텍스트
  static const outlineLight = Color(0xFFCBD5E1); // 테두리
  static const outlineVariantLight = Color(0xFFE2E8F0);
  static const dividerLight = Color(0xFFE2E8F0);

  // 라이트 컨테이너 (대비 확보)
  static const primaryContainerLight = Color(0xFFCCFBF1);
  static const onPrimaryContainerLight = Color(0xFF134E4A);
  static const secondaryContainerLight = Color(0xFFEDE9FE);
  static const onSecondaryContainerLight = Color(0xFF4C1D95);
  static const successContainerLight = Color(0xFFD1FAE5);
  static const onSuccessContainerLight = Color(0xFF064E3B);
  static const warningContainerLight = Color(0xFFFFEDD5);
  static const onWarningContainerLight = Color(0xFF78350F);
  static const errorContainerLight = Color(0xFFFEE2E2);
  static const onErrorContainerLight = Color(0xFF7F1D1D);

  // 라이트 오버레이/스켈레톤
  static const overlayScrimLight = Color(0x66000000); // 다이얼로그 스크림
  static const overlaySubtleLight = Color(0x33000000);
  static const skeletonBaseLight = surfaceVariantLight;
  static const skeletonHighlightLight = surfaceLight;

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
      // surface는 scaffoldBackgroundColor용 배경색 (background)
      surface: background,
      onSurface: onSurface,
      surfaceContainerHighest: surface, // 카드/컨테이너용
      onSurfaceVariant: onSurfaceVariant,
      // Inverse Surface (프로젝트 기준: 오버레이/scrim 위 콘텐츠 대비용)
      inverseSurface: onSurface, // 오버레이 대비를 위한 보조 토큰
      onInverseSurface: background, // 오버레이 위 아이콘/텍스트 전경색 (scrim 대비)
      // NOTE: Material 기본 의미(onInverseSurface)와 다를 수 있으며, 프로젝트에서는 scrim overlay 전경색으로 사용
      // Scrim (오버레이 배경, 딤 처리 베이스)
      scrim: overlayScrim,
      // Outline
      outline: outline,
      outlineVariant: outlineVariant,
    );
  }

  /// 라이트 테마용 ColorScheme 생성
  ///
  /// 라이트 전용 토큰 기반으로 구성 (다크 복사 금지)
  static ColorScheme lightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      // Primary (브랜드 일관성 유지)
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainerLight,
      onPrimaryContainer: onPrimaryContainerLight,
      // Secondary (브랜드 일관성 유지)
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainerLight,
      onSecondaryContainer: onSecondaryContainerLight,
      // Error (브랜드 일관성 유지)
      error: error,
      onError: onError,
      errorContainer: errorContainerLight,
      onErrorContainer: onErrorContainerLight,
      // Surface (라이트 전용 토큰)
      // surface는 scaffoldBackgroundColor용 배경색 (backgroundLight)
      // 카드/컨테이너는 surfaceContainerHighest 사용
      surface: backgroundLight,
      onSurface: onSurfaceLight,
      surfaceContainerHighest: surfaceLight, // 카드/컨테이너용 완전 흰색
      onSurfaceVariant: onSurfaceVariantLight,
      // Inverse Surface (프로젝트 기준: 오버레이/scrim 위 콘텐츠 대비용)
      inverseSurface: onSurfaceLight, // 오버레이 대비를 위한 보조 토큰
      onInverseSurface: backgroundLight, // 오버레이 위 아이콘/텍스트 전경색 (scrim 대비)
      // NOTE: Material 기본 의미(onInverseSurface)와 다를 수 있으며, 프로젝트에서는 scrim overlay 전경색으로 사용
      // Scrim (오버레이 배경, 딤 처리 베이스)
      scrim: overlayScrimLight,
      // Background (라이트 전용 토큰, deprecated지만 scaffoldBackgroundColor용)
      // Note: Flutter Material 3에서 background는 deprecated되었지만,
      // scaffoldBackgroundColor는 별도로 설정해야 하므로 surface와 구분하여 설정
      // 실제로는 surface를 사용하지만, 명확성을 위해 별도로 설정
      // Outline (라이트 전용 토큰)
      outline: outlineLight,
      outlineVariant: outlineVariantLight,
    );
  }
}
