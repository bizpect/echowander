import 'package:flutter/material.dart';

/// 확인/취소 다이얼로그
///
/// 사용자에게 확인을 요청하는 다이얼로그입니다.
///
/// Returns: true (확인) / false (취소) / null (외부 탭으로 닫힘)
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

/// 단순 알림 다이얼로그
///
/// 사용자에게 정보를 알리는 다이얼로그입니다.
/// [onConfirm]이 제공되면 확인 버튼 클릭 시 실행됩니다.
Future<void> showAppAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'OK',
  VoidCallback? onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

/// 입력 이탈 방지 다이얼로그
///
/// 작성 중인 내용이 있을 때 사용자가 나가려고 하면 경고하는 다이얼로그입니다.
/// Compose 화면이나 입력 폼에서 사용합니다.
///
/// 사용 예시:
/// ```dart
/// final l10n = AppLocalizations.of(context)!;
/// final result = await showExitConfirmDialog(
///   context,
///   title: l10n.exitConfirmTitle,
///   message: l10n.exitConfirmMessage,
///   continueLabel: l10n.exitConfirmContinue,
///   leaveLabel: l10n.exitConfirmLeave,
/// );
/// ```
///
/// Returns: true (나가기) / false (계속 작성)
Future<bool?> showExitConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String continueLabel,
  required String leaveLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(continueLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(leaveLabel),
          ),
        ],
      );
    },
  );
}
