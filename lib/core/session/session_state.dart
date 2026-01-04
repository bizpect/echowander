enum SessionStatus { unknown, authenticated, unauthenticated }

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
}

class SessionState {
  const SessionState({
    required this.status,
    this.isBusy = false,
    this.message,
  });

  const SessionState.unknown()
      : status = SessionStatus.unknown,
        isBusy = false,
        message = null;

  final SessionStatus status;
  final bool isBusy;
  final SessionMessage? message;

  SessionState copyWith({
    SessionStatus? status,
    bool? isBusy,
    SessionMessage? message,
    bool resetMessage = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      isBusy: isBusy ?? this.isBusy,
      message: resetMessage ? null : (message ?? this.message),
    );
  }
}
