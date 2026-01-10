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
    required this.dispatchJobSecret,
    required this.admobAppIdAndroid,
    required this.admobAppIdIos,
    required this.admobRewardedUnitIdAndroidProd,
    required this.admobRewardedUnitIdIosProd,
  });

  final AppEnvironment environment;
  final String authBaseUrl;
  final String kakaoNativeAppKey;
  final String googleServerClientId;
  final String googleIosClientId;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String dispatchJobSecret;
  final String admobAppIdAndroid;
  final String admobAppIdIos;
  final String admobRewardedUnitIdAndroidProd;
  final String admobRewardedUnitIdIosProd;

  static AppConfig fromEnvironment() {
    final env =
        dotenv.env['APP_ENV'] ??
        const String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final authBaseUrl =
        dotenv.env['AUTH_BASE_URL'] ??
        const String.fromEnvironment('AUTH_BASE_URL', defaultValue: '');
    final kakaoNativeAppKey =
        dotenv.env['KAKAO_NATIVE_APP_KEY'] ??
        const String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: '');
    final googleServerClientId =
        dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ??
        const String.fromEnvironment(
          'GOOGLE_SERVER_CLIENT_ID',
          defaultValue: '',
        );
    final googleIosClientId =
        dotenv.env['GOOGLE_IOS_CLIENT_ID'] ??
        const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');
    final supabaseUrl =
        dotenv.env['APP_SUPABASE_URL'] ??
        const String.fromEnvironment('APP_SUPABASE_URL', defaultValue: '');
    final supabaseAnonKey =
        dotenv.env['APP_SUPABASE_ANON_KEY'] ??
        const String.fromEnvironment('APP_SUPABASE_ANON_KEY', defaultValue: '');
    final dispatchJobSecret =
        dotenv.env['APP_DISPATCH_JOB_SECRET'] ??
        const String.fromEnvironment(
          'APP_DISPATCH_JOB_SECRET',
          defaultValue: '',
        );
    final admobAppIdAndroid =
        dotenv.env['ADMOB_APP_ID_ANDROID'] ??
        const String.fromEnvironment('ADMOB_APP_ID_ANDROID', defaultValue: '');
    final admobAppIdIos =
        dotenv.env['ADMOB_APP_ID_IOS'] ??
        const String.fromEnvironment('ADMOB_APP_ID_IOS', defaultValue: '');
    final admobRewardedUnitIdAndroidProd =
        dotenv.env['ADMOB_REWARDED_UNIT_ID_ANDROID_PROD'] ??
        const String.fromEnvironment(
          'ADMOB_REWARDED_UNIT_ID_ANDROID_PROD',
          defaultValue: '',
        );
    final admobRewardedUnitIdIosProd =
        dotenv.env['ADMOB_REWARDED_UNIT_ID_IOS_PROD'] ??
        const String.fromEnvironment(
          'ADMOB_REWARDED_UNIT_ID_IOS_PROD',
          defaultValue: '',
        );
    return AppConfig(
      environment: _parseEnv(env),
      authBaseUrl: authBaseUrl,
      kakaoNativeAppKey: kakaoNativeAppKey,
      googleServerClientId: googleServerClientId,
      googleIosClientId: googleIosClientId,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      dispatchJobSecret: dispatchJobSecret,
      admobAppIdAndroid: admobAppIdAndroid,
      admobAppIdIos: admobAppIdIos,
      admobRewardedUnitIdAndroidProd: admobRewardedUnitIdAndroidProd,
      admobRewardedUnitIdIosProd: admobRewardedUnitIdIosProd,
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
