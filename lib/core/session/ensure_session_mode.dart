/// 세션 준비 모드
enum EnsureSessionMode {
  /// blocking: restoreSession 호출 (강제 복구)
  blocking,

  /// silent: silentRefreshIfNeeded만 시도 (조용한 갱신)
  silent,
}
