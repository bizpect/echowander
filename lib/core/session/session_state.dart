enum SessionStatus {
  unknown,
  authenticated,
  unauthenticated,
  refreshing, // restoreSession 진행 중 (401 폭주 방지)
}

enum SessionBootState {
  booting, // 앱 부팅 초기 세션 준비 단계
  ready, // 부팅 완료 (런타임 갱신은 UI에 영향 없음)
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
    this.bootState = SessionBootState.booting,
    this.isBusy = false,
    this.message,
    this.accessToken,
  });

  const SessionState.unknown()
    : status = SessionStatus.unknown,
      bootState = SessionBootState.booting,
      isBusy = false,
      message = null,
      accessToken = null;

  final SessionStatus status;
  final SessionBootState bootState;
  final bool isBusy;
  final SessionMessage? message;
  final String? accessToken;

  SessionState copyWith({
    SessionStatus? status,
    SessionBootState? bootState,
    bool? isBusy,
    SessionMessage? message,
    String? accessToken,
    bool resetMessage = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      bootState: bootState ?? this.bootState,
      isBusy: isBusy ?? this.isBusy,
      message: resetMessage ? null : (message ?? this.message),
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
