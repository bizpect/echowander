enum SessionStatus {
  unknown,
  authenticated,
  unauthenticated,
  refreshing, // restoreSession 진행 중 (401 폭주 방지)
}

enum SessionMessage {
  genericError,
  loginFailed,
  loginCancelled,
  loginNetworkError,
  loginInvalidToken,
  loginUnsupportedProvider,
  loginUserSyncFailed,
  loginServiceUnavailable,
  sessionExpired,

  /// 세션 갱신 일시 장애 (네트워크/서버 문제, 로그아웃 아님)
  authRefreshFailed,
}

class SessionState {
  const SessionState({
    required this.status,
    this.isBusy = false,
    this.message,
    this.accessToken,
  });

  const SessionState.unknown()
      : status = SessionStatus.unknown,
        isBusy = false,
        message = null,
        accessToken = null;

  final SessionStatus status;
  final bool isBusy;
  final SessionMessage? message;
  final String? accessToken;

  SessionState copyWith({
    SessionStatus? status,
    bool? isBusy,
    SessionMessage? message,
    String? accessToken,
    bool resetMessage = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      isBusy: isBusy ?? this.isBusy,
      message: resetMessage ? null : (message ?? this.message),
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
