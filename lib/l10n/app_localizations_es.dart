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
  String get loginDescription => 'Comienza tu mensaje de relevo anónimo';

  @override
  String get loginKakao => 'Continuar con Kakao';

  @override
  String get loginGoogle => 'Continuar con Google';

  @override
  String get loginApple => 'Continuar con Apple';

  @override
  String get loginTerms => 'Al iniciar sesión, aceptas nuestros Términos de Servicio y Política de Privacidad';

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
  String get homeEmptyDescription => 'Envía tu primer mensaje de relevo o revisa tu bandeja de entrada.';

  @override
  String get homeInboxCardTitle => 'Bandeja de entrada';

  @override
  String get homeInboxCardDescription => 'Revisa y responde los mensajes que has recibido.';

  @override
  String get homeCreateCardTitle => 'Crear mensaje';

  @override
  String get homeCreateCardDescription => 'Inicia un nuevo mensaje de relevo.';

  @override
  String get homeJourneyCardViewDetails => 'Ver detalles';

  @override
  String get homeRefresh => 'Actualizar';

  @override
  String get homeExitTitle => '¿Salir de la app?';

  @override
  String get homeExitMessage => 'La app se cerrará.';

  @override
  String get homeExitCancel => 'Cancelar';

  @override
  String get homeExitConfirm => 'Salir';

  @override
  String get homeExitAdLoading => 'Cargando anuncio...';

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
  String get pushPreviewDescription => 'Esta es una pantalla de prueba de enlaces profundos de notificaciones.';

  @override
  String get notificationTitle => 'Nuevo mensaje';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationDismiss => 'Cerrar';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String notificationsUnreadCountLabel(Object count) {
    return 'Notificaciones sin leer $count';
  }

  @override
  String get notificationsUnreadCountOverflow => '9+';

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
  String get errorLoginNetwork => 'Comprueba tu conexión de red e inténtalo de nuevo.';

  @override
  String get errorLoginInvalidToken => 'La verificación del inicio de sesión falló. Inténtalo de nuevo.';

  @override
  String get errorLoginUnsupportedProvider => 'Este método de inicio de sesión no es compatible.';

  @override
  String get errorLoginUserSyncFailed => 'No pudimos guardar tu cuenta. Inténtalo de nuevo.';

  @override
  String get errorLoginServiceUnavailable => 'El servicio de inicio de sesión no está disponible temporalmente. Inténtalo más tarde.';

  @override
  String get errorSessionExpired => 'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errorForbiddenTitle => 'Permission Required';

  @override
  String get errorForbiddenMessage => 'You don\'t have permission to perform this action. Please check your login status or try again later.';

  @override
  String get journeyInboxForbiddenTitle => 'Cannot Load Inbox';

  @override
  String get journeyInboxForbiddenMessage => 'You don\'t have permission to view the inbox. If the problem persists, please sign in again.';

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
  String get composeWizardStep1Title => '¿Qué quieres enviar en tu viaje?';

  @override
  String get composeWizardStep1Subtitle => 'Escribe una frase para iniciar el relevo.';

  @override
  String get composeWizardStep2Title => '¿A cuántas personas lo enviamos?';

  @override
  String get composeWizardStep2Subtitle => 'Elige entre 10 y 50.';

  @override
  String get composeWizardStep3Title => '¿Quieres adjuntar una foto?';

  @override
  String get composeWizardStep3Subtitle => 'Hasta 3 fotos. También puedes enviarlo sin fotos.';

  @override
  String get composeWizardBack => 'Atrás';

  @override
  String get composeWizardNext => 'Siguiente';

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
  String get composeImageHelper => 'Puedes adjuntar hasta 3 fotos.';

  @override
  String get composeImageUploadHint => 'Sube una imagen.';

  @override
  String get composeImageDelete => 'Eliminar imagen';

  @override
  String get composeSelectedImagesTitle => 'Imágenes seleccionadas';

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
  String get composeImageReadFailed => 'No se pudo leer la imagen. Inténtalo de nuevo.';

  @override
  String get composeImageOptimizationFailed => 'Falló el procesamiento de la imagen. Inténtalo de nuevo.';

  @override
  String get composePermissionDenied => 'Se necesita acceso a fotos para adjuntar imágenes.';

  @override
  String get composeSessionMissing => 'Inicia sesión de nuevo.';

  @override
  String get composeSubmitFailed => 'No pudimos enviar tu mensaje. Inténtalo de nuevo.';

  @override
  String get composeServerMisconfigured => 'La configuración del servicio no está lista. Inténtalo más tarde.';

  @override
  String get composeSubmitSuccess => 'Tu mensaje fue enviado.';

  @override
  String get composeSendRequestAccepted => 'Tu solicitud de envío ha sido recibida.';

  @override
  String get composeRecipientCountLabel => 'Cantidad de relés';

  @override
  String get composeRecipientCountHint => 'Selecciona de 1 a 5 personas.';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count personas';
  }

  @override
  String get composeRecipientRequired => 'Selecciona cuántas personas recibirán el mensaje.';

  @override
  String get composeRecipientInvalid => 'Solo puedes seleccionar entre 1 y 5 personas.';

  @override
  String get composeErrorTitle => 'Aviso';

  @override
  String get composeSuccessTitle => 'Listo';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Cancelar';

  @override
  String get sessionExpiredTitle => 'Sesión Expirada';

  @override
  String get sessionExpiredBody => 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';

  @override
  String get sessionExpiredCtaLogin => 'Iniciar Sesión';

  @override
  String get sendFailedTitle => 'Envío Fallido';

  @override
  String get sendFailedTryAgain => 'No se pudo enviar el mensaje. Por favor, inténtalo de nuevo.';

  @override
  String get moderationContentBlockedMessage => 'El contenido del mensaje es inapropiado.';

  @override
  String get moderationBlockedTitle => 'No se puede enviar';

  @override
  String get nicknameForbiddenMessage => 'Tu apodo contiene palabras prohibidas.';

  @override
  String get nicknameTakenMessage => 'Este apodo ya está en uso.';

  @override
  String get composeContentBlocked => 'Este contenido no se puede enviar.';

  @override
  String get composeContentBlockedProfanity => 'No se permite lenguaje inapropiado.';

  @override
  String get composeContentBlockedSexual => 'El contenido sexual está prohibido.';

  @override
  String get composeContentBlockedHate => 'El discurso de odio está prohibido.';

  @override
  String get composeContentBlockedThreat => 'El contenido amenazante está prohibido.';

  @override
  String get replyContentBlocked => 'Este contenido no se puede enviar.';

  @override
  String get replyContentBlockedProfanity => 'No se permite lenguaje inapropiado.';

  @override
  String get replyContentBlockedSexual => 'El contenido sexual está prohibido.';

  @override
  String get replyContentBlockedHate => 'El discurso de odio está prohibido.';

  @override
  String get replyContentBlockedThreat => 'El contenido amenazante está prohibido.';

  @override
  String get composePermissionTitle => 'Permitir acceso a fotos';

  @override
  String get composePermissionMessage => 'Abre Ajustes para permitir acceso a fotos.';

  @override
  String get composeOpenSettings => 'Abrir ajustes';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get journeyListTitle => 'Mensajes enviados';

  @override
  String get sentTabInProgress => 'En curso';

  @override
  String get sentTabCompleted => 'Completado';

  @override
  String inboxSentOngoingForwardedCountLabel(Object count) {
    return 'Enviado a $count';
  }

  @override
  String inboxSentOngoingRespondedCountLabel(Object count) {
    return '$count respondieron';
  }

  @override
  String sentDispatchInProgressTitle(Object n) {
    return '¡Enviando a $n personas aleatorias!';
  }

  @override
  String get sentEmptyInProgressTitle => 'No hay mensajes en curso';

  @override
  String get sentEmptyInProgressDescription => 'Inicia un nuevo mensaje para verlo aquí.';

  @override
  String get sentEmptyCompletedTitle => 'No hay mensajes completados';

  @override
  String get sentEmptyCompletedDescription => 'Los mensajes completados aparecerán aquí.';

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
  String get journeyStatusInProgress => 'En progreso';

  @override
  String get journeyStatusUnknown => 'Desconocido';

  @override
  String get journeyInProgressHint => 'Podrás ver las respuestas después de completarse';

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
  String get inboxTabPending => 'Pendientes';

  @override
  String get inboxTabCompleted => 'Respondidas';

  @override
  String get inboxEmpty => 'Aún no hay mensajes recibidos.';

  @override
  String get inboxEmptyPendingTitle => 'No hay mensajes pendientes';

  @override
  String get inboxEmptyPendingDescription => 'Los nuevos mensajes aparecerán aquí.';

  @override
  String get inboxEmptyCompletedTitle => 'No hay mensajes completados';

  @override
  String get inboxEmptyCompletedDescription => 'Los mensajes que respondiste aparecerán aquí.';

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
  String get inboxCardArrivedPrompt => '¡Llegó un mensaje!\nDeja una respuesta.';

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
  String get inboxBlockMessage => '¿Bloquear a este usuario para futuros mensajes?';

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
  String get inboxRespondLabel => 'Mensaje';

  @override
  String get inboxRespondHint => 'Escribe tu mensaje...';

  @override
  String get inboxRespondCta => 'Enviar mensaje';

  @override
  String get inboxRespondEmpty => 'Ingresa un mensaje.';

  @override
  String get inboxRespondConfirmTitle => 'Enviar mensaje';

  @override
  String get inboxRespondConfirmMessage => '¿Desea enviar este mensaje?';

  @override
  String get inboxRespondSuccessTitle => 'Mensaje enviado';

  @override
  String get inboxRespondSuccessBody => 'Tu mensaje fue enviado.';

  @override
  String get inboxPassCta => 'Pasar';

  @override
  String get inboxPassConfirmTitle => 'Confirmar paso';

  @override
  String get inboxPassConfirmMessage => '¿Estás seguro de que quieres pasar este mensaje?';

  @override
  String get inboxPassConfirmAction => 'Pasar';

  @override
  String get inboxPassSuccessTitle => 'Pasado';

  @override
  String get inboxPassSuccessBody => 'Has pasado este mensaje.';

  @override
  String get inboxPassedTitle => 'Mensaje pasado';

  @override
  String get inboxPassedDetailUnavailable => 'Este mensaje fue pasado y el contenido no está disponible.';

  @override
  String get inboxPassedMessageTitle => 'Este mensaje fue pasado.';

  @override
  String get inboxRespondedMessageTitle => 'Respondiste a este mensaje.';

  @override
  String get inboxRespondedDetailSectionTitle => 'Mi respuesta';

  @override
  String get inboxRespondedDetailReplyUnavailable => 'No se pudo cargar tu respuesta.';

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
  String get inboxReportAlreadyReportedTitle => 'Ya reportado';

  @override
  String get inboxReportAlreadyReportedBody => 'Ya has reportado este mensaje.';

  @override
  String get inboxActionFailed => 'No se pudo completar la acción.';

  @override
  String get actionReportMessage => 'Reportar mensaje';

  @override
  String get actionBlockSender => 'Bloquear remitente';

  @override
  String get inboxDetailMoreTitle => 'Opciones';

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
  String get journeyDetailResultsTitle => 'Respuestas';

  @override
  String get journeyDetailResultsLocked => 'Las respuestas aparecerán después de completar.';

  @override
  String get journeyDetailResultsEmpty => 'Aún no hay respuestas.';

  @override
  String get journeyDetailResultsLoadFailed => 'No pudimos cargar las respuestas.';

  @override
  String get commonTemporaryErrorTitle => 'Error temporal';

  @override
  String get sentDetailRepliesLoadFailedMessage => 'No pudimos cargar las respuestas.\nVolveremos a la lista.';

  @override
  String get commonOk => 'OK';

  @override
  String get journeyDetailResponsesMissingTitle => 'Error temporal';

  @override
  String get journeyDetailResponsesMissingBody => 'No pudimos cargar las respuestas. Inténtalo de nuevo.\nVolveremos a la lista.';

  @override
  String get journeyDetailGateConfigTitle => 'Anuncio no configurado';

  @override
  String get journeyDetailGateConfigBody => 'La configuración de anuncios no está lista. Abriremos los detalles sin anuncio.';

  @override
  String get journeyDetailGateDismissedTitle => 'Anuncio no completado';

  @override
  String get journeyDetailGateDismissedBody => 'Mira el anuncio completo para ver los detalles.';

  @override
  String get journeyDetailGateFailedTitle => 'Anuncio no disponible';

  @override
  String get journeyDetailGateFailedBody => 'No pudimos cargar el anuncio. Inténtalo de nuevo.';

  @override
  String get journeyDetailUnlockFailedTitle => 'No se pudo guardar el desbloqueo';

  @override
  String get journeyDetailUnlockFailedBody => 'No pudimos guardar el desbloqueo por un problema de red/servidor. Inténtalo de nuevo.';

  @override
  String get journeyDetailGateDialogTitle => 'Desbloquea con anuncio de recompensa';

  @override
  String get journeyDetailGateDialogBody => 'Desbloquea viendo un anuncio de recompensa.\nCon una sola vez se desbloquea para siempre.';

  @override
  String get journeyDetailGateDialogConfirm => 'Desbloquear';

  @override
  String get journeyDetailLoadFailed => 'No se pudo cargar el progreso.';

  @override
  String get journeyDetailRetry => 'Reintentar';

  @override
  String get journeyDetailAdRequired => 'Mira un anuncio para ver los resultados.';

  @override
  String get journeyDetailAdCta => 'Ver anuncio y desbloquear';

  @override
  String get journeyDetailAdFailedTitle => 'Anuncio no disponible';

  @override
  String get journeyDetailAdFailedBody => 'No se pudo cargar el anuncio. ¿Ver resultados de todos modos?';

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
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

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
  String get blockListUnblockMessage => '¿Permitir mensajes de este usuario nuevamente?';

  @override
  String get blockListUnblockConfirm => 'Desbloquear';

  @override
  String get blockListUnblockFailed => 'No se pudo desbloquear al usuario.';

  @override
  String get blockUnblockedTitle => 'Completado';

  @override
  String get blockUnblockedMessage => 'Usuario desbloqueado.';

  @override
  String get onboardingTitle => 'Introducción';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingNotificationTitle => 'Permiso de notificaciones';

  @override
  String get onboardingNotificationDescription => 'Te notificaremos cuando lleguen mensajes de relevo y los resultados estén listos.';

  @override
  String get onboardingNotificationNote => 'Puedes cambiar esto en cualquier momento en Ajustes. Este paso es opcional.';

  @override
  String get onboardingAllowNotifications => 'Permitir';

  @override
  String get onboardingPhotoTitle => 'Acceso a fotos';

  @override
  String get onboardingPhotoDescription => 'Se usa solo para configurar imágenes de perfil y adjuntar imágenes a mensajes.';

  @override
  String get onboardingPhotoNote => 'Solo accedemos a las fotos que selecciones. Este paso es opcional.';

  @override
  String get onboardingAllowPhotos => 'Permitir';

  @override
  String get onboardingGuidelineTitle => 'Normas de la comunidad';

  @override
  String get onboardingGuidelineDescription => 'Para un uso seguro, están prohibidos el acoso, el discurso de odio y compartir información personal. Las violaciones pueden resultar en restricciones de contenido.';

  @override
  String get onboardingAgreeGuidelines => 'Acepto las normas de la comunidad.';

  @override
  String get onboardingContentPolicyTitle => 'Política de contenido';

  @override
  String get onboardingContentPolicyDescription => 'El contenido ilegal, dañino y violento está prohibido. El contenido que viole las normas puede ser restringido tras revisión.';

  @override
  String get onboardingAgreeContentPolicy => 'Acepto la política de contenido.';

  @override
  String get onboardingSafetyTitle => 'Reportar y bloquear';

  @override
  String get onboardingSafetyDescription => 'Puedes reportar contenido ofensivo o inapropiado, o bloquear usuarios específicos para dejar de recibir sus mensajes.';

  @override
  String get onboardingConfirmSafety => 'Entiendo la política de reportes y bloqueo.';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get onboardingAgreeAndDisagree => 'Aceptar y Rechazar';

  @override
  String get onboardingPrevious => 'Anterior';

  @override
  String get ctaPermissionChoice => 'Elegir Permiso';

  @override
  String get onboardingExitTitle => '¿Salir de la introducción?';

  @override
  String get onboardingExitMessage => 'Puedes comenzar de nuevo más tarde.';

  @override
  String get onboardingExitConfirm => 'Salir';

  @override
  String get onboardingExitCancel => 'Continuar';

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
  String get tabSentLabel => 'Enviados';

  @override
  String get tabInboxLabel => 'Bandeja de entrada';

  @override
  String get tabCreateLabel => 'Crear mensaje';

  @override
  String get tabAlertsLabel => 'Notificaciones';

  @override
  String get tabProfileLabel => 'Perfil';

  @override
  String get noticeTitle => 'Avisos';

  @override
  String get noticeDetailTitle => 'Avisos';

  @override
  String get noticeFilterLabel => 'Tipo de aviso';

  @override
  String get noticeFilterAll => 'Todos';

  @override
  String get noticeFilterSheetTitle => 'Seleccionar tipo de aviso';

  @override
  String get noticeTypeUnknown => 'Desconocido';

  @override
  String get noticePinnedBadge => 'Fijado';

  @override
  String get noticeEmptyTitle => 'No hay avisos';

  @override
  String get noticeEmptyDescription => 'No hay avisos para este tipo.';

  @override
  String get noticeErrorTitle => 'No se pudieron cargar los avisos';

  @override
  String get noticeErrorDescription => 'Inténtalo de nuevo más tarde.';

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

  @override
  String get profileDefaultNickname => 'Usuario';

  @override
  String get profileEditCta => 'Editar perfil';

  @override
  String get authProviderKakaoLogin => 'Inicio de sesión con Kakao';

  @override
  String get authProviderGoogleLogin => 'Inicio de sesión con Google';

  @override
  String get authProviderAppleLogin => 'Inicio de sesión con Apple';

  @override
  String get authProviderUnknownLogin => 'Sesión iniciada';

  @override
  String get profileLoginProviderKakao => 'Inicio de sesión con Kakao';

  @override
  String get profileLoginProviderGoogle => 'Inicio de sesión con Google';

  @override
  String get profileLoginProviderApple => 'Inicio de sesión con Apple';

  @override
  String get profileLoginProviderEmail => 'Inicio de sesión con correo';

  @override
  String get profileLoginProviderUnknown => 'Sesión iniciada';

  @override
  String get profileAppSettings => 'Ajustes de la app';

  @override
  String get profileMenuNotices => 'Avisos';

  @override
  String get profileMenuSupport => 'Ayuda';

  @override
  String get profileMenuAppInfo => 'Información de la app';

  @override
  String get profileMenuTitle => 'Menú';

  @override
  String get profileMenuSubtitle => 'Acceso rápido a ajustes frecuentes.';

  @override
  String get profileWithdrawCta => 'Eliminar cuenta';

  @override
  String get profileWithdrawTitle => 'Eliminar cuenta';

  @override
  String get profileWithdrawMessage => '¿Quieres eliminar tu cuenta? Esta acción no se puede deshacer.';

  @override
  String get profileWithdrawConfirm => 'Eliminar';

  @override
  String get profileFeaturePreparingTitle => 'Próximamente';

  @override
  String get profileFeaturePreparingBody => 'Esta función aún no está disponible.';

  @override
  String get profileAvatarSemantics => 'Avatar del perfil';

  @override
  String get supportTitle => 'Soporte';

  @override
  String get supportStatusMessage => 'La app está actualizada.';

  @override
  String get supportReleaseNotesTitle => 'Notas de la versión';

  @override
  String supportReleaseNotesHeader(Object version) {
    return 'Última versión $version - novedades';
  }

  @override
  String get supportReleaseNotesBody => '• Mejoramos la experiencia y estabilidad del relé.\n• Pulimos el tema oscuro en perfil y soporte.\n• Corregimos errores menores y rendimiento.';

  @override
  String get supportVersionUnknown => 'Desconocida';

  @override
  String get supportSuggestCta => 'Enviar sugerencias';

  @override
  String get supportReportCta => 'Reportar un error';

  @override
  String get supportFaqTitle => 'Preguntas frecuentes';

  @override
  String get supportFaqSubtitle => 'Consulta las dudas habituales.';

  @override
  String get supportFaqQ1 => 'Los mensajes no parecen entregarse. ¿Por qué?';

  @override
  String get supportFaqA1 => 'La entrega puede retrasarse o restringirse debido al estado de la red, retrasos temporales del servidor o políticas de seguridad (reportes/bloqueos, etc.). Por favor, inténtalo de nuevo más tarde.';

  @override
  String get supportFaqQ2 => 'No recibo notificaciones. ¿Qué debo hacer?';

  @override
  String get supportFaqA2 => 'Los permisos de notificación de Echowander pueden estar desactivados en la configuración de tu teléfono. Ve a Configuración de la app → Configuración de la app (Configuración de notificaciones) para activar los permisos de notificación y también verifica las restricciones de ahorro de batería/fondo.';

  @override
  String get supportFaqQ3 => 'Recibí un mensaje desagradable. ¿Cómo bloqueo/reporto?';

  @override
  String get supportFaqA3 => 'Puedes seleccionar Reportar o Bloquear desde la pantalla del mensaje. Bloquear evita que recibas más mensajes de ese usuario. El contenido reportado puede ser revisado para la seguridad de la comunidad.';

  @override
  String get supportFaqQ4 => '¿Puedo editar o cancelar un mensaje que envié?';

  @override
  String get supportFaqA4 => 'Una vez enviado, los mensajes no se pueden editar o cancelar fácilmente. Por favor, revisa el contenido antes de enviar.';

  @override
  String get supportFaqQ5 => '¿Qué pasa si violo las pautas de la comunidad?';

  @override
  String get supportFaqA5 => 'Las violaciones repetidas pueden resultar en restricciones de mensajes o limitaciones de cuenta. Por favor, sigue las pautas para una comunidad segura.';

  @override
  String get supportActionPreparingTitle => 'Próximamente';

  @override
  String get supportActionPreparingBody => 'Esta acción estará disponible pronto.';

  @override
  String get supportSuggestionSubject => 'Solicitud de sugerencia';

  @override
  String get supportBugSubject => 'Reporte de error';

  @override
  String supportEmailFooterUser(String userId) {
    return 'Usuario : $userId';
  }

  @override
  String supportEmailFooterVersion(String version) {
    return 'Versión de la app : $version';
  }

  @override
  String get supportEmailLaunchFailed => 'No se pudo abrir la aplicación de correo. Por favor, inténtelo de nuevo más tarde.';

  @override
  String get appInfoTitle => 'Información de la app';

  @override
  String get appInfoSettingsTitle => 'Ajustes de la app';

  @override
  String get appInfoSettingsSubtitle => 'Consulta licencias y políticas.';

  @override
  String get appInfoSectionTitle => 'Servicios conectados';

  @override
  String get appInfoSectionSubtitle => 'Revisa las apps vinculadas al servicio.';

  @override
  String appInfoVersionLabel(Object version) {
    return 'Versión $version';
  }

  @override
  String get appInfoVersionUnknown => 'Desconocida';

  @override
  String get appInfoOpenLicenseTitle => 'Licencias abiertas';

  @override
  String get appInfoRelatedAppsTitle => 'Apps relacionadas de BIZPECT';

  @override
  String get appInfoRelatedApp1Title => 'App de prueba 1';

  @override
  String get appInfoRelatedApp1Description => 'App de ejemplo para pruebas de servicios relacionados.';

  @override
  String get appInfoRelatedApp2Title => 'App de prueba 2';

  @override
  String get appInfoRelatedApp2Description => 'Otra app de ejemplo para integraciones relacionadas.';

  @override
  String get appInfoExternalLinkLabel => 'Abrir enlace externo';

  @override
  String get appInfoLinkPreparingTitle => 'Próximamente';

  @override
  String get appInfoLinkPreparingBody => 'Este enlace estará disponible pronto.';

  @override
  String get openLicenseTitle => 'Licencias abiertas';

  @override
  String get openLicenseHeaderTitle => 'Bibliotecas de código abierto';

  @override
  String get openLicenseHeaderBody => 'Esta app usa las siguientes bibliotecas de código abierto.';

  @override
  String get openLicenseSectionTitle => 'Lista de licencias';

  @override
  String get openLicenseSectionSubtitle => 'Revisa los paquetes de código abierto en uso.';

  @override
  String openLicenseChipVersion(Object version) {
    return 'Versión: $version';
  }

  @override
  String openLicenseChipLicense(Object license) {
    return 'Licencia: $license';
  }

  @override
  String get openLicenseChipDetails => 'Detalles';

  @override
  String get openLicenseTypeMit => 'MIT';

  @override
  String get openLicenseTypeApache => 'Apache 2.0';

  @override
  String get openLicenseTypeBsd3 => 'BSD 3-Clause';

  @override
  String get openLicenseTypeBsd2 => 'BSD 2-Clause';

  @override
  String get openLicenseTypeMpl2 => 'MPL 2.0';

  @override
  String get openLicenseTypeGpl => 'GPL';

  @override
  String get openLicenseTypeLgpl => 'LGPL';

  @override
  String get openLicenseTypeIsc => 'ISC';

  @override
  String get openLicenseTypeUnknown => 'Desconocida';

  @override
  String get openLicenseUnknown => 'Desconocida';

  @override
  String get openLicenseEmptyMessage => 'No hay información de licencias disponible.';

  @override
  String openLicenseDetailTitle(Object package) {
    return 'Licencia de $package';
  }

  @override
  String get journeyDetailAnonymous => 'Anónimo';

  @override
  String get errorNetwork => 'Por favor, verifica tu conexión de red.';

  @override
  String get errorTimeout => 'Tiempo de espera agotado. Por favor, inténtalo de nuevo.';

  @override
  String get errorServerUnavailable => 'El servidor no está disponible temporalmente. Por favor, inténtalo más tarde.';

  @override
  String get errorUnauthorized => 'Por favor, inicia sesión de nuevo.';

  @override
  String get errorRetry => 'Reintentar';

  @override
  String get errorCancel => 'Cancelar';

  @override
  String get errorAuthRefreshFailed => 'La red es inestable. Por favor, inténtalo de nuevo en un momento.';

  @override
  String get homeInboxSummaryTitle => 'Resumen de hoy';

  @override
  String get homeInboxSummaryPending => 'Pendientes';

  @override
  String get homeInboxSummaryCompleted => 'Respondidas';

  @override
  String get homeInboxSummarySentResponses => 'Respuestas recibidas';

  @override
  String homeInboxSummaryUpdatedAt(Object time) {
    return 'Actualizado $time';
  }

  @override
  String get homeInboxSummaryRefresh => 'Actualizar';

  @override
  String get homeInboxSummaryLoadFailed => 'No pudimos cargar el resumen.';

  @override
  String homeInboxSummaryItemSemantics(Object label, Object count) {
    return '$label $count';
  }

  @override
  String get homeTimelineTitle => 'Actividad reciente';

  @override
  String get homeTimelineEmptyTitle => 'Sin actividad reciente';

  @override
  String get homeTimelineReceivedTitle => 'Nuevo mensaje recibido';

  @override
  String get homeTimelineRespondedTitle => 'Respuesta enviada';

  @override
  String get homeTimelineSentResponseTitle => 'Respuesta recibida';

  @override
  String homeTimelineSubtitle(Object time) {
    return '$time';
  }

  @override
  String get homeDailyPromptTitle => 'Pregunta del día';

  @override
  String get homeDailyPromptHint => 'Toca para escribir un mensaje';

  @override
  String get homeDailyPromptAction => 'Escribir';

  @override
  String get homeAnnouncementTitle => 'Actualización';

  @override
  String get homeAnnouncementSummary => 'Descubre las novedades de Echowander.';

  @override
  String get homeAnnouncementAction => 'Detalles';

  @override
  String get homeAnnouncementDetailTitle => 'Actualización';

  @override
  String get homeAnnouncementDetailBody => 'Hicimos mejoras para una experiencia más fluida.';

  @override
  String get homePromptQ1 => '¿Qué te hizo sonreír hoy?';

  @override
  String get homePromptQ2 => '¿Qué esperas con ganas esta semana?';

  @override
  String get homePromptQ3 => '¿Qué lugar quieres volver a visitar?';

  @override
  String get homePromptQ4 => 'Comparte una pequeña victoria de hoy.';

  @override
  String get homePromptQ5 => '¿Qué hábito te gustaría crear?';

  @override
  String get homePromptQ6 => '¿A quién quieres agradecer hoy?';

  @override
  String get homePromptQ7 => '¿Qué canción no dejas de escuchar?';

  @override
  String get homePromptQ8 => 'Describe tu día en tres palabras.';

  @override
  String get homePromptQ9 => '¿Qué has aprendido recientemente?';

  @override
  String get homePromptQ10 => 'Si pudieras enviarte un mensaje, ¿qué dirías?';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileEditNicknameLabel => 'Apodo';

  @override
  String get profileEditNicknameHint => 'Ingrese apodo';

  @override
  String get profileEditNicknameEmpty => 'Por favor ingrese un apodo';

  @override
  String profileEditNicknameTooShort(Object min) {
    return 'El apodo debe tener al menos $min caracteres';
  }

  @override
  String profileEditNicknameTooLong(Object max) {
    return 'El apodo puede tener hasta $max caracteres';
  }

  @override
  String get profileEditNicknameConsecutiveSpaces => 'No se permiten espacios consecutivos';

  @override
  String get profileEditNicknameInvalidCharacters => 'Solo se permiten coreano, inglés, números y guión bajo (_)';

  @override
  String get profileEditNicknameUnderscoreAtEnds => 'Underscore (_) cannot be used at the beginning or end';

  @override
  String get profileEditNicknameConsecutiveUnderscores => 'Consecutive underscores (__) are not allowed';

  @override
  String get profileEditNicknameForbidden => 'This nickname is not allowed';

  @override
  String get profileEditNicknameChecking => 'Verificando...';

  @override
  String get profileEditNicknameAvailable => 'Este apodo está disponible';

  @override
  String get profileEditNicknameTaken => 'Este apodo ya está en uso';

  @override
  String get profileEditNicknameError => 'Ocurrió un error al verificar';

  @override
  String get profileEditAvatarLabel => 'Foto de perfil';

  @override
  String get profileEditAvatarChange => 'Cambiar foto';

  @override
  String get profileEditSave => 'Guardar';

  @override
  String get profileEditCancel => 'Cancelar';

  @override
  String get profileEditSaveSuccess => 'Perfil guardado exitosamente';

  @override
  String get profileEditSaveFailed => 'Error al guardar. Por favor intente nuevamente';

  @override
  String get profileEditImageTooLarge => 'Image file is too large. Please select another image';

  @override
  String get profileEditImageOptimizationFailed => 'An error occurred while processing the image. Please try again';

  @override
  String get profileEditCropTitle => 'Editar foto';

  @override
  String get profileEditCropDescription => 'Ajuste la posición como desee';

  @override
  String get profileEditCropCancel => 'Cancelar';

  @override
  String get profileEditCropComplete => 'Completar';

  @override
  String get profileEditCropFailedTitle => 'Error al editar foto';

  @override
  String get profileEditCropFailedMessage => 'Ocurrió un error al editar la foto. Por favor, inténtelo de nuevo.';

  @override
  String get profileEditCropFailedAction => 'OK';
}
