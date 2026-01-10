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
  String get composeWizardStep2Subtitle => 'Elige entre 1 y 5.';

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
  String get inboxPassedTitle => 'Mensaje pasado';

  @override
  String get inboxPassedDetailUnavailable => 'Este mensaje fue pasado y el contenido no está disponible.';

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
  String get profileLoginProviderGoogle => 'Inicio de sesión con Google';

  @override
  String get profileLoginProviderApple => 'Inicio de sesión con Apple';

  @override
  String get profileLoginProviderEmail => 'Inicio de sesión con correo';

  @override
  String get profileLoginProviderUnknown => 'Sesión iniciada';

  @override
  String get profileMenuNotifications => 'Ajustes de notificaciones';

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
  String get supportFaqQ1 => '¿Cómo puedo crear un equipo?';

  @override
  String get supportFaqA1 => 'Las funciones de equipo estarán disponibles pronto.';

  @override
  String get supportFaqQ2 => '¿Cómo invito a miembros del equipo?';

  @override
  String get supportFaqA2 => 'La invitación estará disponible cuando lancemos equipos.';

  @override
  String get supportFaqQ3 => '¿Cómo registro el calendario de juegos?';

  @override
  String get supportFaqA3 => 'El calendario se habilitará en una próxima actualización.';

  @override
  String get supportFaqQ4 => 'No recibo notificaciones.';

  @override
  String get supportFaqA4 => 'Revisa los permisos del sistema y la configuración de notificaciones.';

  @override
  String get supportFaqQ5 => '¿Cómo elimino mi cuenta?';

  @override
  String get supportFaqA5 => 'Ve a Perfil > Eliminar cuenta y sigue los pasos.';

  @override
  String get supportActionPreparingTitle => 'Próximamente';

  @override
  String get supportActionPreparingBody => 'Esta acción estará disponible pronto.';

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
}
