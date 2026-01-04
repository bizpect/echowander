import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () async {
                final result = await authService.signInWithKakao();
                if (result.status == SocialAuthStatus.cancelled) {
                  ref
                      .read(sessionManagerProvider.notifier)
                      .reportLoginMessage(SessionMessage.loginCancelled);
                  return;
                }
                if (result.status == SocialAuthStatus.networkError) {
                  ref
                      .read(sessionManagerProvider.notifier)
                      .reportLoginMessage(SessionMessage.loginNetworkError);
                  return;
                }
                if (result.status != SocialAuthStatus.success || result.token == null) {
                  ref
                      .read(sessionManagerProvider.notifier)
                      .reportLoginMessage(SessionMessage.loginFailed);
                  return;
                }
                await ref.read(sessionManagerProvider.notifier).signInWithSocialToken(
                      provider: 'kakao',
                      idToken: result.token!,
                    );
              },
              child: Text(l10n.loginKakao),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                final result = await authService.signInWithGoogle();
                if (result.status == SocialAuthStatus.cancelled) {
                  ref
                      .read(sessionManagerProvider.notifier)
                      .reportLoginMessage(SessionMessage.loginCancelled);
                  return;
                }
                if (result.status == SocialAuthStatus.networkError) {
                  ref
                      .read(sessionManagerProvider.notifier)
                      .reportLoginMessage(SessionMessage.loginNetworkError);
                  return;
                }
                if (result.status != SocialAuthStatus.success || result.token == null) {
                  ref
                      .read(sessionManagerProvider.notifier)
                      .reportLoginMessage(SessionMessage.loginFailed);
                  return;
                }
                await ref.read(sessionManagerProvider.notifier).signInWithSocialToken(
                      provider: 'google',
                      idToken: result.token!,
                    );
              },
              child: Text(l10n.loginGoogle),
            ),
            const SizedBox(height: 12),
            if (Platform.isIOS)
              OutlinedButton(
                onPressed: () async {
                  final result = await authService.signInWithApple();
                  if (result.status == SocialAuthStatus.cancelled) {
                    ref
                        .read(sessionManagerProvider.notifier)
                        .reportLoginMessage(SessionMessage.loginCancelled);
                    return;
                  }
                  if (result.status == SocialAuthStatus.networkError) {
                    ref
                        .read(sessionManagerProvider.notifier)
                        .reportLoginMessage(SessionMessage.loginNetworkError);
                    return;
                  }
                  if (result.status != SocialAuthStatus.success || result.token == null) {
                    ref
                        .read(sessionManagerProvider.notifier)
                        .reportLoginMessage(SessionMessage.loginFailed);
                    return;
                  }
                  await ref.read(sessionManagerProvider.notifier).signInWithSocialToken(
                        provider: 'apple',
                        idToken: result.token!,
                      );
                },
                child: Text(l10n.loginApple),
              ),
          ],
        ),
      ),
    );
  }
}
