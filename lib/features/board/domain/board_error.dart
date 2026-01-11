enum BoardError {
  missingConfig,
  unauthorized,
  network,
  timeout,
  invalidPayload,
  serverRejected,
}

class BoardException implements Exception {
  const BoardException(this.error);

  final BoardError error;
}
