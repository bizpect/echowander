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
  String get loginTerms => 'Ao iniciar sessão, concorda com os nossos Termos de Serviço e Política de Privacidade';

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
  String get homeEmptyDescription => 'Envie a sua primeira mensagem de relé ou verifique a sua caixa de entrada.';

  @override
  String get homeInboxCardTitle => 'Caixa de entrada';

  @override
  String get homeInboxCardDescription => 'Veja e responda às mensagens que recebeu.';

  @override
  String get homeCreateCardTitle => 'Criar mensagem';

  @override
  String get homeCreateCardDescription => 'Inicie uma nova mensagem de relé.';

  @override
  String get homeJourneyCardViewDetails => 'Ver detalhes';

  @override
  String get homeRefresh => 'Atualizar';

  @override
  String get homeExitTitle => 'Sair da app?';

  @override
  String get homeExitMessage => 'A app será encerrada.';

  @override
  String get homeExitCancel => 'Cancelar';

  @override
  String get homeExitConfirm => 'Sair';

  @override
  String get homeExitAdLoading => 'Carregando anúncio...';

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
  String get pushPreviewDescription => 'Este é um ecrã de teste para links profundos de notificações.';

  @override
  String get notificationTitle => 'Nova mensagem';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationDismiss => 'Fechar';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String notificationsUnreadCountLabel(Object count) {
    return 'Notificações não lidas $count';
  }

  @override
  String get notificationsUnreadCountOverflow => '9+';

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
  String get errorLoginNetwork => 'Verifique a sua ligação de rede e tente novamente.';

  @override
  String get errorLoginInvalidToken => 'A verificação do início de sessão falhou. Tente novamente.';

  @override
  String get errorLoginUnsupportedProvider => 'Este método de início de sessão não é suportado.';

  @override
  String get errorLoginUserSyncFailed => 'Não foi possível guardar a sua conta. Tente novamente.';

  @override
  String get errorLoginServiceUnavailable => 'O serviço de início de sessão está temporariamente indisponível. Tente mais tarde.';

  @override
  String get errorSessionExpired => 'A sua sessão expirou. Inicie sessão novamente.';

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
  String get composeWizardStep1Subtitle => 'Escreva uma frase para iniciar o revezamento.';

  @override
  String get composeWizardStep2Title => 'Para quantas pessoas enviar?';

  @override
  String get composeWizardStep2Subtitle => 'Escolha entre 10 e 50.';

  @override
  String get composeWizardStep3Title => 'Quer enviar uma foto junto?';

  @override
  String get composeWizardStep3Subtitle => 'Até 3 fotos. Você também pode enviar sem foto.';

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
  String get composeImageHelper => 'Você pode anexar até 3 fotos.';

  @override
  String get composeImageUploadHint => 'Carregue uma imagem.';

  @override
  String get composeImageDelete => 'Eliminar imagem';

  @override
  String get composeSelectedImagesTitle => 'Imagens selecionadas';

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
  String get composeImageReadFailed => 'Não foi possível ler a imagem. Tente novamente.';

  @override
  String get composeImageOptimizationFailed => 'Falha no processamento da imagem. Tente novamente.';

  @override
  String get composePermissionDenied => 'É necessário acesso às fotos.';

  @override
  String get composeSessionMissing => 'Inicie sessão novamente.';

  @override
  String get composeSubmitFailed => 'Não foi possível enviar a mensagem. Tente novamente.';

  @override
  String get composeServerMisconfigured => 'A configuração do serviço ainda não está pronta. Tente mais tarde.';

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
  String get composeRecipientRequired => 'Selecione quantas pessoas receberão a mensagem.';

  @override
  String get composeRecipientInvalid => 'Só pode selecionar entre 1 e 5 pessoas.';

  @override
  String get composeErrorTitle => 'Aviso';

  @override
  String get composeSuccessTitle => 'Concluído';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Cancelar';

  @override
  String get sessionExpiredTitle => 'Sessão Expirada';

  @override
  String get sessionExpiredBody => 'A sua sessão expirou. Por favor, inicie sessão novamente.';

  @override
  String get sessionExpiredCtaLogin => 'Iniciar Sessão';

  @override
  String get sendFailedTitle => 'Falha no Envio';

  @override
  String get sendFailedTryAgain => 'Falha ao enviar mensagem. Por favor, tente novamente.';

  @override
  String get moderationContentBlockedMessage => 'O conteúdo da mensagem é inadequado.';

  @override
  String get moderationBlockedTitle => 'Não é possível enviar';

  @override
  String get nicknameForbiddenMessage => 'Seu apelido contém palavras proibidas.';

  @override
  String get nicknameTakenMessage => 'Este apelido já está em uso.';

  @override
  String get composeContentBlocked => 'Este conteúdo não pode ser enviado.';

  @override
  String get composeContentBlockedProfanity => 'Linguagem inadequada não é permitida.';

  @override
  String get composeContentBlockedSexual => 'Conteúdo sexual é proibido.';

  @override
  String get composeContentBlockedHate => 'Discurso de ódio é proibido.';

  @override
  String get composeContentBlockedThreat => 'Conteúdo ameaçador é proibido.';

  @override
  String get replyContentBlocked => 'Este conteúdo não pode ser enviado.';

  @override
  String get replyContentBlockedProfanity => 'Linguagem inadequada não é permitida.';

  @override
  String get replyContentBlockedSexual => 'Conteúdo sexual é proibido.';

  @override
  String get replyContentBlockedHate => 'Discurso de ódio é proibido.';

  @override
  String get replyContentBlockedThreat => 'Conteúdo ameaçador é proibido.';

  @override
  String get composePermissionTitle => 'Permitir acesso a fotos';

  @override
  String get composePermissionMessage => 'Abra as Definições para permitir o acesso a fotos.';

  @override
  String get composeOpenSettings => 'Abrir definições';

  @override
  String get commonClose => 'Fechar';

  @override
  String get journeyListTitle => 'Mensagens enviadas';

  @override
  String get sentTabInProgress => 'Em andamento';

  @override
  String get sentTabCompleted => 'Concluído';

  @override
  String get sentEmptyInProgressTitle => 'Nenhuma mensagem em andamento';

  @override
  String get sentEmptyInProgressDescription => 'Inicie uma nova mensagem para vê-la aqui.';

  @override
  String get sentEmptyCompletedTitle => 'Nenhuma mensagem concluída';

  @override
  String get sentEmptyCompletedDescription => 'As mensagens concluídas aparecerão aqui.';

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
  String get journeyInProgressHint => 'Poderá ver as respostas após a conclusão';

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
  String get inboxTabPending => 'Pendentes';

  @override
  String get inboxTabCompleted => 'Respondidas';

  @override
  String get inboxEmpty => 'Ainda não há mensagens recebidas.';

  @override
  String get inboxEmptyPendingTitle => 'Nenhuma mensagem pendente';

  @override
  String get inboxEmptyPendingDescription => 'Novas mensagens aparecerão aqui.';

  @override
  String get inboxEmptyCompletedTitle => 'Nenhuma mensagem respondida';

  @override
  String get inboxEmptyCompletedDescription => 'Mensagens que você respondeu aparecerão aqui.';

  @override
  String get inboxCta => 'Ver caixa de entrada';

  @override
  String get inboxRefresh => 'Atualizar';

  @override
  String get inboxLoadFailed => 'Não conseguimos carregar a sua caixa de entrada.';

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
  String get inboxCardArrivedPrompt => 'Chegou uma mensagem!\nDeixe uma resposta.';

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
  String get inboxPassedDetailUnavailable => 'Esta mensagem foi passada e o conteúdo não está disponível.';

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
  String get inboxReportAlreadyReportedTitle => 'Já denunciado';

  @override
  String get inboxReportAlreadyReportedBody => 'Você já denunciou esta mensagem.';

  @override
  String get inboxActionFailed => 'Não foi possível concluir a ação.';

  @override
  String get actionReportMessage => 'Denunciar mensagem';

  @override
  String get actionBlockSender => 'Bloquear remetente';

  @override
  String get inboxDetailMoreTitle => 'Opções';

  @override
  String get journeyDetailTitle => 'Mensagem';

  @override
  String get journeyDetailMessageLabel => 'Mensagem';

  @override
  String get journeyDetailMessageUnavailable => 'Não foi possível carregar a mensagem.';

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
  String get journeyDetailResultsLocked => 'As respostas aparecerão após a conclusão.';

  @override
  String get journeyDetailResultsEmpty => 'Ainda não há respostas.';

  @override
  String get journeyDetailResultsLoadFailed => 'Não foi possível carregar as respostas.';

  @override
  String get commonTemporaryErrorTitle => 'Erro temporário';

  @override
  String get sentDetailRepliesLoadFailedMessage => 'Não foi possível carregar as respostas.\nVoltaremos à lista.';

  @override
  String get commonOk => 'OK';

  @override
  String get journeyDetailResponsesMissingTitle => 'Erro temporário';

  @override
  String get journeyDetailResponsesMissingBody => 'Não foi possível carregar as respostas. Tente novamente.\nVoltaremos à lista.';

  @override
  String get journeyDetailGateConfigTitle => 'Anúncio não pronto';

  @override
  String get journeyDetailGateConfigBody => 'A configuração de anúncios não está pronta. Vamos abrir os detalhes sem anúncio.';

  @override
  String get journeyDetailGateDismissedTitle => 'Anúncio não concluído';

  @override
  String get journeyDetailGateDismissedBody => 'Assista ao anúncio até o fim para ver os detalhes.';

  @override
  String get journeyDetailGateFailedTitle => 'Anúncio indisponível';

  @override
  String get journeyDetailGateFailedBody => 'Não foi possível carregar o anúncio. Tente novamente.';

  @override
  String get journeyDetailUnlockFailedTitle => 'Falha ao salvar o desbloqueio';

  @override
  String get journeyDetailUnlockFailedBody => 'Não foi possível salvar o desbloqueio por um problema de rede/servidor. Tente novamente.';

  @override
  String get journeyDetailGateDialogTitle => 'Desbloquear com anúncio recompensado';

  @override
  String get journeyDetailGateDialogBody => 'Desbloqueie assistindo a um anúncio recompensado.\nAssista uma vez para desbloquear para sempre.';

  @override
  String get journeyDetailGateDialogConfirm => 'Desbloquear';

  @override
  String get journeyDetailLoadFailed => 'Não foi possível carregar o progresso.';

  @override
  String get journeyDetailRetry => 'Tentar novamente';

  @override
  String get journeyDetailAdRequired => 'Assista a um anúncio para ver os resultados.';

  @override
  String get journeyDetailAdCta => 'Assistir anúncio e desbloquear';

  @override
  String get journeyDetailAdFailedTitle => 'Anúncio indisponível';

  @override
  String get journeyDetailAdFailedBody => 'Não foi possível carregar o anúncio. Ver os resultados mesmo assim?';

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
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsSectionSafety => 'Segurança';

  @override
  String get settingsBlockedUsers => 'Usuários bloqueados';

  @override
  String get settingsLoadFailed => 'Não foi possível carregar as configurações.';

  @override
  String get settingsUpdateFailed => 'Não foi possível atualizar as configurações.';

  @override
  String get blockListTitle => 'Usuários bloqueados';

  @override
  String get blockListEmpty => 'Nenhum usuário bloqueado.';

  @override
  String get blockListUnknownUser => 'Usuário desconhecido';

  @override
  String get blockListLoadFailed => 'Não foi possível carregar a lista de bloqueados.';

  @override
  String get blockListUnblock => 'Desbloquear';

  @override
  String get blockListUnblockTitle => 'Desbloquear usuário';

  @override
  String get blockListUnblockMessage => 'Permitir mensagens deste usuário novamente?';

  @override
  String get blockListUnblockConfirm => 'Desbloquear';

  @override
  String get blockListUnblockFailed => 'Não foi possível desbloquear o usuário.';

  @override
  String get blockUnblockedTitle => 'Concluído';

  @override
  String get blockUnblockedMessage => 'Usuário desbloqueado.';

  @override
  String get onboardingTitle => 'Integração';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Etapa $current de $total';
  }

  @override
  String get onboardingNotificationTitle => 'Permissão de notificações';

  @override
  String get onboardingNotificationDescription => 'Notificaremos quando as mensagens de revezamento chegarem e os resultados estiverem prontos.';

  @override
  String get onboardingNotificationNote => 'Pode alterar isto a qualquer momento nas Definições. Esta etapa é opcional.';

  @override
  String get onboardingAllowNotifications => 'Permitir';

  @override
  String get onboardingPhotoTitle => 'Acesso a fotos';

  @override
  String get onboardingPhotoDescription => 'Usado apenas para definir imagens de perfil e anexar imagens às mensagens.';

  @override
  String get onboardingPhotoNote => 'Acedemos apenas às fotos que selecionar. Esta etapa é opcional.';

  @override
  String get onboardingAllowPhotos => 'Permitir';

  @override
  String get onboardingGuidelineTitle => 'Diretrizes da comunidade';

  @override
  String get onboardingGuidelineDescription => 'Para uma utilização segura, são proibidos o assédio, o discurso de ódio e a partilha de informações pessoais. As violações podem resultar em restrições de conteúdo.';

  @override
  String get onboardingAgreeGuidelines => 'Concordo com as diretrizes da comunidade.';

  @override
  String get onboardingContentPolicyTitle => 'Política de conteúdo';

  @override
  String get onboardingContentPolicyDescription => 'Conteúdo ilegal, prejudicial e violento é proibido. O conteúdo em violação pode ser restringido após análise.';

  @override
  String get onboardingAgreeContentPolicy => 'Concordo com a política de conteúdo.';

  @override
  String get onboardingSafetyTitle => 'Denunciar e bloquear';

  @override
  String get onboardingSafetyDescription => 'Pode denunciar conteúdo ofensivo ou inadequado, ou bloquear utilizadores específicos para deixar de receber as suas mensagens.';

  @override
  String get onboardingConfirmSafety => 'Compreendo a política de denúncia e bloqueio.';

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
  String get noticeTitle => 'Avisos';

  @override
  String get noticeDetailTitle => 'Avisos';

  @override
  String get noticeFilterLabel => 'Tipo de aviso';

  @override
  String get noticeFilterAll => 'Todos';

  @override
  String get noticeFilterSheetTitle => 'Selecionar tipo de aviso';

  @override
  String get noticeTypeUnknown => 'Desconhecido';

  @override
  String get noticePinnedBadge => 'Fixado';

  @override
  String get noticeEmptyTitle => 'Sem avisos';

  @override
  String get noticeEmptyDescription => 'Não há avisos desse tipo.';

  @override
  String get noticeErrorTitle => 'Não foi possível carregar os avisos';

  @override
  String get noticeErrorDescription => 'Tente novamente mais tarde.';

  @override
  String get profileSignOutCta => 'Terminar sessão';

  @override
  String get profileSignOutTitle => 'Terminar sessão';

  @override
  String get profileSignOutMessage => 'Tem a certeza de que deseja terminar sessão?';

  @override
  String get profileSignOutConfirm => 'Terminar sessão';

  @override
  String get profileUserIdLabel => 'ID de utilizador';

  @override
  String get profileDefaultNickname => 'Utilizador';

  @override
  String get profileEditCta => 'Editar perfil';

  @override
  String get authProviderKakaoLogin => 'Login com Kakao';

  @override
  String get authProviderGoogleLogin => 'Login com Google';

  @override
  String get authProviderAppleLogin => 'Login com Apple';

  @override
  String get authProviderUnknownLogin => 'Sessão iniciada';

  @override
  String get profileLoginProviderKakao => 'Login com Kakao';

  @override
  String get profileLoginProviderGoogle => 'Login com Google';

  @override
  String get profileLoginProviderApple => 'Login com Apple';

  @override
  String get profileLoginProviderEmail => 'Login com e-mail';

  @override
  String get profileLoginProviderUnknown => 'Sessão iniciada';

  @override
  String get profileAppSettings => 'Configurações do app';

  @override
  String get profileMenuNotices => 'Avisos';

  @override
  String get profileMenuSupport => 'Suporte';

  @override
  String get profileMenuAppInfo => 'Informações do app';

  @override
  String get profileMenuTitle => 'Menu';

  @override
  String get profileMenuSubtitle => 'Acesso rápido às configurações mais usadas.';

  @override
  String get profileWithdrawCta => 'Eliminar conta';

  @override
  String get profileWithdrawTitle => 'Eliminar conta';

  @override
  String get profileWithdrawMessage => 'Quer eliminar a sua conta? Esta ação não pode ser desfeita.';

  @override
  String get profileWithdrawConfirm => 'Eliminar';

  @override
  String get profileFeaturePreparingTitle => 'Em breve';

  @override
  String get profileFeaturePreparingBody => 'Esta funcionalidade ainda não está disponível.';

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
  String get supportReleaseNotesBody => '• Melhoramos a experiência e a estabilidade do relé.\n• Ajustamos o tema escuro em perfil e suporte.\n• Corrigimos pequenos bugs e desempenho.';

  @override
  String get supportVersionUnknown => 'Desconhecida';

  @override
  String get supportSuggestCta => 'Enviar sugestão';

  @override
  String get supportReportCta => 'Relatar erro';

  @override
  String get supportFaqTitle => 'Perguntas frequentes';

  @override
  String get supportFaqSubtitle => 'Confira as dúvidas mais comuns.';

  @override
  String get supportFaqQ1 => 'As mensagens não parecem ser entregues. Por quê?';

  @override
  String get supportFaqA1 => 'A entrega pode ser atrasada ou restrita devido ao status da rede, atrasos temporários do servidor ou políticas de segurança (denúncias/bloqueios, etc.). Por favor, tente novamente mais tarde.';

  @override
  String get supportFaqQ2 => 'Não estou recebendo notificações. O que devo fazer?';

  @override
  String get supportFaqA2 => 'As permissões de notificação do Echowander podem estar desativadas nas configurações do seu telefone. Vá em Configurações do app → Configurações do app (Configurações de notificação) para ativar as permissões de notificação e também verifique as restrições de economia de bateria/segundo plano.';

  @override
  String get supportFaqQ3 => 'Recebi uma mensagem desagradável. Como bloqueio/denuncio?';

  @override
  String get supportFaqA3 => 'Você pode selecionar Denunciar ou Bloquear na tela da mensagem. Bloquear impede que você receba mais mensagens desse usuário. O conteúdo denunciado pode ser revisado para a segurança da comunidade.';

  @override
  String get supportFaqQ4 => 'Posso editar ou cancelar uma mensagem que enviei?';

  @override
  String get supportFaqA4 => 'Uma vez enviada, as mensagens não podem ser facilmente editadas ou canceladas. Por favor, revise o conteúdo antes de enviar.';

  @override
  String get supportFaqQ5 => 'O que acontece se eu violar as diretrizes da comunidade?';

  @override
  String get supportFaqA5 => 'Violações repetidas podem resultar em restrições de mensagens ou limitações de conta. Por favor, siga as diretrizes para uma comunidade segura.';

  @override
  String get supportActionPreparingTitle => 'Em breve';

  @override
  String get supportActionPreparingBody => 'Esta ação estará disponível em breve.';

  @override
  String get supportSuggestionSubject => 'Pedido de sugestão';

  @override
  String get supportBugSubject => 'Relatório de erro';

  @override
  String supportEmailFooterUser(String userId) {
    return 'Usuário : $userId';
  }

  @override
  String supportEmailFooterVersion(String version) {
    return 'Versão do app : $version';
  }

  @override
  String get supportEmailLaunchFailed => 'Não foi possível abrir o aplicativo de e-mail. Por favor, tente novamente mais tarde.';

  @override
  String get appInfoTitle => 'Informações do app';

  @override
  String get appInfoSettingsTitle => 'Configurações do app';

  @override
  String get appInfoSettingsSubtitle => 'Veja licenças e políticas.';

  @override
  String get appInfoSectionTitle => 'Serviços conectados';

  @override
  String get appInfoSectionSubtitle => 'Confira os apps vinculados ao serviço.';

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
  String get appInfoRelatedApp1Description => 'App de exemplo para testar serviços relacionados.';

  @override
  String get appInfoRelatedApp2Title => 'App de teste 2';

  @override
  String get appInfoRelatedApp2Description => 'Outro app de exemplo para integrações relacionadas.';

  @override
  String get appInfoExternalLinkLabel => 'Abrir link externo';

  @override
  String get appInfoLinkPreparingTitle => 'Em breve';

  @override
  String get appInfoLinkPreparingBody => 'Este link estará disponível em breve.';

  @override
  String get openLicenseTitle => 'Licenças abertas';

  @override
  String get openLicenseHeaderTitle => 'Bibliotecas de código aberto';

  @override
  String get openLicenseHeaderBody => 'Este app usa as seguintes bibliotecas de código aberto.';

  @override
  String get openLicenseSectionTitle => 'Lista de licenças';

  @override
  String get openLicenseSectionSubtitle => 'Confira os pacotes de código aberto em uso.';

  @override
  String openLicenseChipVersion(Object version) {
    return 'Versão: $version';
  }

  @override
  String openLicenseChipLicense(Object license) {
    return 'Licença: $license';
  }

  @override
  String get openLicenseChipDetails => 'Detalhes';

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
  String get openLicenseTypeUnknown => 'Desconhecida';

  @override
  String get openLicenseUnknown => 'Desconhecida';

  @override
  String get openLicenseEmptyMessage => 'Nenhuma informação de licença disponível.';

  @override
  String openLicenseDetailTitle(Object package) {
    return 'Licença de $package';
  }

  @override
  String get journeyDetailAnonymous => 'Anónimo';

  @override
  String get errorNetwork => 'Por favor, verifique a sua ligação de rede.';

  @override
  String get errorTimeout => 'Tempo limite excedido. Por favor, tente novamente.';

  @override
  String get errorServerUnavailable => 'O servidor está temporariamente indisponível. Por favor, tente mais tarde.';

  @override
  String get errorUnauthorized => 'Por favor, inicie sessão novamente.';

  @override
  String get errorRetry => 'Tentar novamente';

  @override
  String get errorCancel => 'Cancelar';

  @override
  String get errorAuthRefreshFailed => 'A rede está instável. Por favor, tente novamente em breve.';

  @override
  String get homeInboxSummaryTitle => 'Resumo de hoje';

  @override
  String get homeInboxSummaryPending => 'Pendentes';

  @override
  String get homeInboxSummaryCompleted => 'Respondidas';

  @override
  String get homeInboxSummarySentResponses => 'Respostas recebidas';

  @override
  String homeInboxSummaryUpdatedAt(Object time) {
    return 'Atualizado $time';
  }

  @override
  String get homeInboxSummaryRefresh => 'Atualizar';

  @override
  String get homeInboxSummaryLoadFailed => 'Não foi possível carregar o resumo.';

  @override
  String homeInboxSummaryItemSemantics(Object label, Object count) {
    return '$label $count';
  }

  @override
  String get homeTimelineTitle => 'Atividade recente';

  @override
  String get homeTimelineEmptyTitle => 'Sem atividade recente';

  @override
  String get homeTimelineReceivedTitle => 'Nova mensagem recebida';

  @override
  String get homeTimelineRespondedTitle => 'Resposta enviada';

  @override
  String get homeTimelineSentResponseTitle => 'Resposta recebida';

  @override
  String homeTimelineSubtitle(Object time) {
    return '$time';
  }

  @override
  String get homeDailyPromptTitle => 'Pergunta do dia';

  @override
  String get homeDailyPromptHint => 'Toque para escrever uma mensagem';

  @override
  String get homeDailyPromptAction => 'Escrever';

  @override
  String get homeAnnouncementTitle => 'Atualização';

  @override
  String get homeAnnouncementSummary => 'Veja as novidades do Echowander.';

  @override
  String get homeAnnouncementAction => 'Detalhes';

  @override
  String get homeAnnouncementDetailTitle => 'Atualização';

  @override
  String get homeAnnouncementDetailBody => 'Fizemos melhorias para uma experiência mais fluida.';

  @override
  String get homePromptQ1 => 'O que te fez sorrir hoje?';

  @override
  String get homePromptQ2 => 'O que você está aguardando esta semana?';

  @override
  String get homePromptQ3 => 'Que lugar você quer revisitar?';

  @override
  String get homePromptQ4 => 'Compartilhe uma pequena vitória de hoje.';

  @override
  String get homePromptQ5 => 'Que hábito você gostaria de criar?';

  @override
  String get homePromptQ6 => 'A quem você quer agradecer hoje?';

  @override
  String get homePromptQ7 => 'Qual música você está ouvindo em loop?';

  @override
  String get homePromptQ8 => 'Descreva seu dia em três palavras.';

  @override
  String get homePromptQ9 => 'O que você aprendeu recentemente?';

  @override
  String get homePromptQ10 => 'Se pudesse enviar uma mensagem para si, o que diria?';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileEditNicknameLabel => 'Alcunha';

  @override
  String get profileEditNicknameHint => 'Digite a alcunha';

  @override
  String get profileEditNicknameEmpty => 'Por favor, digite uma alcunha';

  @override
  String profileEditNicknameTooShort(Object min) {
    return 'A alcunha deve ter pelo menos $min caracteres';
  }

  @override
  String profileEditNicknameTooLong(Object max) {
    return 'A alcunha pode ter até $max caracteres';
  }

  @override
  String get profileEditNicknameConsecutiveSpaces => 'Espaços consecutivos não são permitidos';

  @override
  String get profileEditNicknameInvalidCharacters => 'Apenas coreano, inglês, números e sublinhado (_) são permitidos';

  @override
  String get profileEditNicknameUnderscoreAtEnds => 'Underscore (_) cannot be used at the beginning or end';

  @override
  String get profileEditNicknameConsecutiveUnderscores => 'Consecutive underscores (__) are not allowed';

  @override
  String get profileEditNicknameForbidden => 'This nickname is not allowed';

  @override
  String get profileEditNicknameChecking => 'A verificar...';

  @override
  String get profileEditNicknameAvailable => 'Esta alcunha está disponível';

  @override
  String get profileEditNicknameTaken => 'Esta alcunha já está em uso';

  @override
  String get profileEditNicknameError => 'Ocorreu um erro ao verificar';

  @override
  String get profileEditAvatarLabel => 'Foto do perfil';

  @override
  String get profileEditAvatarChange => 'Alterar foto';

  @override
  String get profileEditSave => 'Guardar';

  @override
  String get profileEditCancel => 'Cancelar';

  @override
  String get profileEditSaveSuccess => 'Perfil guardado com sucesso';

  @override
  String get profileEditSaveFailed => 'Falha ao guardar. Por favor, tente novamente';

  @override
  String get profileEditImageTooLarge => 'Image file is too large. Please select another image';

  @override
  String get profileEditImageOptimizationFailed => 'An error occurred while processing the image. Please try again';

  @override
  String get profileEditCropTitle => 'Editar foto';

  @override
  String get profileEditCropDescription => 'Ajuste a posição como desejar';

  @override
  String get profileEditCropCancel => 'Cancelar';

  @override
  String get profileEditCropComplete => 'Concluir';

  @override
  String get profileEditCropFailedTitle => 'Falha ao editar foto';

  @override
  String get profileEditCropFailedMessage => 'Ocorreu um erro ao editar a foto. Por favor, tente novamente.';

  @override
  String get profileEditCropFailedAction => 'OK';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr(): super('pt_BR');

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
  String get loginTerms => 'Ao entrar, você concorda com nossos Termos de Serviço e Política de Privacidade';

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
  String get homeEmptyDescription => 'Envie sua primeira mensagem de revezamento ou confira sua caixa de entrada.';

  @override
  String get homeInboxCardTitle => 'Caixa de entrada';

  @override
  String get homeInboxCardDescription => 'Confira e responda as mensagens que você recebeu.';

  @override
  String get homeCreateCardTitle => 'Criar mensagem';

  @override
  String get homeCreateCardDescription => 'Inicie uma nova mensagem de revezamento.';

  @override
  String get homeJourneyCardViewDetails => 'Ver detalhes';

  @override
  String get homeRefresh => 'Atualizar';

  @override
  String get homeExitTitle => 'Sair do app?';

  @override
  String get homeExitMessage => 'O app será encerrado.';

  @override
  String get homeExitCancel => 'Cancelar';

  @override
  String get homeExitConfirm => 'Sair';

  @override
  String get homeExitAdLoading => 'Carregando anúncio...';

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
  String get pushPreviewDescription => 'Esta é uma tela de teste para links profundos de notificações.';

  @override
  String get notificationTitle => 'Nova mensagem';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationDismiss => 'Fechar';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String notificationsUnreadCountLabel(Object count) {
    return 'Notificações não lidas $count';
  }

  @override
  String get notificationsUnreadCountOverflow => '9+';

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
  String get errorLoginNetwork => 'Verifique sua conexão de rede e tente novamente.';

  @override
  String get errorLoginInvalidToken => 'A verificação do login falhou. Tente novamente.';

  @override
  String get errorLoginUnsupportedProvider => 'Este método de login não é compatível.';

  @override
  String get errorLoginUserSyncFailed => 'Não foi possível salvar sua conta. Tente novamente.';

  @override
  String get errorLoginServiceUnavailable => 'O serviço de login está temporariamente indisponível. Tente mais tarde.';

  @override
  String get errorSessionExpired => 'Sua sessão expirou. Faça login novamente.';

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
  String get composeWizardStep1Subtitle => 'Escreva uma frase para iniciar o revezamento.';

  @override
  String get composeWizardStep2Title => 'Para quantas pessoas enviar?';

  @override
  String get composeWizardStep2Subtitle => 'Escolha entre 10 e 50.';

  @override
  String get composeWizardStep3Title => 'Quer enviar uma foto junto?';

  @override
  String get composeWizardStep3Subtitle => 'Até 3 fotos. Você também pode enviar sem foto.';

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
  String get composeImageHelper => 'Você pode anexar até 3 fotos.';

  @override
  String get composeImageUploadHint => 'Carregue uma imagem.';

  @override
  String get composeImageDelete => 'Excluir imagem';

  @override
  String get composeSelectedImagesTitle => 'Imagens selecionadas';

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
  String get composeImageReadFailed => 'Não foi possível ler a imagem. Tente novamente.';

  @override
  String get composeImageOptimizationFailed => 'Falha no processamento da imagem. Tente novamente.';

  @override
  String get composePermissionDenied => 'É preciso acesso às fotos para anexar imagens.';

  @override
  String get composeSessionMissing => 'Faça login novamente.';

  @override
  String get composeSubmitFailed => 'Não foi possível enviar sua mensagem. Tente novamente.';

  @override
  String get composeServerMisconfigured => 'A configuração do serviço ainda não está pronta. Tente mais tarde.';

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
  String get composeRecipientRequired => 'Selecione quantas pessoas receberão a mensagem.';

  @override
  String get composeRecipientInvalid => 'Você só pode selecionar entre 1 e 5 pessoas.';

  @override
  String get composeErrorTitle => 'Aviso';

  @override
  String get composeSuccessTitle => 'Concluído';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Cancelar';

  @override
  String get sessionExpiredTitle => 'Sessão Expirada';

  @override
  String get sessionExpiredBody => 'Sua sessão expirou. Por favor, faça login novamente.';

  @override
  String get sessionExpiredCtaLogin => 'Entrar';

  @override
  String get sendFailedTitle => 'Falha no Envio';

  @override
  String get sendFailedTryAgain => 'Falha ao enviar mensagem. Por favor, tente novamente.';

  @override
  String get moderationContentBlockedMessage => 'O conteúdo da mensagem é inadequado.';

  @override
  String get moderationBlockedTitle => 'Não é possível enviar';

  @override
  String get nicknameForbiddenMessage => 'Seu apelido contém palavras proibidas.';

  @override
  String get nicknameTakenMessage => 'Este apelido já está em uso.';

  @override
  String get composeContentBlocked => 'Este conteúdo não pode ser enviado.';

  @override
  String get composeContentBlockedProfanity => 'Linguagem inadequada não é permitida.';

  @override
  String get composeContentBlockedSexual => 'Conteúdo sexual é proibido.';

  @override
  String get composeContentBlockedHate => 'Discurso de ódio é proibido.';

  @override
  String get composeContentBlockedThreat => 'Conteúdo ameaçador é proibido.';

  @override
  String get replyContentBlocked => 'Este conteúdo não pode ser enviado.';

  @override
  String get replyContentBlockedProfanity => 'Linguagem inadequada não é permitida.';

  @override
  String get replyContentBlockedSexual => 'Conteúdo sexual é proibido.';

  @override
  String get replyContentBlockedHate => 'Discurso de ódio é proibido.';

  @override
  String get replyContentBlockedThreat => 'Conteúdo ameaçador é proibido.';

  @override
  String get composePermissionTitle => 'Permitir acesso às fotos';

  @override
  String get composePermissionMessage => 'Abra Ajustes para permitir acesso às fotos.';

  @override
  String get composeOpenSettings => 'Abrir ajustes';

  @override
  String get commonClose => 'Fechar';

  @override
  String get journeyListTitle => 'Mensagens enviadas';

  @override
  String get sentTabInProgress => 'Em andamento';

  @override
  String get sentTabCompleted => 'Concluído';

  @override
  String get sentEmptyInProgressTitle => 'Nenhuma mensagem em andamento';

  @override
  String get sentEmptyInProgressDescription => 'Inicie uma nova mensagem para vê-la aqui.';

  @override
  String get sentEmptyCompletedTitle => 'Nenhuma mensagem concluída';

  @override
  String get sentEmptyCompletedDescription => 'As mensagens concluídas aparecerão aqui.';

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
  String get journeyInProgressHint => 'Você poderá ver as respostas após a conclusão';

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
  String get inboxTabPending => 'Pendentes';

  @override
  String get inboxTabCompleted => 'Respondidas';

  @override
  String get inboxEmpty => 'Ainda não há mensagens recebidas.';

  @override
  String get inboxEmptyPendingTitle => 'Nenhuma mensagem pendente';

  @override
  String get inboxEmptyPendingDescription => 'Novas mensagens aparecerão aqui.';

  @override
  String get inboxEmptyCompletedTitle => 'Nenhuma mensagem respondida';

  @override
  String get inboxEmptyCompletedDescription => 'Mensagens que você respondeu aparecerão aqui.';

  @override
  String get inboxCta => 'Ver caixa de entrada';

  @override
  String get inboxRefresh => 'Atualizar';

  @override
  String get inboxLoadFailed => 'Não conseguimos carregar sua caixa de entrada.';

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
  String get inboxCardArrivedPrompt => 'Chegou uma mensagem!\nDeixe uma resposta.';

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
  String get inboxPassedDetailUnavailable => 'Esta mensagem foi passada e o conteúdo não está disponível.';

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
  String get inboxReportAlreadyReportedTitle => 'Já denunciado';

  @override
  String get inboxReportAlreadyReportedBody => 'Você já denunciou esta mensagem.';

  @override
  String get inboxActionFailed => 'Não foi possível concluir a ação.';

  @override
  String get actionReportMessage => 'Denunciar mensagem';

  @override
  String get actionBlockSender => 'Bloquear remetente';

  @override
  String get inboxDetailMoreTitle => 'Opções';

  @override
  String get journeyDetailTitle => 'Mensagem';

  @override
  String get journeyDetailMessageLabel => 'Mensagem';

  @override
  String get journeyDetailMessageUnavailable => 'Não foi possível carregar a mensagem.';

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
  String get journeyDetailResultsLocked => 'As respostas aparecem após a conclusão.';

  @override
  String get journeyDetailResultsEmpty => 'Ainda não há respostas.';

  @override
  String get journeyDetailResultsLoadFailed => 'Não foi possível carregar as respostas.';

  @override
  String get commonTemporaryErrorTitle => 'Erro temporário';

  @override
  String get sentDetailRepliesLoadFailedMessage => 'Não foi possível carregar as respostas.\nVoltaremos à lista.';

  @override
  String get commonOk => 'OK';

  @override
  String get journeyDetailResponsesMissingTitle => 'Erro temporário';

  @override
  String get journeyDetailResponsesMissingBody => 'Não foi possível carregar as respostas. Tente novamente.\nVoltaremos à lista.';

  @override
  String get journeyDetailGateConfigTitle => 'Anúncio não configurado';

  @override
  String get journeyDetailGateConfigBody => 'A configuração de anúncios não está pronta. Vamos abrir os detalhes sem anúncio.';

  @override
  String get journeyDetailGateDismissedTitle => 'Anúncio não concluído';

  @override
  String get journeyDetailGateDismissedBody => 'Assista ao anúncio até o fim para ver os detalhes.';

  @override
  String get journeyDetailGateFailedTitle => 'Anúncio indisponível';

  @override
  String get journeyDetailGateFailedBody => 'Não foi possível carregar o anúncio. Tente novamente.';

  @override
  String get journeyDetailUnlockFailedTitle => 'Falha ao salvar o desbloqueio';

  @override
  String get journeyDetailUnlockFailedBody => 'Não foi possível salvar o desbloqueio por um problema de rede/servidor. Tente novamente.';

  @override
  String get journeyDetailGateDialogTitle => 'Desbloquear com anúncio recompensado';

  @override
  String get journeyDetailGateDialogBody => 'Desbloqueie assistindo a um anúncio recompensado.\nAssista uma vez para desbloquear para sempre.';

  @override
  String get journeyDetailGateDialogConfirm => 'Desbloquear';

  @override
  String get journeyDetailLoadFailed => 'Não foi possível carregar o progresso.';

  @override
  String get journeyDetailRetry => 'Tentar novamente';

  @override
  String get journeyDetailAdRequired => 'Assista a um anúncio para ver os resultados.';

  @override
  String get journeyDetailAdCta => 'Assistir anúncio e desbloquear';

  @override
  String get journeyDetailAdFailedTitle => 'Anúncio indisponível';

  @override
  String get journeyDetailAdFailedBody => 'Não foi possível carregar o anúncio. Ver os resultados mesmo assim?';

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
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsSectionSafety => 'Segurança';

  @override
  String get settingsBlockedUsers => 'Usuários bloqueados';

  @override
  String get settingsLoadFailed => 'Não foi possível carregar as configurações.';

  @override
  String get settingsUpdateFailed => 'Não foi possível atualizar as configurações.';

  @override
  String get blockListTitle => 'Usuários bloqueados';

  @override
  String get blockListEmpty => 'Nenhum usuário bloqueado.';

  @override
  String get blockListUnknownUser => 'Usuário desconhecido';

  @override
  String get blockListLoadFailed => 'Não foi possível carregar a lista de bloqueados.';

  @override
  String get blockListUnblock => 'Desbloquear';

  @override
  String get blockListUnblockTitle => 'Desbloquear usuário';

  @override
  String get blockListUnblockMessage => 'Permitir mensagens deste usuário novamente?';

  @override
  String get blockListUnblockConfirm => 'Desbloquear';

  @override
  String get blockListUnblockFailed => 'Não foi possível desbloquear o usuário.';

  @override
  String get blockUnblockedTitle => 'Concluído';

  @override
  String get blockUnblockedMessage => 'Usuário desbloqueado.';

  @override
  String get onboardingTitle => 'Introdução';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Etapa $current de $total';
  }

  @override
  String get onboardingNotificationTitle => 'Permissão de notificações';

  @override
  String get onboardingNotificationDescription => 'Notificaremos quando as mensagens de revezamento chegarem e os resultados estiverem prontos.';

  @override
  String get onboardingNotificationNote => 'Você pode alterar isso a qualquer momento em Ajustes. Esta etapa é opcional.';

  @override
  String get onboardingAllowNotifications => 'Permitir';

  @override
  String get onboardingPhotoTitle => 'Acesso às fotos';

  @override
  String get onboardingPhotoDescription => 'Usado apenas para definir imagens de perfil e anexar imagens às mensagens.';

  @override
  String get onboardingPhotoNote => 'Acessamos apenas as fotos que você selecionar. Esta etapa é opcional.';

  @override
  String get onboardingAllowPhotos => 'Permitir';

  @override
  String get onboardingGuidelineTitle => 'Diretrizes da comunidade';

  @override
  String get onboardingGuidelineDescription => 'Para um uso seguro, são proibidos o assédio, o discurso de ódio e o compartilhamento de informações pessoais. As violações podem resultar em restrições de conteúdo.';

  @override
  String get onboardingAgreeGuidelines => 'Concordo com as diretrizes da comunidade.';

  @override
  String get onboardingContentPolicyTitle => 'Política de conteúdo';

  @override
  String get onboardingContentPolicyDescription => 'Conteúdo ilegal, prejudicial e violento é proibido. O conteúdo em violação pode ser restringido após análise.';

  @override
  String get onboardingAgreeContentPolicy => 'Concordo com a política de conteúdo.';

  @override
  String get onboardingSafetyTitle => 'Denunciar e bloquear';

  @override
  String get onboardingSafetyDescription => 'Você pode denunciar conteúdo ofensivo ou inadequado, ou bloquear usuários específicos para não receber mais suas mensagens.';

  @override
  String get onboardingConfirmSafety => 'Entendo a política de denúncia e bloqueio.';

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
  String get noticeTitle => 'Avisos';

  @override
  String get noticeDetailTitle => 'Avisos';

  @override
  String get noticeFilterLabel => 'Tipo de aviso';

  @override
  String get noticeFilterAll => 'Todos';

  @override
  String get noticeFilterSheetTitle => 'Selecionar tipo de aviso';

  @override
  String get noticeTypeUnknown => 'Desconhecido';

  @override
  String get noticePinnedBadge => 'Fixado';

  @override
  String get noticeEmptyTitle => 'Sem avisos';

  @override
  String get noticeEmptyDescription => 'Não há avisos desse tipo.';

  @override
  String get noticeErrorTitle => 'Não foi possível carregar os avisos';

  @override
  String get noticeErrorDescription => 'Tente novamente mais tarde.';

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
  String get authProviderKakaoLogin => 'Login com Kakao';

  @override
  String get authProviderGoogleLogin => 'Login com Google';

  @override
  String get authProviderAppleLogin => 'Login com Apple';

  @override
  String get authProviderUnknownLogin => 'Sessão iniciada';

  @override
  String get profileLoginProviderKakao => 'Login com Kakao';

  @override
  String get profileLoginProviderGoogle => 'Login com Google';

  @override
  String get profileLoginProviderApple => 'Login com Apple';

  @override
  String get profileLoginProviderEmail => 'Login com e-mail';

  @override
  String get profileLoginProviderUnknown => 'Sessão iniciada';

  @override
  String get profileAppSettings => 'Configurações do app';

  @override
  String get profileMenuNotices => 'Avisos';

  @override
  String get profileMenuSupport => 'Suporte';

  @override
  String get profileMenuAppInfo => 'Informações do app';

  @override
  String get profileMenuTitle => 'Menu';

  @override
  String get profileMenuSubtitle => 'Acesso rápido às configurações mais usadas.';

  @override
  String get profileWithdrawCta => 'Excluir conta';

  @override
  String get profileWithdrawTitle => 'Excluir conta';

  @override
  String get profileWithdrawMessage => 'Deseja excluir sua conta? Esta ação não pode ser desfeita.';

  @override
  String get profileWithdrawConfirm => 'Excluir';

  @override
  String get profileFeaturePreparingTitle => 'Em breve';

  @override
  String get profileFeaturePreparingBody => 'Este recurso ainda não está disponível.';

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
  String get supportReleaseNotesBody => '• Melhoramos a experiência e a estabilidade do relé.\n• Ajustamos o tema escuro em perfil e suporte.\n• Corrigimos pequenos bugs e desempenho.';

  @override
  String get supportVersionUnknown => 'Desconhecida';

  @override
  String get supportSuggestCta => 'Enviar sugestão';

  @override
  String get supportReportCta => 'Relatar erro';

  @override
  String get supportFaqTitle => 'Perguntas frequentes';

  @override
  String get supportFaqSubtitle => 'Confira as dúvidas mais comuns.';

  @override
  String get supportFaqQ1 => 'As mensagens não parecem ser entregues. Por quê?';

  @override
  String get supportFaqA1 => 'A entrega pode ser atrasada ou restrita devido ao status da rede, atrasos temporários do servidor ou políticas de segurança (denúncias/bloqueios, etc.). Por favor, tente novamente mais tarde.';

  @override
  String get supportFaqQ2 => 'Não estou recebendo notificações. O que devo fazer?';

  @override
  String get supportFaqA2 => 'As permissões de notificação do Echowander podem estar desativadas nas configurações do seu telefone. Vá em Configurações do app → Configurações do app (Configurações de notificação) para ativar as permissões de notificação e também verifique as restrições de economia de bateria/segundo plano.';

  @override
  String get supportFaqQ3 => 'Recebi uma mensagem desagradável. Como bloqueio/denuncio?';

  @override
  String get supportFaqA3 => 'Você pode selecionar Denunciar ou Bloquear na tela da mensagem. Bloquear impede que você receba mais mensagens desse usuário. O conteúdo denunciado pode ser revisado para a segurança da comunidade.';

  @override
  String get supportFaqQ4 => 'Posso editar ou cancelar uma mensagem que enviei?';

  @override
  String get supportFaqA4 => 'Uma vez enviada, as mensagens não podem ser facilmente editadas ou canceladas. Por favor, revise o conteúdo antes de enviar.';

  @override
  String get supportFaqQ5 => 'O que acontece se eu violar as diretrizes da comunidade?';

  @override
  String get supportFaqA5 => 'Violações repetidas podem resultar em restrições de mensagens ou limitações de conta. Por favor, siga as diretrizes para uma comunidade segura.';

  @override
  String get supportActionPreparingTitle => 'Em breve';

  @override
  String get supportActionPreparingBody => 'Esta ação estará disponível em breve.';

  @override
  String get supportSuggestionSubject => 'Pedido de sugestão';

  @override
  String get supportBugSubject => 'Relatório de erro';

  @override
  String supportEmailFooterUser(String userId) {
    return 'Usuário : $userId';
  }

  @override
  String supportEmailFooterVersion(String version) {
    return 'Versão do app : $version';
  }

  @override
  String get supportEmailLaunchFailed => 'Não foi possível abrir o aplicativo de e-mail. Por favor, tente novamente mais tarde.';

  @override
  String get appInfoTitle => 'Informações do app';

  @override
  String get appInfoSettingsTitle => 'Configurações do app';

  @override
  String get appInfoSettingsSubtitle => 'Veja licenças e políticas.';

  @override
  String get appInfoSectionTitle => 'Serviços conectados';

  @override
  String get appInfoSectionSubtitle => 'Confira os apps vinculados ao serviço.';

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
  String get appInfoRelatedApp1Description => 'App de exemplo para testar serviços relacionados.';

  @override
  String get appInfoRelatedApp2Title => 'App de teste 2';

  @override
  String get appInfoRelatedApp2Description => 'Outro app de exemplo para integrações relacionadas.';

  @override
  String get appInfoExternalLinkLabel => 'Abrir link externo';

  @override
  String get appInfoLinkPreparingTitle => 'Em breve';

  @override
  String get appInfoLinkPreparingBody => 'Este link estará disponível em breve.';

  @override
  String get openLicenseTitle => 'Licenças abertas';

  @override
  String get openLicenseHeaderTitle => 'Bibliotecas de código aberto';

  @override
  String get openLicenseHeaderBody => 'Este app usa as seguintes bibliotecas de código aberto.';

  @override
  String get openLicenseSectionTitle => 'Lista de licenças';

  @override
  String get openLicenseSectionSubtitle => 'Confira os pacotes de código aberto em uso.';

  @override
  String openLicenseChipVersion(Object version) {
    return 'Versão: $version';
  }

  @override
  String openLicenseChipLicense(Object license) {
    return 'Licença: $license';
  }

  @override
  String get openLicenseChipDetails => 'Detalhes';

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
  String get openLicenseTypeUnknown => 'Desconhecida';

  @override
  String get openLicenseUnknown => 'Desconhecida';

  @override
  String get openLicenseEmptyMessage => 'Nenhuma informação de licença disponível.';

  @override
  String openLicenseDetailTitle(Object package) {
    return 'Licença de $package';
  }

  @override
  String get journeyDetailAnonymous => 'Anônimo';

  @override
  String get errorNetwork => 'Por favor, verifique sua conexão de rede.';

  @override
  String get errorTimeout => 'Tempo limite excedido. Por favor, tente novamente.';

  @override
  String get errorServerUnavailable => 'O servidor está temporariamente indisponível. Por favor, tente mais tarde.';

  @override
  String get errorUnauthorized => 'Por favor, faça login novamente.';

  @override
  String get errorRetry => 'Tentar novamente';

  @override
  String get errorCancel => 'Cancelar';

  @override
  String get errorAuthRefreshFailed => 'A rede está instável. Por favor, tente novamente em breve.';

  @override
  String get homeInboxSummaryTitle => 'Resumo de hoje';

  @override
  String get homeInboxSummaryPending => 'Pendentes';

  @override
  String get homeInboxSummaryCompleted => 'Respondidas';

  @override
  String get homeInboxSummarySentResponses => 'Respostas recebidas';

  @override
  String homeInboxSummaryUpdatedAt(Object time) {
    return 'Atualizado $time';
  }

  @override
  String get homeInboxSummaryRefresh => 'Atualizar';

  @override
  String get homeInboxSummaryLoadFailed => 'Não conseguimos carregar o resumo.';

  @override
  String homeInboxSummaryItemSemantics(Object label, Object count) {
    return '$label $count';
  }

  @override
  String get homeTimelineTitle => 'Atividade recente';

  @override
  String get homeTimelineEmptyTitle => 'Sem atividade recente';

  @override
  String get homeTimelineReceivedTitle => 'Nova mensagem recebida';

  @override
  String get homeTimelineRespondedTitle => 'Resposta enviada';

  @override
  String get homeTimelineSentResponseTitle => 'Resposta recebida';

  @override
  String homeTimelineSubtitle(Object time) {
    return '$time';
  }

  @override
  String get homeDailyPromptTitle => 'Pergunta do dia';

  @override
  String get homeDailyPromptHint => 'Toque para escrever uma mensagem';

  @override
  String get homeDailyPromptAction => 'Escrever';

  @override
  String get homeAnnouncementTitle => 'Atualização';

  @override
  String get homeAnnouncementSummary => 'Veja as novidades do Echowander.';

  @override
  String get homeAnnouncementAction => 'Detalhes';

  @override
  String get homeAnnouncementDetailTitle => 'Atualização';

  @override
  String get homeAnnouncementDetailBody => 'Fizemos melhorias para uma experiência mais fluida.';

  @override
  String get homePromptQ1 => 'O que te fez sorrir hoje?';

  @override
  String get homePromptQ2 => 'O que você espera para esta semana?';

  @override
  String get homePromptQ3 => 'Qual lugar você quer revisitar?';

  @override
  String get homePromptQ4 => 'Compartilhe uma pequena vitória de hoje.';

  @override
  String get homePromptQ5 => 'Que hábito você gostaria de criar?';

  @override
  String get homePromptQ6 => 'Para quem você quer agradecer hoje?';

  @override
  String get homePromptQ7 => 'Qual música você não para de ouvir?';

  @override
  String get homePromptQ8 => 'Descreva seu dia em três palavras.';

  @override
  String get homePromptQ9 => 'O que você aprendeu recentemente?';

  @override
  String get homePromptQ10 => 'Se pudesse enviar uma mensagem para si mesmo, o que diria?';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileEditNicknameLabel => 'Apelido';

  @override
  String get profileEditNicknameHint => 'Digite o apelido';

  @override
  String get profileEditNicknameEmpty => 'Por favor, digite um apelido';

  @override
  String profileEditNicknameTooShort(Object min) {
    return 'O apelido deve ter pelo menos $min caracteres';
  }

  @override
  String profileEditNicknameTooLong(Object max) {
    return 'O apelido pode ter até $max caracteres';
  }

  @override
  String get profileEditNicknameConsecutiveSpaces => 'Espaços consecutivos não são permitidos';

  @override
  String get profileEditNicknameInvalidCharacters => 'Apenas coreano, inglês, números e sublinhado (_) são permitidos';

  @override
  String get profileEditNicknameUnderscoreAtEnds => 'Underscore (_) cannot be used at the beginning or end';

  @override
  String get profileEditNicknameConsecutiveUnderscores => 'Consecutive underscores (__) are not allowed';

  @override
  String get profileEditNicknameForbidden => 'This nickname is not allowed';

  @override
  String get profileEditNicknameChecking => 'Verificando...';

  @override
  String get profileEditNicknameAvailable => 'Este apelido está disponível';

  @override
  String get profileEditNicknameTaken => 'Este apelido já está em uso';

  @override
  String get profileEditNicknameError => 'Ocorreu um erro ao verificar';

  @override
  String get profileEditAvatarLabel => 'Foto do perfil';

  @override
  String get profileEditAvatarChange => 'Alterar foto';

  @override
  String get profileEditSave => 'Salvar';

  @override
  String get profileEditCancel => 'Cancelar';

  @override
  String get profileEditSaveSuccess => 'Perfil salvo com sucesso';

  @override
  String get profileEditSaveFailed => 'Falha ao salvar. Por favor, tente novamente';

  @override
  String get profileEditImageTooLarge => 'Image file is too large. Please select another image';

  @override
  String get profileEditImageOptimizationFailed => 'An error occurred while processing the image. Please try again';

  @override
  String get profileEditCropTitle => 'Editar foto';

  @override
  String get profileEditCropDescription => 'Ajuste a posição como desejar';

  @override
  String get profileEditCropCancel => 'Cancelar';

  @override
  String get profileEditCropComplete => 'Concluir';

  @override
  String get profileEditCropFailedTitle => 'Falha ao editar foto';

  @override
  String get profileEditCropFailedMessage => 'Ocorreu um erro ao editar a foto. Por favor, tente novamente.';

  @override
  String get profileEditCropFailedAction => 'OK';
}
