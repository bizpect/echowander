enum JourneyStorageError {
  missingConfig,
  unauthorized,
  uploadFailed,
  network,
  unknown,
}

class JourneyStorageException implements Exception {
  JourneyStorageException(this.error);

  final JourneyStorageError error;
}

abstract class JourneyStorageRepository {
  Future<List<String>> uploadImages({
    required List<String> filePaths,
    required String accessToken,
  });

  Future<void> deleteImages({
    required List<String> paths,
    required String accessToken,
  });
}
