// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => 'A iniciar...';

  @override
  String get loginTitle => 'Iniciar sessão';

  @override
  String get loginDescription => 'Comece a sua mensagem de relé anónima';

  @override
  String get loginKakao => 'Continuar com Kakao';

  @override
  String get loginGoogle => 'Continuar com Google';

  @override
  String get loginApple => 'Continuar com Apple';

  @override
  String get loginTerms =>
      'Ao iniciar sessão, concorda com os nossos Termos de Serviço e Política de Privacidade';

  @override
  String get homeTitle => 'Início';

  @override
  String get homeGreeting => 'Bem-vindo de volta';

  @override
  String get homeRecentJourneysTitle => 'Mensagens recentes';

  @override
  String get homeActionsTitle => 'Começar';

  @override
  String get homeEmptyTitle => 'Bem-vindo ao EchoWander';

  @override
  String get homeEmptyDescription =>
      'Envie a sua primeira mensagem de relé ou verifique a sua caixa de entrada.';

  @override
  String get homeInboxCardTitle => 'Caixa de entrada';

  @override
  String get homeInboxCardDescription =>
      'Veja e responda às mensagens que recebeu.';

  @override
  String get homeCreateCardTitle => 'Criar mensagem';

  @override
  String get homeCreateCardDescription => 'Inicie uma nova mensagem de relé.';

  @override
  String get homeJourneyCardViewDetails => 'Ver detalhes';

  @override
  String get homeRefresh => 'Atualizar';

  @override
  String get homeLoadFailed => 'Não conseguimos carregar os seus dados.';

  @override
  String homeInboxCount(Object count) {
    return '$count nova(s)';
  }

  @override
  String get settingsCta => 'Configurações';

  @override
  String get settingsNotificationInbox => 'Caixa de notificações';

  @override
  String get pushPreviewTitle => 'Notificação';

  @override
  String get pushPreviewDescription =>
      'Este é um ecrã de teste para links profundos de notificações.';

  @override
  String get notificationTitle => 'Nova mensagem';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationDismiss => 'Fechar';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get notificationsEmpty => 'Ainda não há notificações.';

  @override
  String get notificationsUnreadOnly => 'Mostrar apenas não lidas';

  @override
  String get notificationsRead => 'Lida';

  @override
  String get notificationsUnread => 'Nova';

  @override
  String get notificationsDeleteTitle => 'Excluir notificação';

  @override
  String get notificationsDeleteMessage => 'Excluir esta notificação?';

  @override
  String get notificationsDeleteConfirm => 'Excluir';

  @override
  String get pushJourneyAssignedTitle => 'Nova mensagem';

  @override
  String get pushJourneyAssignedBody => 'Chegou uma nova mensagem de relé.';

  @override
  String get pushJourneyResultTitle => 'Resultado disponível';

  @override
  String get pushJourneyResultBody => 'Seu resultado do relé está pronto.';

  @override
  String get errorTitle => 'Aviso';

  @override
  String get errorGeneric => 'Ocorreu um problema. Tente novamente.';

  @override
  String get errorLoginFailed => 'Falha ao iniciar sessão. Tente novamente.';

  @override
  String get errorLoginCancelled => 'O início de sessão foi cancelado.';

  @override
  String get errorLoginNetwork =>
      'Verifique a sua ligação de rede e tente novamente.';

  @override
  String get errorLoginInvalidToken =>
      'A verificação do início de sessão falhou. Tente novamente.';

  @override
  String get errorLoginUnsupportedProvider =>
      'Este método de início de sessão não é suportado.';

  @override
  String get errorLoginUserSyncFailed =>
      'Não foi possível guardar a sua conta. Tente novamente.';

  @override
  String get errorLoginServiceUnavailable =>
      'O serviço de início de sessão está temporariamente indisponível. Tente mais tarde.';

  @override
  String get errorSessionExpired =>
      'A sua sessão expirou. Inicie sessão novamente.';

  @override
  String get errorForbiddenTitle => 'Permission Required';

  @override
  String get errorForbiddenMessage =>
      'You don\'t have permission to perform this action. Please check your login status or try again later.';

  @override
  String get journeyInboxForbiddenTitle => 'Cannot Load Inbox';

  @override
  String get journeyInboxForbiddenMessage =>
      'You don\'t have permission to view the inbox. If the problem persists, please sign in again.';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageJapanese => 'Japonês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageChinese => 'Chinês';

  @override
  String get composeTitle => 'Escrever mensagem';

  @override
  String get composeWizardStep1Title => 'Que mensagem vai nessa jornada?';

  @override
  String get composeWizardStep1Subtitle =>
      'Escreva uma frase para iniciar o revezamento.';

  @override
  String get composeWizardStep2Title => 'Para quantas pessoas enviar?';

  @override
  String get composeWizardStep2Subtitle => 'Escolha entre 1 e 5.';

  @override
  String get composeWizardStep3Title => 'Quer enviar uma foto junto?';

  @override
  String get composeWizardStep3Subtitle =>
      'Até 3 fotos. Você também pode enviar sem foto.';

  @override
  String get composeWizardBack => 'Voltar';

  @override
  String get composeWizardNext => 'Próximo';

  @override
  String get composeLabel => 'Mensagem';

  @override
  String get composeHint => 'Partilhe o que pensa...';

  @override
  String composeCharacterCount(Object current, Object total) {
    return '$current/$total';
  }

  @override
  String get composeImagesTitle => 'Imagens';

  @override
  String get composeAddImage => 'Adicionar foto';

  @override
  String get composeSubmit => 'Enviar';

  @override
  String get composeCta => 'Escrever mensagem';

  @override
  String get composeTooLong => 'A mensagem é demasiado longa.';

  @override
  String get composeForbidden => 'Remova URLs ou contactos.';

  @override
  String get composeEmpty => 'Escreva uma mensagem.';

  @override
  String get composeInvalid => 'Verifique o conteúdo da mensagem.';

  @override
  String get composeImageLimit => 'Pode anexar até 3 imagens.';

  @override
  String get composePermissionDenied => 'É necessário acesso às fotos.';

  @override
  String get composeSessionMissing => 'Inicie sessão novamente.';

  @override
  String get composeSubmitFailed =>
      'Não foi possível enviar a mensagem. Tente novamente.';

  @override
  String get composeServerMisconfigured =>
      'A configuração do serviço ainda não está pronta. Tente mais tarde.';

  @override
  String get composeSubmitSuccess => 'A sua mensagem foi enviada.';

  @override
  String get composeRecipientCountLabel => 'Quantidade de relés';

  @override
  String get composeRecipientCountHint => 'Selecione de 1 a 5 pessoas.';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count pessoas';
  }

  @override
  String get composeRecipientRequired =>
      'Selecione quantas pessoas receberão a mensagem.';

  @override
  String get composeRecipientInvalid =>
      'Só pode selecionar entre 1 e 5 pessoas.';

  @override
  String get composeErrorTitle => 'Aviso';

  @override
  String get composeSuccessTitle => 'Concluído';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Cancelar';

  @override
  String get composePermissionTitle => 'Permitir acesso a fotos';

  @override
  String get composePermissionMessage =>
      'Abra as Definições para permitir o acesso a fotos.';

  @override
  String get composeOpenSettings => 'Abrir definições';

  @override
  String get journeyListTitle => 'Mensagens enviadas';

  @override
  String get journeyListEmpty => 'Ainda não há mensagens enviadas.';

  @override
  String get journeyListCta => 'Ver mensagens enviadas';

  @override
  String get journeyListStatusLabel => 'Estado:';

  @override
  String get journeyStatusCreated => 'Enviada';

  @override
  String get journeyStatusWaiting => 'Aguardando correspondência';

  @override
  String get journeyStatusCompleted => 'Concluída';

  @override
  String get journeyStatusInProgress => 'Em andamento';

  @override
  String get journeyStatusUnknown => 'Desconhecido';

  @override
  String get journeyInProgressHint =>
      'Poderá ver as respostas após a conclusão';

  @override
  String get journeyFilterOk => 'Permitido';

  @override
  String get journeyFilterHeld => 'Em revisão';

  @override
  String get journeyFilterRemoved => 'Removido';

  @override
  String get journeyFilterUnknown => 'Desconhecido';

  @override
  String get inboxTitle => 'Caixa de entrada';

  @override
  String get inboxEmpty => 'Ainda não há mensagens recebidas.';

  @override
  String get inboxCta => 'Ver caixa de entrada';

  @override
  String get inboxRefresh => 'Atualizar';

  @override
  String get inboxLoadFailed =>
      'Não conseguimos carregar a sua caixa de entrada.';

  @override
  String inboxImageCount(Object count) {
    return '$count foto(s)';
  }

  @override
  String get inboxStatusLabel => 'Estado:';

  @override
  String get inboxStatusAssigned => 'Em espera';

  @override
  String get inboxStatusResponded => 'Respondida';

  @override
  String get inboxStatusPassed => 'Passado';

  @override
  String get inboxStatusReported => 'Denunciado';

  @override
  String get inboxStatusUnknown => 'Desconhecido';

  @override
  String get inboxDetailTitle => 'Mensagem recebida';

  @override
  String get inboxDetailMissing => 'Não foi possível carregar esta mensagem.';

  @override
  String get inboxImagesLabel => 'Fotos';

  @override
  String get inboxImagesLoadFailed => 'Não foi possível carregar as fotos.';

  @override
  String get inboxBlockCta => 'Bloquear remetente';

  @override
  String get inboxBlockTitle => 'Bloquear usuário';

  @override
  String get inboxBlockMessage => 'Bloquear este usuário para futuros envios?';

  @override
  String get inboxBlockConfirm => 'Bloquear';

  @override
  String get inboxBlockSuccessTitle => 'Bloqueado';

  @override
  String get inboxBlockSuccessBody => 'O usuário foi bloqueado.';

  @override
  String get inboxBlockFailed => 'Não foi possível bloquear o usuário.';

  @override
  String get inboxBlockMissing => 'Não foi possível identificar o remetente.';

  @override
  String get inboxRespondLabel => 'Responder';

  @override
  String get inboxRespondHint => 'Escreva sua resposta...';

  @override
  String get inboxRespondCta => 'Enviar resposta';

  @override
  String get inboxRespondEmpty => 'Digite uma resposta.';

  @override
  String get inboxRespondSuccessTitle => 'Resposta enviada';

  @override
  String get inboxRespondSuccessBody => 'Sua resposta foi enviada.';

  @override
  String get inboxPassCta => 'Passar';

  @override
  String get inboxPassSuccessTitle => 'Passado';

  @override
  String get inboxPassSuccessBody => 'Você passou esta mensagem.';

  @override
  String get inboxPassedTitle => 'Mensagem passada';

  @override
  String get inboxPassedDetailUnavailable =>
      'Esta mensagem foi passada e o conteúdo não está disponível.';

  @override
  String get inboxReportCta => 'Denunciar';

  @override
  String get inboxReportTitle => 'Motivo da denúncia';

  @override
  String get inboxReportSpam => 'Spam';

  @override
  String get inboxReportAbuse => 'Abuso';

  @override
  String get inboxReportOther => 'Outro';

  @override
  String get inboxReportSuccessTitle => 'Denúncia enviada';

  @override
  String get inboxReportSuccessBody => 'Sua denúncia foi enviada.';

  @override
  String get inboxActionFailed => 'Não foi possível concluir a ação.';

  @override
  String get journeyDetailTitle => 'Mensagem';

  @override
  String get journeyDetailMessageLabel => 'Mensagem';

  @override
  String get journeyDetailMessageUnavailable =>
      'Não foi possível carregar a mensagem.';

  @override
  String get journeyDetailProgressTitle => 'Progresso do relé';

  @override
  String get journeyDetailStatusLabel => 'Status';

  @override
  String get journeyDetailDeadlineLabel => 'Prazo do relé';

  @override
  String get journeyDetailResponseTargetLabel => 'Meta de respostas';

  @override
  String get journeyDetailRespondedLabel => 'Respostas';

  @override
  String get journeyDetailAssignedLabel => 'Atribuídos';

  @override
  String get journeyDetailPassedLabel => 'Passados';

  @override
  String get journeyDetailReportedLabel => 'Denunciados';

  @override
  String get journeyDetailCountriesLabel => 'Locais do relé';

  @override
  String get journeyDetailCountriesEmpty => 'Ainda não há locais.';

  @override
  String get journeyDetailResultsTitle => 'Respostas';

  @override
  String get journeyDetailResultsLocked =>
      'As respostas aparecerão após a conclusão.';

  @override
  String get journeyDetailResultsEmpty => 'Ainda não há respostas.';

  @override
  String get journeyDetailResultsLoadFailed =>
      'Não foi possível carregar as respostas.';

  @override
  String get commonTemporaryErrorTitle => 'Erro temporário';

  @override
  String get sentDetailRepliesLoadFailedMessage =>
      'Não foi possível carregar as respostas.\nVoltaremos à lista.';

  @override
  String get commonOk => 'OK';

  @override
  String get journeyDetailResponsesMissingTitle => 'Erro temporário';

  @override
  String get journeyDetailResponsesMissingBody =>
      'Não foi possível carregar as respostas. Tente novamente.\nVoltaremos à lista.';

  @override
  String get journeyDetailGateConfigTitle => 'Anúncio não pronto';

  @override
  String get journeyDetailGateConfigBody =>
      'A configuração de anúncios não está pronta. Vamos abrir os detalhes sem anúncio.';

  @override
  String get journeyDetailGateDismissedTitle => 'Anúncio não concluído';

  @override
  String get journeyDetailGateDismissedBody =>
      'Assista ao anúncio até o fim para ver os detalhes.';

  @override
  String get journeyDetailGateFailedTitle => 'Anúncio indisponível';

  @override
  String get journeyDetailGateFailedBody =>
      'Não foi possível carregar o anúncio. Tente novamente.';

  @override
  String get journeyDetailUnlockFailedTitle => 'Falha ao salvar o desbloqueio';

  @override
  String get journeyDetailUnlockFailedBody =>
      'Não foi possível salvar o desbloqueio por um problema de rede/servidor. Tente novamente.';

  @override
  String get journeyDetailGateDialogTitle =>
      'Desbloquear com anúncio recompensado';

  @override
  String get journeyDetailGateDialogBody =>
      'Desbloqueie assistindo a um anúncio recompensado.\nAssista uma vez para desbloquear para sempre.';

  @override
  String get journeyDetailGateDialogConfirm => 'Desbloquear';

  @override
  String get journeyDetailLoadFailed =>
      'Não foi possível carregar o progresso.';

  @override
  String get journeyDetailRetry => 'Tentar novamente';

  @override
  String get journeyDetailAdRequired =>
      'Assista a um anúncio para ver os resultados.';

  @override
  String get journeyDetailAdCta => 'Assistir anúncio e desbloquear';

  @override
  String get journeyDetailAdFailedTitle => 'Anúncio indisponível';

  @override
  String get journeyDetailAdFailedBody =>
      'Não foi possível carregar o anúncio. Ver os resultados mesmo assim?';

  @override
  String get journeyDetailAdFailedConfirm => 'Ver resultados';

  @override
  String get journeyResultReportCta => 'Denunciar resposta';

  @override
  String get journeyResultReportSuccessTitle => 'Denúncia enviada';

  @override
  String get journeyResultReportSuccessBody => 'Sua denúncia foi enviada.';

  @override
  String get journeyResultReportFailed => 'Não foi possível enviar a denúncia.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSectionNotification => 'Notificações';

  @override
  String get settingsNotificationToggle => 'Permitir notificações';

  @override
  String get settingsNotificationHint => 'Receba atualizações e resultados.';

  @override
  String get settingsSectionSafety => 'Segurança';

  @override
  String get settingsBlockedUsers => 'Usuários bloqueados';

  @override
  String get settingsLoadFailed =>
      'Não foi possível carregar as configurações.';

  @override
  String get settingsUpdateFailed =>
      'Não foi possível atualizar as configurações.';

  @override
  String get blockListTitle => 'Usuários bloqueados';

  @override
  String get blockListEmpty => 'Nenhum usuário bloqueado.';

  @override
  String get blockListUnknownUser => 'Usuário desconhecido';

  @override
  String get blockListLoadFailed =>
      'Não foi possível carregar a lista de bloqueados.';

  @override
  String get blockListUnblock => 'Desbloquear';

  @override
  String get blockListUnblockTitle => 'Desbloquear usuário';

  @override
  String get blockListUnblockMessage =>
      'Permitir mensagens deste usuário novamente?';

  @override
  String get blockListUnblockConfirm => 'Desbloquear';

  @override
  String get blockListUnblockFailed =>
      'Não foi possível desbloquear o usuário.';

  @override
  String get onboardingTitle => 'Integração';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Etapa $current de $total';
  }

  @override
  String get onboardingNotificationTitle => 'Permissão de notificações';

  @override
  String get onboardingNotificationDescription =>
      'Notificaremos quando as mensagens de revezamento chegarem e os resultados estiverem prontos.';

  @override
  String get onboardingNotificationNote =>
      'Pode alterar isto a qualquer momento nas Definições. Esta etapa é opcional.';

  @override
  String get onboardingAllowNotifications => 'Permitir';

  @override
  String get onboardingPhotoTitle => 'Acesso a fotos';

  @override
  String get onboardingPhotoDescription =>
      'Usado apenas para definir imagens de perfil e anexar imagens às mensagens.';

  @override
  String get onboardingPhotoNote =>
      'Acedemos apenas às fotos que selecionar. Esta etapa é opcional.';

  @override
  String get onboardingAllowPhotos => 'Permitir';

  @override
  String get onboardingGuidelineTitle => 'Diretrizes da comunidade';

  @override
  String get onboardingGuidelineDescription =>
      'Para uma utilização segura, são proibidos o assédio, o discurso de ódio e a partilha de informações pessoais. As violações podem resultar em restrições de conteúdo.';

  @override
  String get onboardingAgreeGuidelines =>
      'Concordo com as diretrizes da comunidade.';

  @override
  String get onboardingContentPolicyTitle => 'Política de conteúdo';

  @override
  String get onboardingContentPolicyDescription =>
      'Conteúdo ilegal, prejudicial e violento é proibido. O conteúdo em violação pode ser restringido após análise.';

  @override
  String get onboardingAgreeContentPolicy =>
      'Concordo com a política de conteúdo.';

  @override
  String get onboardingSafetyTitle => 'Denunciar e bloquear';

  @override
  String get onboardingSafetyDescription =>
      'Pode denunciar conteúdo ofensivo ou inadequado, ou bloquear utilizadores específicos para deixar de receber as suas mensagens.';

  @override
  String get onboardingConfirmSafety =>
      'Compreendo a política de denúncia e bloqueio.';

  @override
  String get onboardingSkip => 'Ignorar';

  @override
  String get onboardingNext => 'Seguinte';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingAgreeAndDisagree => 'Concordar e Discordar';

  @override
  String get onboardingPrevious => 'Anterior';

  @override
  String get ctaPermissionChoice => 'Escolher Permissão';

  @override
  String get onboardingExitTitle => 'Sair da integração?';

  @override
  String get onboardingExitMessage => 'Pode começar novamente mais tarde.';

  @override
  String get onboardingExitConfirm => 'Sair';

  @override
  String get onboardingExitCancel => 'Continuar';

  @override
  String get exitConfirmTitle => 'Cancelar escrita?';

  @override
  String get exitConfirmMessage => 'Sua entrada será perdida.';

  @override
  String get exitConfirmContinue => 'Continuar a escrever';

  @override
  String get exitConfirmLeave => 'Sair';

  @override
  String get tabHomeLabel => 'Início';

  @override
  String get tabSentLabel => 'Enviados';

  @override
  String get tabInboxLabel => 'Caixa de entrada';

  @override
  String get tabCreateLabel => 'Criar mensagem';

  @override
  String get tabAlertsLabel => 'Notificações';

  @override
  String get tabProfileLabel => 'Perfil';

  @override
  String get profileSignOutCta => 'Terminar sessão';

  @override
  String get profileSignOutTitle => 'Terminar sessão';

  @override
  String get profileSignOutMessage =>
      'Tem a certeza de que deseja terminar sessão?';

  @override
  String get profileSignOutConfirm => 'Terminar sessão';

  @override
  String get profileUserIdLabel => 'ID de utilizador';

  @override
  String get profileDefaultNickname => 'Utilizador';

  @override
  String get profileEditCta => 'Editar perfil';

  @override
  String get profileLoginProviderGoogle => 'Login com Google';

  @override
  String get profileLoginProviderApple => 'Login com Apple';

  @override
  String get profileLoginProviderEmail => 'Login com e-mail';

  @override
  String get profileLoginProviderUnknown => 'Sessão iniciada';

  @override
  String get profileMenuNotifications => 'Configurações de notificações';

  @override
  String get profileMenuNotices => 'Avisos';

  @override
  String get profileMenuSupport => 'Suporte';

  @override
  String get profileMenuAppInfo => 'Informações do app';

  @override
  String get profileWithdrawCta => 'Eliminar conta';

  @override
  String get profileWithdrawTitle => 'Eliminar conta';

  @override
  String get profileWithdrawMessage =>
      'Quer eliminar a sua conta? Esta ação não pode ser desfeita.';

  @override
  String get profileWithdrawConfirm => 'Eliminar';

  @override
  String get profileFeaturePreparingTitle => 'Em breve';

  @override
  String get profileFeaturePreparingBody =>
      'Esta funcionalidade ainda não está disponível.';

  @override
  String get profileAvatarSemantics => 'Avatar do perfil';

  @override
  String get supportTitle => 'Suporte';

  @override
  String get supportStatusMessage => 'O aplicativo instalado está atualizado.';

  @override
  String get supportReleaseNotesTitle => 'Notas de atualização';

  @override
  String supportReleaseNotesHeader(Object version) {
    return 'Última versão $version - novidades';
  }

  @override
  String get supportReleaseNotesBody =>
      '• Melhoramos a experiência e a estabilidade do relé.\n• Ajustamos o tema escuro em perfil e suporte.\n• Corrigimos pequenos bugs e desempenho.';

  @override
  String get supportVersionUnknown => 'Desconhecida';

  @override
  String get supportSuggestCta => 'Enviar sugestão';

  @override
  String get supportReportCta => 'Relatar erro';

  @override
  String get supportFaqTitle => 'Perguntas frequentes';

  @override
  String get supportFaqQ1 => 'Como posso criar uma equipe?';

  @override
  String get supportFaqA1 =>
      'Os recursos de equipe estarão disponíveis em breve.';

  @override
  String get supportFaqQ2 => 'Como convidar membros da equipe?';

  @override
  String get supportFaqA2 =>
      'Convites serão liberados com a função de equipes.';

  @override
  String get supportFaqQ3 => 'Como registrar o calendário de jogos?';

  @override
  String get supportFaqA3 =>
      'O calendário será suportado em uma atualização futura.';

  @override
  String get supportFaqQ4 => 'Não recebo notificações.';

  @override
  String get supportFaqA4 =>
      'Verifique as permissões do sistema e as configurações do app.';

  @override
  String get supportFaqQ5 => 'Como excluir minha conta?';

  @override
  String get supportFaqA5 => 'Vá em Perfil > Eliminar conta e siga as etapas.';

  @override
  String get supportActionPreparingTitle => 'Em breve';

  @override
  String get supportActionPreparingBody =>
      'Esta ação estará disponível em breve.';

  @override
  String get appInfoTitle => 'Informações do app';

  @override
  String appInfoVersionLabel(Object version) {
    return 'Versão $version';
  }

  @override
  String get appInfoVersionUnknown => 'Desconhecida';

  @override
  String get appInfoOpenLicenseTitle => 'Licenças abertas';

  @override
  String get appInfoRelatedAppsTitle => 'Apps relacionados da BIZPECT';

  @override
  String get appInfoRelatedApp1Title => 'App de teste 1';

  @override
  String get appInfoRelatedApp1Description =>
      'App de exemplo para testar serviços relacionados.';

  @override
  String get appInfoRelatedApp2Title => 'App de teste 2';

  @override
  String get appInfoRelatedApp2Description =>
      'Outro app de exemplo para integrações relacionadas.';

  @override
  String get appInfoExternalLinkLabel => 'Abrir link externo';

  @override
  String get appInfoLinkPreparingTitle => 'Em breve';

  @override
  String get appInfoLinkPreparingBody =>
      'Este link estará disponível em breve.';

  @override
  String get journeyDetailAnonymous => 'Anónimo';

  @override
  String get errorNetwork => 'Por favor, verifique a sua ligação de rede.';

  @override
  String get errorTimeout =>
      'Tempo limite excedido. Por favor, tente novamente.';

  @override
  String get errorServerUnavailable =>
      'O servidor está temporariamente indisponível. Por favor, tente mais tarde.';

  @override
  String get errorUnauthorized => 'Por favor, inicie sessão novamente.';

  @override
  String get errorRetry => 'Tentar novamente';

  @override
  String get errorCancel => 'Cancelar';

  @override
  String get errorAuthRefreshFailed =>
      'A rede está instável. Por favor, tente novamente em breve.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => 'Iniciando...';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginDescription => 'Comece sua mensagem de revezamento anônima';

  @override
  String get loginKakao => 'Continuar com Kakao';

  @override
  String get loginGoogle => 'Continuar com Google';

  @override
  String get loginApple => 'Continuar com Apple';

  @override
  String get loginTerms =>
      'Ao entrar, você concorda com nossos Termos de Serviço e Política de Privacidade';

  @override
  String get homeTitle => 'Início';

  @override
  String get homeGreeting => 'Bem-vindo de volta';

  @override
  String get homeRecentJourneysTitle => 'Mensagens recentes';

  @override
  String get homeActionsTitle => 'Começar';

  @override
  String get homeEmptyTitle => 'Bem-vindo ao EchoWander';

  @override
  String get homeEmptyDescription =>
      'Envie sua primeira mensagem de revezamento ou confira sua caixa de entrada.';

  @override
  String get homeInboxCardTitle => 'Caixa de entrada';

  @override
  String get homeInboxCardDescription =>
      'Confira e responda as mensagens que você recebeu.';

  @override
  String get homeCreateCardTitle => 'Criar mensagem';

  @override
  String get homeCreateCardDescription =>
      'Inicie uma nova mensagem de revezamento.';

  @override
  String get homeJourneyCardViewDetails => 'Ver detalhes';

  @override
  String get homeRefresh => 'Atualizar';

  @override
  String get homeLoadFailed => 'Não conseguimos carregar seus dados.';

  @override
  String homeInboxCount(Object count) {
    return '$count nova(s)';
  }

  @override
  String get settingsCta => 'Configurações';

  @override
  String get settingsNotificationInbox => 'Caixa de notificações';

  @override
  String get pushPreviewTitle => 'Notificação';

  @override
  String get pushPreviewDescription =>
      'Esta é uma tela de teste para links profundos de notificações.';

  @override
  String get notificationTitle => 'Nova mensagem';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationDismiss => 'Fechar';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get notificationsEmpty => 'Ainda não há notificações.';

  @override
  String get notificationsUnreadOnly => 'Mostrar apenas não lidas';

  @override
  String get notificationsRead => 'Lida';

  @override
  String get notificationsUnread => 'Nova';

  @override
  String get notificationsDeleteTitle => 'Excluir notificação';

  @override
  String get notificationsDeleteMessage => 'Excluir esta notificação?';

  @override
  String get notificationsDeleteConfirm => 'Excluir';

  @override
  String get pushJourneyAssignedTitle => 'Nova mensagem';

  @override
  String get pushJourneyAssignedBody => 'Chegou uma nova mensagem de relé.';

  @override
  String get pushJourneyResultTitle => 'Resultado disponível';

  @override
  String get pushJourneyResultBody => 'Seu resultado do relé está pronto.';

  @override
  String get errorTitle => 'Aviso';

  @override
  String get errorGeneric => 'Ocorreu um problema. Tente novamente.';

  @override
  String get errorLoginFailed => 'Falha ao entrar. Tente novamente.';

  @override
  String get errorLoginCancelled => 'O login foi cancelado.';

  @override
  String get errorLoginNetwork =>
      'Verifique sua conexão de rede e tente novamente.';

  @override
  String get errorLoginInvalidToken =>
      'A verificação do login falhou. Tente novamente.';

  @override
  String get errorLoginUnsupportedProvider =>
      'Este método de login não é compatível.';

  @override
  String get errorLoginUserSyncFailed =>
      'Não foi possível salvar sua conta. Tente novamente.';

  @override
  String get errorLoginServiceUnavailable =>
      'O serviço de login está temporariamente indisponível. Tente mais tarde.';

  @override
  String get errorSessionExpired => 'Sua sessão expirou. Faça login novamente.';

  @override
  String get errorForbiddenTitle => 'Permission Required';

  @override
  String get errorForbiddenMessage =>
      'You don\'t have permission to perform this action. Please check your login status or try again later.';

  @override
  String get journeyInboxForbiddenTitle => 'Cannot Load Inbox';

  @override
  String get journeyInboxForbiddenMessage =>
      'You don\'t have permission to view the inbox. If the problem persists, please sign in again.';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageJapanese => 'Japonês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageChinese => 'Chinês';

  @override
  String get composeTitle => 'Escrever mensagem';

  @override
  String get composeWizardStep1Title => 'Que mensagem vai nessa jornada?';

  @override
  String get composeWizardStep1Subtitle =>
      'Escreva uma frase para iniciar o revezamento.';

  @override
  String get composeWizardStep2Title => 'Para quantas pessoas enviar?';

  @override
  String get composeWizardStep2Subtitle => 'Escolha entre 1 e 5.';

  @override
  String get composeWizardStep3Title => 'Quer enviar uma foto junto?';

  @override
  String get composeWizardStep3Subtitle =>
      'Até 3 fotos. Você também pode enviar sem foto.';

  @override
  String get composeWizardBack => 'Voltar';

  @override
  String get composeWizardNext => 'Próximo';

  @override
  String get composeLabel => 'Mensagem';

  @override
  String get composeHint => 'Compartilhe o que pensa...';

  @override
  String composeCharacterCount(Object current, Object total) {
    return '$current/$total';
  }

  @override
  String get composeImagesTitle => 'Imagens';

  @override
  String get composeAddImage => 'Adicionar foto';

  @override
  String get composeSubmit => 'Enviar';

  @override
  String get composeCta => 'Escrever mensagem';

  @override
  String get composeTooLong => 'A mensagem é longa demais.';

  @override
  String get composeForbidden => 'Remova URLs ou contatos.';

  @override
  String get composeEmpty => 'Digite uma mensagem.';

  @override
  String get composeInvalid => 'Confira o conteúdo da mensagem.';

  @override
  String get composeImageLimit => 'Você pode anexar até 3 imagens.';

  @override
  String get composePermissionDenied =>
      'É preciso acesso às fotos para anexar imagens.';

  @override
  String get composeSessionMissing => 'Faça login novamente.';

  @override
  String get composeSubmitFailed =>
      'Não foi possível enviar sua mensagem. Tente novamente.';

  @override
  String get composeServerMisconfigured =>
      'A configuração do serviço ainda não está pronta. Tente mais tarde.';

  @override
  String get composeSubmitSuccess => 'Sua mensagem foi enviada.';

  @override
  String get composeRecipientCountLabel => 'Quantidade de relés';

  @override
  String get composeRecipientCountHint => 'Selecione de 1 a 5 pessoas.';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count pessoas';
  }

  @override
  String get composeRecipientRequired =>
      'Selecione quantas pessoas receberão a mensagem.';

  @override
  String get composeRecipientInvalid =>
      'Você só pode selecionar entre 1 e 5 pessoas.';

  @override
  String get composeErrorTitle => 'Aviso';

  @override
  String get composeSuccessTitle => 'Concluído';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Cancelar';

  @override
  String get composePermissionTitle => 'Permitir acesso às fotos';

  @override
  String get composePermissionMessage =>
      'Abra Ajustes para permitir acesso às fotos.';

  @override
  String get composeOpenSettings => 'Abrir ajustes';

  @override
  String get journeyListTitle => 'Mensagens enviadas';

  @override
  String get journeyListEmpty => 'Ainda não há mensagens enviadas.';

  @override
  String get journeyListCta => 'Ver mensagens enviadas';

  @override
  String get journeyListStatusLabel => 'Status:';

  @override
  String get journeyStatusCreated => 'Enviado';

  @override
  String get journeyStatusWaiting => 'Aguardando correspondência';

  @override
  String get journeyStatusCompleted => 'Concluído';

  @override
  String get journeyStatusInProgress => 'Em andamento';

  @override
  String get journeyStatusUnknown => 'Desconhecido';

  @override
  String get journeyInProgressHint =>
      'Você poderá ver as respostas após a conclusão';

  @override
  String get journeyFilterOk => 'Permitido';

  @override
  String get journeyFilterHeld => 'Em revisão';

  @override
  String get journeyFilterRemoved => 'Removido';

  @override
  String get journeyFilterUnknown => 'Desconhecido';

  @override
  String get inboxTitle => 'Caixa de entrada';

  @override
  String get inboxEmpty => 'Ainda não há mensagens recebidas.';

  @override
  String get inboxCta => 'Ver caixa de entrada';

  @override
  String get inboxRefresh => 'Atualizar';

  @override
  String get inboxLoadFailed =>
      'Não conseguimos carregar sua caixa de entrada.';

  @override
  String inboxImageCount(Object count) {
    return '$count foto(s)';
  }

  @override
  String get inboxStatusLabel => 'Status:';

  @override
  String get inboxStatusAssigned => 'Em espera';

  @override
  String get inboxStatusResponded => 'Respondido';

  @override
  String get inboxStatusPassed => 'Passado';

  @override
  String get inboxStatusReported => 'Reportado';

  @override
  String get inboxStatusUnknown => 'Desconhecido';

  @override
  String get inboxDetailTitle => 'Mensagem recebida';

  @override
  String get inboxDetailMissing => 'Não foi possível carregar esta mensagem.';

  @override
  String get inboxImagesLabel => 'Fotos';

  @override
  String get inboxImagesLoadFailed => 'Não foi possível carregar as fotos.';

  @override
  String get inboxBlockCta => 'Bloquear remetente';

  @override
  String get inboxBlockTitle => 'Bloquear usuário';

  @override
  String get inboxBlockMessage => 'Bloquear este usuário para futuros envios?';

  @override
  String get inboxBlockConfirm => 'Bloquear';

  @override
  String get inboxBlockSuccessTitle => 'Bloqueado';

  @override
  String get inboxBlockSuccessBody => 'O usuário foi bloqueado.';

  @override
  String get inboxBlockFailed => 'Não foi possível bloquear o usuário.';

  @override
  String get inboxBlockMissing => 'Não foi possível identificar o remetente.';

  @override
  String get inboxRespondLabel => 'Responder';

  @override
  String get inboxRespondHint => 'Escreva sua resposta...';

  @override
  String get inboxRespondCta => 'Enviar resposta';

  @override
  String get inboxRespondEmpty => 'Digite uma resposta.';

  @override
  String get inboxRespondSuccessTitle => 'Resposta enviada';

  @override
  String get inboxRespondSuccessBody => 'Sua resposta foi enviada.';

  @override
  String get inboxPassCta => 'Passar';

  @override
  String get inboxPassSuccessTitle => 'Passado';

  @override
  String get inboxPassSuccessBody => 'Você passou esta mensagem.';

  @override
  String get inboxPassedTitle => 'Mensagem passada';

  @override
  String get inboxPassedDetailUnavailable =>
      'Esta mensagem foi passada e o conteúdo não está disponível.';

  @override
  String get inboxReportCta => 'Denunciar';

  @override
  String get inboxReportTitle => 'Motivo da denúncia';

  @override
  String get inboxReportSpam => 'Spam';

  @override
  String get inboxReportAbuse => 'Abuso';

  @override
  String get inboxReportOther => 'Outro';

  @override
  String get inboxReportSuccessTitle => 'Denúncia enviada';

  @override
  String get inboxReportSuccessBody => 'Sua denúncia foi enviada.';

  @override
  String get inboxActionFailed => 'Não foi possível concluir a ação.';

  @override
  String get journeyDetailTitle => 'Mensagem';

  @override
  String get journeyDetailMessageLabel => 'Mensagem';

  @override
  String get journeyDetailMessageUnavailable =>
      'Não foi possível carregar a mensagem.';

  @override
  String get journeyDetailProgressTitle => 'Progresso do relé';

  @override
  String get journeyDetailStatusLabel => 'Status';

  @override
  String get journeyDetailDeadlineLabel => 'Prazo do relé';

  @override
  String get journeyDetailResponseTargetLabel => 'Meta de respostas';

  @override
  String get journeyDetailRespondedLabel => 'Respostas';

  @override
  String get journeyDetailAssignedLabel => 'Atribuídos';

  @override
  String get journeyDetailPassedLabel => 'Passados';

  @override
  String get journeyDetailReportedLabel => 'Denunciados';

  @override
  String get journeyDetailCountriesLabel => 'Locais do relé';

  @override
  String get journeyDetailCountriesEmpty => 'Ainda não há locais.';

  @override
  String get journeyDetailResultsTitle => 'Respostas';

  @override
  String get journeyDetailResultsLocked =>
      'As respostas aparecem após a conclusão.';

  @override
  String get journeyDetailResultsEmpty => 'Ainda não há respostas.';

  @override
  String get journeyDetailResultsLoadFailed =>
      'Não foi possível carregar as respostas.';

  @override
  String get commonTemporaryErrorTitle => 'Erro temporário';

  @override
  String get sentDetailRepliesLoadFailedMessage =>
      'Não foi possível carregar as respostas.\nVoltaremos à lista.';

  @override
  String get commonOk => 'OK';

  @override
  String get journeyDetailResponsesMissingTitle => 'Erro temporário';

  @override
  String get journeyDetailResponsesMissingBody =>
      'Não foi possível carregar as respostas. Tente novamente.\nVoltaremos à lista.';

  @override
  String get journeyDetailGateConfigTitle => 'Anúncio não configurado';

  @override
  String get journeyDetailGateConfigBody =>
      'A configuração de anúncios não está pronta. Vamos abrir os detalhes sem anúncio.';

  @override
  String get journeyDetailGateDismissedTitle => 'Anúncio não concluído';

  @override
  String get journeyDetailGateDismissedBody =>
      'Assista ao anúncio até o fim para ver os detalhes.';

  @override
  String get journeyDetailGateFailedTitle => 'Anúncio indisponível';

  @override
  String get journeyDetailGateFailedBody =>
      'Não foi possível carregar o anúncio. Tente novamente.';

  @override
  String get journeyDetailUnlockFailedTitle => 'Falha ao salvar o desbloqueio';

  @override
  String get journeyDetailUnlockFailedBody =>
      'Não foi possível salvar o desbloqueio por um problema de rede/servidor. Tente novamente.';

  @override
  String get journeyDetailGateDialogTitle =>
      'Desbloquear com anúncio recompensado';

  @override
  String get journeyDetailGateDialogBody =>
      'Desbloqueie assistindo a um anúncio recompensado.\nAssista uma vez para desbloquear para sempre.';

  @override
  String get journeyDetailGateDialogConfirm => 'Desbloquear';

  @override
  String get journeyDetailLoadFailed =>
      'Não foi possível carregar o progresso.';

  @override
  String get journeyDetailRetry => 'Tentar novamente';

  @override
  String get journeyDetailAdRequired =>
      'Assista a um anúncio para ver os resultados.';

  @override
  String get journeyDetailAdCta => 'Assistir anúncio e desbloquear';

  @override
  String get journeyDetailAdFailedTitle => 'Anúncio indisponível';

  @override
  String get journeyDetailAdFailedBody =>
      'Não foi possível carregar o anúncio. Ver os resultados mesmo assim?';

  @override
  String get journeyDetailAdFailedConfirm => 'Ver resultados';

  @override
  String get journeyResultReportCta => 'Denunciar resposta';

  @override
  String get journeyResultReportSuccessTitle => 'Denúncia enviada';

  @override
  String get journeyResultReportSuccessBody => 'Sua denúncia foi enviada.';

  @override
  String get journeyResultReportFailed => 'Não foi possível enviar a denúncia.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSectionNotification => 'Notificações';

  @override
  String get settingsNotificationToggle => 'Permitir notificações';

  @override
  String get settingsNotificationHint => 'Receba atualizações e resultados.';

  @override
  String get settingsSectionSafety => 'Segurança';

  @override
  String get settingsBlockedUsers => 'Usuários bloqueados';

  @override
  String get settingsLoadFailed =>
      'Não foi possível carregar as configurações.';

  @override
  String get settingsUpdateFailed =>
      'Não foi possível atualizar as configurações.';

  @override
  String get blockListTitle => 'Usuários bloqueados';

  @override
  String get blockListEmpty => 'Nenhum usuário bloqueado.';

  @override
  String get blockListUnknownUser => 'Usuário desconhecido';

  @override
  String get blockListLoadFailed =>
      'Não foi possível carregar a lista de bloqueados.';

  @override
  String get blockListUnblock => 'Desbloquear';

  @override
  String get blockListUnblockTitle => 'Desbloquear usuário';

  @override
  String get blockListUnblockMessage =>
      'Permitir mensagens deste usuário novamente?';

  @override
  String get blockListUnblockConfirm => 'Desbloquear';

  @override
  String get blockListUnblockFailed =>
      'Não foi possível desbloquear o usuário.';

  @override
  String get onboardingTitle => 'Introdução';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Etapa $current de $total';
  }

  @override
  String get onboardingNotificationTitle => 'Permissão de notificações';

  @override
  String get onboardingNotificationDescription =>
      'Notificaremos quando as mensagens de revezamento chegarem e os resultados estiverem prontos.';

  @override
  String get onboardingNotificationNote =>
      'Você pode alterar isso a qualquer momento em Ajustes. Esta etapa é opcional.';

  @override
  String get onboardingAllowNotifications => 'Permitir';

  @override
  String get onboardingPhotoTitle => 'Acesso às fotos';

  @override
  String get onboardingPhotoDescription =>
      'Usado apenas para definir imagens de perfil e anexar imagens às mensagens.';

  @override
  String get onboardingPhotoNote =>
      'Acessamos apenas as fotos que você selecionar. Esta etapa é opcional.';

  @override
  String get onboardingAllowPhotos => 'Permitir';

  @override
  String get onboardingGuidelineTitle => 'Diretrizes da comunidade';

  @override
  String get onboardingGuidelineDescription =>
      'Para um uso seguro, são proibidos o assédio, o discurso de ódio e o compartilhamento de informações pessoais. As violações podem resultar em restrições de conteúdo.';

  @override
  String get onboardingAgreeGuidelines =>
      'Concordo com as diretrizes da comunidade.';

  @override
  String get onboardingContentPolicyTitle => 'Política de conteúdo';

  @override
  String get onboardingContentPolicyDescription =>
      'Conteúdo ilegal, prejudicial e violento é proibido. O conteúdo em violação pode ser restringido após análise.';

  @override
  String get onboardingAgreeContentPolicy =>
      'Concordo com a política de conteúdo.';

  @override
  String get onboardingSafetyTitle => 'Denunciar e bloquear';

  @override
  String get onboardingSafetyDescription =>
      'Você pode denunciar conteúdo ofensivo ou inadequado, ou bloquear usuários específicos para não receber mais suas mensagens.';

  @override
  String get onboardingConfirmSafety =>
      'Entendo a política de denúncia e bloqueio.';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingAgreeAndDisagree => 'Concordar e Discordar';

  @override
  String get onboardingPrevious => 'Anterior';

  @override
  String get ctaPermissionChoice => 'Escolher Permissão';

  @override
  String get onboardingExitTitle => 'Sair da introdução?';

  @override
  String get onboardingExitMessage => 'Você pode começar novamente mais tarde.';

  @override
  String get onboardingExitConfirm => 'Sair';

  @override
  String get onboardingExitCancel => 'Continuar';

  @override
  String get exitConfirmTitle => 'Cancelar escrita?';

  @override
  String get exitConfirmMessage => 'Sua entrada será perdida.';

  @override
  String get exitConfirmContinue => 'Continuar escrevendo';

  @override
  String get exitConfirmLeave => 'Sair';

  @override
  String get tabHomeLabel => 'Início';

  @override
  String get tabSentLabel => 'Enviados';

  @override
  String get tabInboxLabel => 'Caixa de entrada';

  @override
  String get tabCreateLabel => 'Criar mensagem';

  @override
  String get tabAlertsLabel => 'Notificações';

  @override
  String get tabProfileLabel => 'Perfil';

  @override
  String get profileSignOutCta => 'Sair';

  @override
  String get profileSignOutTitle => 'Sair';

  @override
  String get profileSignOutMessage => 'Tem certeza de que deseja sair?';

  @override
  String get profileSignOutConfirm => 'Sair';

  @override
  String get profileUserIdLabel => 'ID de usuário';

  @override
  String get profileDefaultNickname => 'Usuário';

  @override
  String get profileEditCta => 'Editar perfil';

  @override
  String get profileLoginProviderGoogle => 'Login com Google';

  @override
  String get profileLoginProviderApple => 'Login com Apple';

  @override
  String get profileLoginProviderEmail => 'Login com e-mail';

  @override
  String get profileLoginProviderUnknown => 'Sessão iniciada';

  @override
  String get profileMenuNotifications => 'Configurações de notificações';

  @override
  String get profileMenuNotices => 'Avisos';

  @override
  String get profileMenuSupport => 'Suporte';

  @override
  String get profileMenuAppInfo => 'Informações do app';

  @override
  String get profileWithdrawCta => 'Excluir conta';

  @override
  String get profileWithdrawTitle => 'Excluir conta';

  @override
  String get profileWithdrawMessage =>
      'Deseja excluir sua conta? Esta ação não pode ser desfeita.';

  @override
  String get profileWithdrawConfirm => 'Excluir';

  @override
  String get profileFeaturePreparingTitle => 'Em breve';

  @override
  String get profileFeaturePreparingBody =>
      'Este recurso ainda não está disponível.';

  @override
  String get profileAvatarSemantics => 'Avatar do perfil';

  @override
  String get supportTitle => 'Suporte';

  @override
  String get supportStatusMessage => 'O aplicativo instalado está atualizado.';

  @override
  String get supportReleaseNotesTitle => 'Notas de atualização';

  @override
  String supportReleaseNotesHeader(Object version) {
    return 'Última versão $version - novidades';
  }

  @override
  String get supportReleaseNotesBody =>
      '• Melhoramos a experiência e a estabilidade do relé.\n• Ajustamos o tema escuro em perfil e suporte.\n• Corrigimos pequenos bugs e desempenho.';

  @override
  String get supportVersionUnknown => 'Desconhecida';

  @override
  String get supportSuggestCta => 'Enviar sugestão';

  @override
  String get supportReportCta => 'Relatar erro';

  @override
  String get supportFaqTitle => 'Perguntas frequentes';

  @override
  String get supportFaqQ1 => 'Como posso criar uma equipe?';

  @override
  String get supportFaqA1 =>
      'Os recursos de equipe estarão disponíveis em breve.';

  @override
  String get supportFaqQ2 => 'Como convidar membros da equipe?';

  @override
  String get supportFaqA2 =>
      'Convites serão liberados com a função de equipes.';

  @override
  String get supportFaqQ3 => 'Como registrar o calendário de jogos?';

  @override
  String get supportFaqA3 =>
      'O calendário será suportado em uma atualização futura.';

  @override
  String get supportFaqQ4 => 'Não recebo notificações.';

  @override
  String get supportFaqA4 =>
      'Verifique as permissões do sistema e as configurações do app.';

  @override
  String get supportFaqQ5 => 'Como excluir minha conta?';

  @override
  String get supportFaqA5 => 'Vá em Perfil > Excluir conta e siga as etapas.';

  @override
  String get supportActionPreparingTitle => 'Em breve';

  @override
  String get supportActionPreparingBody =>
      'Esta ação estará disponível em breve.';

  @override
  String get appInfoTitle => 'Informações do app';

  @override
  String appInfoVersionLabel(Object version) {
    return 'Versão $version';
  }

  @override
  String get appInfoVersionUnknown => 'Desconhecida';

  @override
  String get appInfoOpenLicenseTitle => 'Licenças abertas';

  @override
  String get appInfoRelatedAppsTitle => 'Apps relacionados da BIZPECT';

  @override
  String get appInfoRelatedApp1Title => 'App de teste 1';

  @override
  String get appInfoRelatedApp1Description =>
      'App de exemplo para testar serviços relacionados.';

  @override
  String get appInfoRelatedApp2Title => 'App de teste 2';

  @override
  String get appInfoRelatedApp2Description =>
      'Outro app de exemplo para integrações relacionadas.';

  @override
  String get appInfoExternalLinkLabel => 'Abrir link externo';

  @override
  String get appInfoLinkPreparingTitle => 'Em breve';

  @override
  String get appInfoLinkPreparingBody =>
      'Este link estará disponível em breve.';

  @override
  String get journeyDetailAnonymous => 'Anônimo';

  @override
  String get errorNetwork => 'Por favor, verifique sua conexão de rede.';

  @override
  String get errorTimeout =>
      'Tempo limite excedido. Por favor, tente novamente.';

  @override
  String get errorServerUnavailable =>
      'O servidor está temporariamente indisponível. Por favor, tente mais tarde.';

  @override
  String get errorUnauthorized => 'Por favor, faça login novamente.';

  @override
  String get errorRetry => 'Tentar novamente';

  @override
  String get errorCancel => 'Cancelar';

  @override
  String get errorAuthRefreshFailed =>
      'A rede está instável. Por favor, tente novamente em breve.';
}
