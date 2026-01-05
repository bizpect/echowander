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
  String get homeRecentJourneysTitle => 'Mensajes recientes';

  @override
  String get homeActionsTitle => 'Empezar';

  @override
  String get homeEmptyTitle => 'Bienvenido a EchoWander';

  @override
  String get homeEmptyDescription =>
      'Envía tu primer mensaje de relevo o revisa tu bandeja de entrada.';

  @override
  String get homeInboxCardTitle => 'Bandeja de entrada';

  @override
  String get homeInboxCardDescription =>
      'Revisa y responde los mensajes que has recibido.';

  @override
  String get homeCreateCardTitle => 'Crear mensaje';

  @override
  String get homeCreateCardDescription => 'Inicia un nuevo mensaje de relevo.';

  @override
  String get homeJourneyCardViewDetails => 'Ver detalles';

  @override
  String get homeRefresh => 'Actualizar';

  @override
  String get homeLoadFailed => 'No pudimos cargar tus datos.';

  @override
  String homeInboxCount(Object count) {
    return '$count nuevo(s)';
  }

  @override
  String get settingsCta => 'Configuración';

  @override
  String get settingsNotificationInbox => 'Bandeja de notificaciones';

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
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Aún no hay notificaciones.';

  @override
  String get notificationsUnreadOnly => 'Mostrar solo no leídas';

  @override
  String get notificationsRead => 'Leído';

  @override
  String get notificationsUnread => 'Nuevo';

  @override
  String get notificationsDeleteTitle => 'Eliminar notificación';

  @override
  String get notificationsDeleteMessage => '¿Eliminar esta notificación?';

  @override
  String get notificationsDeleteConfirm => 'Eliminar';

  @override
  String get pushJourneyAssignedTitle => 'Nuevo mensaje';

  @override
  String get pushJourneyAssignedBody => 'Llegó un nuevo mensaje de relé.';

  @override
  String get pushJourneyResultTitle => 'Resultados listos';

  @override
  String get pushJourneyResultBody => 'Tu resultado del relé está listo.';

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

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageJapanese => 'Japonés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get languageChinese => 'Chino';

  @override
  String get composeTitle => 'Escribir mensaje';

  @override
  String get composeLabel => 'Mensaje';

  @override
  String get composeHint => 'Comparte lo que piensas...';

  @override
  String composeCharacterCount(Object current, Object total) {
    return '$current/$total';
  }

  @override
  String get composeImagesTitle => 'Imágenes';

  @override
  String get composeAddImage => 'Añadir foto';

  @override
  String get composeSubmit => 'Enviar';

  @override
  String get composeCta => 'Escribir mensaje';

  @override
  String get composeTooLong => 'El mensaje es demasiado largo.';

  @override
  String get composeForbidden => 'Elimina URLs o datos de contacto.';

  @override
  String get composeEmpty => 'Escribe un mensaje.';

  @override
  String get composeInvalid => 'Revisa el contenido del mensaje.';

  @override
  String get composeImageLimit => 'Puedes adjuntar hasta 3 imágenes.';

  @override
  String get composePermissionDenied =>
      'Se necesita acceso a fotos para adjuntar imágenes.';

  @override
  String get composeSessionMissing => 'Inicia sesión de nuevo.';

  @override
  String get composeSubmitFailed =>
      'No pudimos enviar tu mensaje. Inténtalo de nuevo.';

  @override
  String get composeServerMisconfigured =>
      'La configuración del servicio no está lista. Inténtalo más tarde.';

  @override
  String get composeSubmitSuccess => 'Tu mensaje fue enviado.';

  @override
  String get composeRecipientCountLabel => 'Cantidad de relés';

  @override
  String get composeRecipientCountHint => 'Selecciona de 1 a 5 personas.';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count personas';
  }

  @override
  String get composeRecipientRequired =>
      'Selecciona cuántas personas recibirán el mensaje.';

  @override
  String get composeRecipientInvalid =>
      'Solo puedes seleccionar entre 1 y 5 personas.';

  @override
  String get composeErrorTitle => 'Aviso';

  @override
  String get composeSuccessTitle => 'Listo';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Cancelar';

  @override
  String get composePermissionTitle => 'Permitir acceso a fotos';

  @override
  String get composePermissionMessage =>
      'Abre Ajustes para permitir acceso a fotos.';

  @override
  String get composeOpenSettings => 'Abrir ajustes';

  @override
  String get journeyListTitle => 'Mensajes enviados';

  @override
  String get journeyListEmpty => 'Aún no hay mensajes enviados.';

  @override
  String get journeyListCta => 'Ver mensajes enviados';

  @override
  String get journeyListStatusLabel => 'Estado:';

  @override
  String get journeyStatusCreated => 'Enviado';

  @override
  String get journeyStatusWaiting => 'En espera de emparejamiento';

  @override
  String get journeyStatusCompleted => 'Completado';

  @override
  String get journeyStatusUnknown => 'Desconocido';

  @override
  String get journeyFilterOk => 'Permitido';

  @override
  String get journeyFilterHeld => 'En revisión';

  @override
  String get journeyFilterRemoved => 'Eliminado';

  @override
  String get journeyFilterUnknown => 'Desconocido';

  @override
  String get inboxTitle => 'Bandeja de entrada';

  @override
  String get inboxEmpty => 'Aún no hay mensajes recibidos.';

  @override
  String get inboxCta => 'Ver bandeja de entrada';

  @override
  String get inboxRefresh => 'Actualizar';

  @override
  String get inboxLoadFailed => 'No pudimos cargar tu bandeja de entrada.';

  @override
  String inboxImageCount(Object count) {
    return '$count foto(s)';
  }

  @override
  String get inboxStatusLabel => 'Estado:';

  @override
  String get inboxStatusAssigned => 'En espera';

  @override
  String get inboxStatusResponded => 'Respondido';

  @override
  String get inboxStatusPassed => 'Pasado';

  @override
  String get inboxStatusReported => 'Reportado';

  @override
  String get inboxStatusUnknown => 'Desconocido';

  @override
  String get inboxDetailTitle => 'Mensaje recibido';

  @override
  String get inboxDetailMissing => 'No se pudo cargar este mensaje.';

  @override
  String get inboxImagesLabel => 'Fotos';

  @override
  String get inboxImagesLoadFailed => 'No se pudieron cargar las fotos.';

  @override
  String get inboxBlockCta => 'Bloquear remitente';

  @override
  String get inboxBlockTitle => 'Bloquear usuario';

  @override
  String get inboxBlockMessage =>
      '¿Bloquear a este usuario para futuros mensajes?';

  @override
  String get inboxBlockConfirm => 'Bloquear';

  @override
  String get inboxBlockSuccessTitle => 'Bloqueado';

  @override
  String get inboxBlockSuccessBody => 'El usuario ha sido bloqueado.';

  @override
  String get inboxBlockFailed => 'No se pudo bloquear al usuario.';

  @override
  String get inboxBlockMissing => 'No pudimos identificar al remitente.';

  @override
  String get inboxRespondLabel => 'Responder';

  @override
  String get inboxRespondHint => 'Escribe tu respuesta...';

  @override
  String get inboxRespondCta => 'Enviar respuesta';

  @override
  String get inboxRespondEmpty => 'Ingresa una respuesta.';

  @override
  String get inboxRespondSuccessTitle => 'Respuesta enviada';

  @override
  String get inboxRespondSuccessBody => 'Tu respuesta fue enviada.';

  @override
  String get inboxPassCta => 'Pasar';

  @override
  String get inboxPassSuccessTitle => 'Pasado';

  @override
  String get inboxPassSuccessBody => 'Has pasado este mensaje.';

  @override
  String get inboxReportCta => 'Reportar';

  @override
  String get inboxReportTitle => 'Motivo del reporte';

  @override
  String get inboxReportSpam => 'Spam';

  @override
  String get inboxReportAbuse => 'Abuso';

  @override
  String get inboxReportOther => 'Otro';

  @override
  String get inboxReportSuccessTitle => 'Reporte enviado';

  @override
  String get inboxReportSuccessBody => 'Tu reporte fue enviado.';

  @override
  String get inboxActionFailed => 'No se pudo completar la acción.';

  @override
  String get journeyDetailTitle => 'Mensaje';

  @override
  String get journeyDetailMessageLabel => 'Mensaje';

  @override
  String get journeyDetailMessageUnavailable => 'No se pudo cargar el mensaje.';

  @override
  String get journeyDetailProgressTitle => 'Progreso del relé';

  @override
  String get journeyDetailStatusLabel => 'Estado';

  @override
  String get journeyDetailDeadlineLabel => 'Fecha límite del relé';

  @override
  String get journeyDetailResponseTargetLabel => 'Objetivo de respuestas';

  @override
  String get journeyDetailRespondedLabel => 'Respuestas';

  @override
  String get journeyDetailAssignedLabel => 'Asignados';

  @override
  String get journeyDetailPassedLabel => 'Pasados';

  @override
  String get journeyDetailReportedLabel => 'Reportados';

  @override
  String get journeyDetailCountriesLabel => 'Ubicaciones del relé';

  @override
  String get journeyDetailCountriesEmpty => 'Aún no hay ubicaciones.';

  @override
  String get journeyDetailResultsTitle => 'Resultados';

  @override
  String get journeyDetailResultsLocked =>
      'Los resultados aparecerán al completarse.';

  @override
  String get journeyDetailResultsEmpty => 'Aún no hay respuestas.';

  @override
  String get journeyDetailResultsLoadFailed =>
      'No se pudieron cargar los resultados.';

  @override
  String get journeyDetailLoadFailed => 'No se pudo cargar el progreso.';

  @override
  String get journeyDetailRetry => 'Reintentar';

  @override
  String get journeyDetailAdRequired =>
      'Mira un anuncio para ver los resultados.';

  @override
  String get journeyDetailAdCta => 'Ver anuncio y desbloquear';

  @override
  String get journeyDetailAdFailedTitle => 'Anuncio no disponible';

  @override
  String get journeyDetailAdFailedBody =>
      'No se pudo cargar el anuncio. ¿Ver resultados de todos modos?';

  @override
  String get journeyDetailAdFailedConfirm => 'Ver resultados';

  @override
  String get journeyResultReportCta => 'Reportar respuesta';

  @override
  String get journeyResultReportSuccessTitle => 'Reporte enviado';

  @override
  String get journeyResultReportSuccessBody => 'Tu reporte fue enviado.';

  @override
  String get journeyResultReportFailed => 'No se pudo enviar el reporte.';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsSectionNotification => 'Notificaciones';

  @override
  String get settingsNotificationToggle => 'Permitir notificaciones';

  @override
  String get settingsNotificationHint => 'Recibe actualizaciones y resultados.';

  @override
  String get settingsSectionSafety => 'Seguridad';

  @override
  String get settingsBlockedUsers => 'Usuarios bloqueados';

  @override
  String get settingsLoadFailed => 'No se pudo cargar la configuración.';

  @override
  String get settingsUpdateFailed => 'No se pudo actualizar la configuración.';

  @override
  String get blockListTitle => 'Usuarios bloqueados';

  @override
  String get blockListEmpty => 'No hay usuarios bloqueados.';

  @override
  String get blockListUnknownUser => 'Usuario desconocido';

  @override
  String get blockListLoadFailed => 'No se pudo cargar la lista de bloqueados.';

  @override
  String get blockListUnblock => 'Desbloquear';

  @override
  String get blockListUnblockTitle => 'Desbloquear usuario';

  @override
  String get blockListUnblockMessage =>
      '¿Permitir mensajes de este usuario nuevamente?';

  @override
  String get blockListUnblockConfirm => 'Desbloquear';

  @override
  String get blockListUnblockFailed => 'No se pudo desbloquear al usuario.';

  @override
  String get onboardingTitle => 'Introducción';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingNotificationTitle => 'Permiso de notificaciones';

  @override
  String get onboardingNotificationDescription =>
      'Recibe resultados y avisos importantes.';

  @override
  String get onboardingNotificationNote =>
      'No enviamos notificaciones promocionales. Puedes cambiarlo en Ajustes.';

  @override
  String get onboardingAllowNotifications => 'Permitir notificaciones';

  @override
  String get onboardingPhotoTitle => 'Acceso a fotos';

  @override
  String get onboardingPhotoDescription =>
      'Necesario para adjuntar imágenes a tu mensaje.';

  @override
  String get onboardingPhotoNote =>
      'Puedes adjuntar hasta 3 fotos. Solo accedemos a las seleccionadas.';

  @override
  String get onboardingAllowPhotos => 'Permitir acceso a fotos';

  @override
  String get onboardingGuidelineTitle => 'Normas de la comunidad';

  @override
  String get onboardingGuidelineDescription =>
      'Prohibido el acoso, el odio y compartir datos personales.';

  @override
  String get onboardingAgreeGuidelines => 'Acepto las normas de la comunidad.';

  @override
  String get onboardingContentPolicyTitle => 'Política de contenido';

  @override
  String get onboardingContentPolicyDescription =>
      'El contenido prohibido o dañino puede eliminarse.';

  @override
  String get onboardingAgreeContentPolicy => 'Acepto la política de contenido.';

  @override
  String get onboardingSafetyTitle => 'Reportar y bloquear';

  @override
  String get onboardingSafetyDescription =>
      'Puedes reportar o bloquear en cualquier momento.';

  @override
  String get onboardingConfirmSafety =>
      'Entiendo la política de reportes y bloqueo.';

  @override
  String get onboardingSkip => 'Ahora no';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get exitConfirmTitle => '¿Cancelar escritura?';

  @override
  String get exitConfirmMessage => 'Se perderá tu entrada.';

  @override
  String get exitConfirmContinue => 'Seguir escribiendo';

  @override
  String get exitConfirmLeave => 'Salir';

  @override
  String get tabHomeLabel => 'Inicio';

  @override
  String get tabInboxLabel => 'Bandeja de entrada';

  @override
  String get tabCreateLabel => 'Crear mensaje';

  @override
  String get tabAlertsLabel => 'Notificaciones';

  @override
  String get tabProfileLabel => 'Perfil';

  @override
  String get profileSignOutCta => 'Cerrar sesión';

  @override
  String get profileSignOutTitle => 'Cerrar sesión';

  @override
  String get profileSignOutMessage => '¿Seguro que quieres cerrar sesión?';

  @override
  String get profileSignOutConfirm => 'Cerrar sesión';

  @override
  String get profileUserIdLabel => 'ID de usuario';
}
