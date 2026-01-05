import '../config/app_config.dart';
import 'client_error_log_repository.dart';

class ServerErrorLogger {
  ServerErrorLogger({required AppConfig config})
      : _logRepository = ClientErrorLogRepository(config: config);

  final ClientErrorLogRepository _logRepository;

  Future<void> logHttpFailure({
    required String context,
    required Uri uri,
    required String method,
    required int? statusCode,
    String? errorMessage,
    Map<String, dynamic>? meta,
    String? accessToken,
  }) async {
    await _logRepository.logError(
      context: context,
      statusCode: statusCode,
      errorMessage: errorMessage,
      meta: _mergeMeta(
        meta: meta,
        uri: uri,
        method: method,
      ),
      accessToken: accessToken,
    );
  }

  Future<void> logException({
    required String context,
    required Uri uri,
    required String method,
    required Object error,
    String? errorMessage,
    Map<String, dynamic>? meta,
    String? accessToken,
  }) async {
    await _logRepository.logError(
      context: context,
      statusCode: null,
      errorMessage: errorMessage ?? error.toString(),
      meta: _mergeMeta(
        meta: meta,
        uri: uri,
        method: method,
        extra: {
          'exception': error.runtimeType.toString(),
        },
      ),
      accessToken: accessToken,
    );
  }

  Map<String, dynamic> _mergeMeta({
    required Uri uri,
    required String method,
    Map<String, dynamic>? meta,
    Map<String, dynamic>? extra,
  }) {
    return {
      'url': uri.toString(),
      'method': method,
      if (meta != null) ...meta,
      if (extra != null) ...extra,
    };
  }
}
