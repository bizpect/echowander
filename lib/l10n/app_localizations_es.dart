// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => 'Iniciando...';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginKakao => 'Continuar con Kakao';

  @override
  String get loginGoogle => 'Continuar con Google';

  @override
  String get loginApple => 'Continuar con Apple';

  @override
  String get homeTitle => 'Inicio';

  @override
  String get homeGreeting => 'Bienvenido de nuevo';

  @override
  String get pushPreviewTitle => 'Notificación';

  @override
  String get pushPreviewDescription =>
      'Esta es una pantalla de prueba de enlaces profundos de notificaciones.';

  @override
  String get notificationTitle => 'Nuevo mensaje';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationDismiss => 'Cerrar';

  @override
  String get errorTitle => 'Aviso';

  @override
  String get errorGeneric => 'Ocurrió un problema. Inténtalo de nuevo.';

  @override
  String get errorLoginFailed => 'Error al iniciar sesión. Inténtalo de nuevo.';

  @override
  String get errorLoginCancelled => 'Se canceló el inicio de sesión.';

  @override
  String get errorLoginNetwork =>
      'Comprueba tu conexión de red e inténtalo de nuevo.';

  @override
  String get errorLoginInvalidToken =>
      'La verificación del inicio de sesión falló. Inténtalo de nuevo.';

  @override
  String get errorLoginUnsupportedProvider =>
      'Este método de inicio de sesión no es compatible.';

  @override
  String get errorLoginUserSyncFailed =>
      'No pudimos guardar tu cuenta. Inténtalo de nuevo.';

  @override
  String get errorLoginServiceUnavailable =>
      'El servicio de inicio de sesión no está disponible temporalmente. Inténtalo más tarde.';

  @override
  String get errorSessionExpired =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';
}
