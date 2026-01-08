import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../presentation/widgets/app_dialog.dart';
import 'network_error.dart';

/// 네트워크 에러를 사용자 친화적인 메시지로 변환하고 표시하는 헬퍼
class NetworkErrorUI {
  /// NetworkRequestException을 사용자 친화적인 메시지로 변환
  static String getErrorMessage(
    BuildContext context,
    NetworkRequestException error,
  ) {
    final l10n = AppLocalizations.of(context)!;

    switch (error.type) {
      case NetworkErrorType.network:
        return l10n.errorNetwork;
      case NetworkErrorType.timeout:
        return l10n.errorTimeout;
      case NetworkErrorType.unauthorized:
        return l10n.errorUnauthorized;
      case NetworkErrorType.forbidden:
        return l10n.errorForbiddenMessage;
      case NetworkErrorType.serverUnavailable:
        return l10n.errorServerUnavailable;
      case NetworkErrorType.invalidPayload:
      case NetworkErrorType.serverRejected:
      case NetworkErrorType.missingConfig:
      case NetworkErrorType.unknown:
        return l10n.errorGeneric;
    }
  }

  /// 블로킹 에러 다이얼로그 표시 (재시도/취소 옵션)
  ///
  /// 블로킹 허용 플로우(메시지 전송, 답글, 신고 등)에서 사용
  ///
  /// Returns: true (재시도) / false (취소)
  static Future<bool> showBlockingError({
    required BuildContext context,
    required NetworkRequestException error,
    String? customMessage,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final message = customMessage ?? getErrorMessage(context, error);

    final result = await showAppConfirmDialog(
      context: context,
      title: l10n.errorTitle,
      message: message,
      confirmLabel: l10n.errorRetry,
      cancelLabel: l10n.errorCancel,
    );

    return result == true;
  }

  /// 논블로킹 에러 알림 표시 (확인만)
  ///
  /// 조회 플로우에서 사용
  static Future<void> showNonBlockingError({
    required BuildContext context,
    required NetworkRequestException error,
    String? customMessage,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final message = customMessage ?? getErrorMessage(context, error);

    await showAppAlertDialog(
      context: context,
      title: l10n.errorTitle,
      message: message,
      confirmLabel: l10n.composeOk,
    );
  }
}
