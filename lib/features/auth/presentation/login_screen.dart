import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/auth/social_auth_service.dart';
import '../../../core/auth/social_auth_providers.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/session/session_state.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authService = ref.watch(socialAuthServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 상단: 브랜드/로고/소개
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingHorizontal,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 앱 타이틀
                    Text(
                      l10n.appTitle,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    // 소개 텍스트
                    Text(
                      l10n.loginDescription,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // 중앙: 소셜 로그인 버튼 영역
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Apple 로그인 (iOS만)
                  if (Platform.isIOS) ...[
                    SizedBox(
                      height: AppSpacing.minTouchTarget,
                      child: SignInWithAppleButton(
                        onPressed: () async {
                          final result = await authService.signInWithApple();
                          if (result.status == SocialAuthStatus.cancelled) {
                            ref
                                .read(sessionManagerProvider.notifier)
                                .reportLoginMessage(
                                  SessionMessage.loginCancelled,
                                );
                            return;
                          }
                          if (result.status == SocialAuthStatus.networkError) {
                            ref
                                .read(sessionManagerProvider.notifier)
                                .reportLoginMessage(
                                  SessionMessage.loginNetworkError,
                                );
                            return;
                          }
                          if (result.status != SocialAuthStatus.success ||
                              result.token == null) {
                            ref
                                .read(sessionManagerProvider.notifier)
                                .reportLoginMessage(SessionMessage.loginFailed);
                            return;
                          }
                          await ref
                              .read(sessionManagerProvider.notifier)
                              .signInWithSocialToken(
                                provider: 'apple',
                                idToken: result.token!,
                              );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                  ],
                  // Google 로그인 (Google Identity 브랜딩 가이드 준수: 밝은 배경, 검은색 텍스트)
                  SizedBox(
                    height: AppSpacing.minTouchTarget,
                    child: FilledButton(
                      onPressed: () async {
                        final result = await authService.signInWithGoogle();
                        if (result.status == SocialAuthStatus.cancelled) {
                          ref
                              .read(sessionManagerProvider.notifier)
                              .reportLoginMessage(
                                SessionMessage.loginCancelled,
                              );
                          return;
                        }
                        if (result.status == SocialAuthStatus.networkError) {
                          ref
                              .read(sessionManagerProvider.notifier)
                              .reportLoginMessage(
                                SessionMessage.loginNetworkError,
                              );
                          return;
                        }
                        if (result.status != SocialAuthStatus.success ||
                            result.token == null) {
                          ref
                              .read(sessionManagerProvider.notifier)
                              .reportLoginMessage(SessionMessage.loginFailed);
                          return;
                        }
                        await ref
                            .read(sessionManagerProvider.notifier)
                            .signInWithSocialToken(
                              provider: 'google',
                              idToken: result.token!,
                            );
                      },
                      style: FilledButton.styleFrom(
                        // Google Identity 가이드: 밝은 배경(흰색), 검은색 텍스트
                        backgroundColor: AppColors.surfaceInverted,
                        foregroundColor: AppColors.onSurfaceInverted,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google 로고 아이콘 (공식 색상: #4285F4 Blue)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.googleBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.g_mobiledata,
                              size: 16,
                              color: AppColors.surfaceInverted,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacing12),
                          Flexible(
                            child: Text(
                              l10n.loginGoogle,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.onSurfaceInverted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  // Kakao 로그인
                  SizedBox(
                    height: AppSpacing.minTouchTarget,
                    child: FilledButton(
                      onPressed: () async {
                        final result = await authService.signInWithKakao();
                        if (result.status == SocialAuthStatus.cancelled) {
                          ref
                              .read(sessionManagerProvider.notifier)
                              .reportLoginMessage(
                                SessionMessage.loginCancelled,
                              );
                          return;
                        }
                        if (result.status == SocialAuthStatus.networkError) {
                          ref
                              .read(sessionManagerProvider.notifier)
                              .reportLoginMessage(
                                SessionMessage.loginNetworkError,
                              );
                          return;
                        }
                        if (result.status != SocialAuthStatus.success ||
                            result.token == null) {
                          ref
                              .read(sessionManagerProvider.notifier)
                              .reportLoginMessage(SessionMessage.loginFailed);
                          return;
                        }
                        await ref
                            .read(sessionManagerProvider.notifier)
                            .signInWithSocialToken(
                              provider: 'kakao',
                              idToken: result.token!,
                            );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kakaoYellow,
                        foregroundColor: AppColors.kakaoText,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: Text(
                        l10n.loginKakao,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.kakaoText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 하단: 약관/개인정보 고지
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingHorizontal,
                AppSpacing.spacing32,
                AppSpacing.screenPaddingHorizontal,
                AppSpacing.screenPaddingBottom,
              ),
              child: Text(
                l10n.loginTerms,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceDim,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
