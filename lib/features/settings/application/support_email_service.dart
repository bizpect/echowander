import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/support_config.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/session/auth_executor.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _logPrefix = '[SupportEmailService]';

/// 지원 이메일 서비스
class SupportEmailService {
  /// 건의사항 요청 메일 작성
  static Future<void> composeSuggestion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final sessionState = ref.read(sessionManagerProvider);
    final accessToken = sessionState.accessToken;

    String? userId;
    if (accessToken != null) {
      userId = JwtUtils.getUserId(accessToken);
    }
    userId ??= 'unknown';

    String? version;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.version;
      if (packageInfo.buildNumber.isNotEmpty) {
        version = '$version+${packageInfo.buildNumber}';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 버전 획득 실패: $e');
      }
      version = 'unknown';
    }

    final subject = l10n.supportSuggestionSubject;
    final footerUser = l10n.supportEmailFooterUser(userId);
    final footerVersion = l10n.supportEmailFooterVersion(version);
    final body = '\n\n$footerUser\n$footerVersion';

    if (!context.mounted) return;
    await _launchEmail(
      context: context,
      subject: subject,
      body: body,
      l10n: l10n,
    );
  }

  /// 오류사항 제보 메일 작성
  static Future<void> composeBug(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final sessionState = ref.read(sessionManagerProvider);
    final accessToken = sessionState.accessToken;

    String? userId;
    if (accessToken != null) {
      userId = JwtUtils.getUserId(accessToken);
    }
    userId ??= 'unknown';

    String? version;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.version;
      if (packageInfo.buildNumber.isNotEmpty) {
        version = '$version+${packageInfo.buildNumber}';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 버전 획득 실패: $e');
      }
      version = 'unknown';
    }

    final subject = l10n.supportBugSubject;
    final footerUser = l10n.supportEmailFooterUser(userId);
    final footerVersion = l10n.supportEmailFooterVersion(version);
    final body = '\n\n$footerUser\n$footerVersion';

    if (!context.mounted) return;
    await _launchEmail(
      context: context,
      subject: subject,
      body: body,
      l10n: l10n,
    );
  }

  /// 메일 앱 실행
  static Future<void> _launchEmail({
    required BuildContext context,
    required String subject,
    required String body,
    required AppLocalizations l10n,
  }) async {
    try {
      final email = SupportConfig.supportEmail;
      
      // Uri.encodeComponent를 사용하여 %20 기반 인코딩 (form-encoding의 + 방지)
      final subjectEncoded = Uri.encodeComponent(subject);
      final bodyEncoded = Uri.encodeComponent(body);
      
      // queryParameters 대신 직접 query 문자열 구성 (재발 방지)
      final uri = Uri.parse('mailto:$email?subject=$subjectEncoded&body=$bodyEncoded');

      // Android 11+ package visibility를 위해 queries가 필요하지만,
      // canLaunchUrl이 실패할 수 있으므로 직접 launchUrl 시도
      // mode: LaunchMode.externalApplication으로 명시하여 외부 앱 실행
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (!context.mounted) return;
        await showAppAlertDialog(
          context: context,
          title: l10n.supportEmailLaunchFailed,
          message: l10n.supportEmailLaunchFailed,
          confirmLabel: l10n.commonOk,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 메일 앱 실행 실패: $e');
      }
      if (!context.mounted) return;
      await showAppAlertDialog(
        context: context,
        title: l10n.supportEmailLaunchFailed,
        message: l10n.supportEmailLaunchFailed,
        confirmLabel: l10n.commonOk,
      );
    }
  }
}
