import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import 'session_tokens.dart';

abstract class AuthRpcClient {
  Future<bool> validateSession(SessionTokens tokens);
  Future<SessionTokens?> refreshSession(SessionTokens tokens);
  Future<AuthRpcLoginResult> exchangeSocialToken({
    required String provider,
    required String idToken,
  });
}

enum AuthRpcLoginError {
  missingPayload,
  unsupportedProvider,
  invalidToken,
  userSyncFailed,
  serverMisconfigured,
  network,
  unknown,
}

class AuthRpcLoginResult {
  const AuthRpcLoginResult._({this.tokens, this.error});

  final SessionTokens? tokens;
  final AuthRpcLoginError? error;

  const AuthRpcLoginResult.success(SessionTokens tokens)
      : this._(tokens: tokens, error: null);
  const AuthRpcLoginResult.failure(AuthRpcLoginError error)
      : this._(tokens: null, error: error);
}

class DevAuthRpcClient implements AuthRpcClient {
  @override
  Future<bool> validateSession(SessionTokens tokens) async {
    return tokens.accessToken.isNotEmpty;
  }

  @override
  Future<SessionTokens?> refreshSession(SessionTokens tokens) async {
    return tokens;
  }

  @override
  Future<AuthRpcLoginResult> exchangeSocialToken({
    required String provider,
    required String idToken,
  }) async {
    return const AuthRpcLoginResult.success(
      SessionTokens(accessToken: 'dev', refreshToken: 'dev'),
    );
  }
}

class HttpAuthRpcClient implements AuthRpcClient {
  HttpAuthRpcClient({required String baseUrl, required AppConfig config})
      : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
        _errorLogger = ServerErrorLogger(config: config);

  final Uri _baseUri;
  final ServerErrorLogger _errorLogger;

  Uri _resolve(String path) => _baseUri.resolve(path);

  Future<Map<String, dynamic>?> _postJson({
    required String context,
    required Uri uri,
    required Map<String, dynamic> body,
    required String token,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final request = await HttpClient().postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      if (token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final payloadText = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        await _errorLogger.logHttpFailure(
          context: context,
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: payloadText,
          meta: meta,
          accessToken: token,
        );
        return null;
      }
      try {
        return jsonDecode(payloadText) as Map<String, dynamic>;
      } on FormatException catch (error) {
        await _errorLogger.logException(
          context: context,
          uri: uri,
          method: 'POST',
          error: error,
          errorMessage: payloadText,
          meta: meta,
          accessToken: token,
        );
        return null;
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: context,
        uri: uri,
        method: 'POST',
        error: error,
        meta: meta,
        accessToken: token,
      );
      return null;
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: context,
        uri: uri,
        method: 'POST',
        error: error,
        meta: meta,
        accessToken: token,
      );
      return null;
    }
  }

  @override
  Future<bool> validateSession(SessionTokens tokens) async {
    final payload = await _postJson(
      context: 'auth_validate_session',
      uri: _resolve('validate_session'),
      body: {'refreshToken': tokens.refreshToken},
      token: tokens.accessToken,
    );
    return payload?['valid'] == true;
  }

  @override
  Future<SessionTokens?> refreshSession(SessionTokens tokens) async {
    final payload = await _postJson(
      context: 'auth_refresh_session',
      uri: _resolve('refresh_session'),
      body: {'refreshToken': tokens.refreshToken},
      token: tokens.accessToken,
    );
    if (payload == null) {
      return null;
    }
    return SessionTokens(
      accessToken: payload['accessToken'] as String,
      refreshToken: payload['refreshToken'] as String,
    );
  }

  @override
  Future<AuthRpcLoginResult> exchangeSocialToken({
    required String provider,
    required String idToken,
  }) async {
    try {
      final uri = _resolve('login_social');
      final request = await HttpClient().postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.add(utf8.encode(jsonEncode({'provider': provider, 'idToken': idToken})));
      final response = await request.close();
      final payloadText = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        await _errorLogger.logHttpFailure(
          context: 'auth_login_social',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: payloadText,
          meta: {
            'provider': provider,
          },
          accessToken: '',
        );
        final errorCode = _extractErrorCode(payloadText);
        return AuthRpcLoginResult.failure(_mapLoginError(errorCode));
      }
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      return AuthRpcLoginResult.success(
        SessionTokens(
          accessToken: payload['accessToken'] as String,
          refreshToken: payload['refreshToken'] as String,
        ),
      );
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'auth_login_social',
        uri: _resolve('login_social'),
        method: 'POST',
        error: error,
        meta: {
          'provider': provider,
        },
        accessToken: '',
      );
      return const AuthRpcLoginResult.failure(AuthRpcLoginError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'auth_login_social',
        uri: _resolve('login_social'),
        method: 'POST',
        error: error,
        meta: {
          'provider': provider,
        },
        accessToken: '',
      );
      return const AuthRpcLoginResult.failure(AuthRpcLoginError.unknown);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'auth_login_social',
        uri: _resolve('login_social'),
        method: 'POST',
        error: error,
        meta: {
          'provider': provider,
        },
        accessToken: '',
      );
      return const AuthRpcLoginResult.failure(AuthRpcLoginError.network);
    }
  }

  String? _extractErrorCode(String payloadText) {
    try {
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      final error = payload['error'];
      if (error is String) {
        return error;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  AuthRpcLoginError _mapLoginError(String? errorCode) {
    switch (errorCode) {
      case 'missing_payload':
        return AuthRpcLoginError.missingPayload;
      case 'unsupported_provider':
        return AuthRpcLoginError.unsupportedProvider;
      case 'invalid_token':
        return AuthRpcLoginError.invalidToken;
      case 'user_sync_failed':
        return AuthRpcLoginError.userSyncFailed;
      case 'missing_secret':
        return AuthRpcLoginError.serverMisconfigured;
      default:
        return AuthRpcLoginError.unknown;
    }
  }
}
