import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, prod, stg }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.authBaseUrl,
    required this.kakaoNativeAppKey,
    required this.googleServerClientId,
    required this.googleIosClientId,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final AppEnvironment environment;
  final String authBaseUrl;
  final String kakaoNativeAppKey;
  final String googleServerClientId;
  final String googleIosClientId;
  final String supabaseUrl;
  final String supabaseAnonKey;

  static AppConfig fromEnvironment() {
    final env = dotenv.env['APP_ENV'] ??
        const String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final authBaseUrl = dotenv.env['AUTH_BASE_URL'] ??
        const String.fromEnvironment('AUTH_BASE_URL', defaultValue: '');
    final kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ??
        const String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: '');
    final googleServerClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ??
        const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
    final googleIosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'] ??
        const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');
    final supabaseUrl = dotenv.env['APP_SUPABASE_URL'] ??
        const String.fromEnvironment('APP_SUPABASE_URL', defaultValue: '');
    final supabaseAnonKey = dotenv.env['APP_SUPABASE_ANON_KEY'] ??
        const String.fromEnvironment('APP_SUPABASE_ANON_KEY', defaultValue: '');
    return AppConfig(
      environment: _parseEnv(env),
      authBaseUrl: authBaseUrl,
      kakaoNativeAppKey: kakaoNativeAppKey,
      googleServerClientId: googleServerClientId,
      googleIosClientId: googleIosClientId,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }

  static AppEnvironment _parseEnv(String value) {
    switch (value) {
      case 'prod':
        return AppEnvironment.prod;
      case 'stg':
        return AppEnvironment.stg;
      case 'dev':
      default:
        return AppEnvironment.dev;
    }
  }
}

class AppConfigStore {
  static late AppConfig current;
}
