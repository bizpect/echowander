import 'dart:convert';
import 'dart:io';

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
  HttpAuthRpcClient({required String baseUrl})
      : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');

  final Uri _baseUri;

  Uri _resolve(String path) => _baseUri.resolve(path);

  Future<Map<String, dynamic>?> _postJson(Uri uri, Map<String, dynamic> body, String token) async {
    final request = await HttpClient().postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    if (token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.write(jsonEncode(body));

    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      return null;
    }

    final payload = await response.transform(utf8.decoder).join();
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  @override
  Future<bool> validateSession(SessionTokens tokens) async {
    final payload = await _postJson(
      _resolve('validate_session'),
      {'refreshToken': tokens.refreshToken},
      tokens.accessToken,
    );
    return payload?['valid'] == true;
  }

  @override
  Future<SessionTokens?> refreshSession(SessionTokens tokens) async {
    final payload = await _postJson(
      _resolve('refresh_session'),
      {'refreshToken': tokens.refreshToken},
      tokens.accessToken,
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
      final request = await HttpClient().postUrl(_resolve('login_social'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode({'provider': provider, 'idToken': idToken}));
      final response = await request.close();
      final payloadText = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
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
    } on SocketException {
      return const AuthRpcLoginResult.failure(AuthRpcLoginError.network);
    } on FormatException {
      return const AuthRpcLoginResult.failure(AuthRpcLoginError.unknown);
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
