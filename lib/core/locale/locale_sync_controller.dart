import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../session/session_manager.dart';
import 'locale_sync_repository.dart';

class LocaleSyncState {
  const LocaleSyncState({
    required this.lastSyncedTag,
    required this.isSyncing,
  });

  final String? lastSyncedTag;
  final bool isSyncing;

  LocaleSyncState copyWith({
    String? lastSyncedTag,
    bool? isSyncing,
  }) {
    return LocaleSyncState(
      lastSyncedTag: lastSyncedTag ?? this.lastSyncedTag,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

final localeSyncControllerProvider =
    NotifierProvider<LocaleSyncController, LocaleSyncState>(
  LocaleSyncController.new,
);

class LocaleSyncController extends Notifier<LocaleSyncState> {
  /// build 재호출 시 LateInitializationError 방지를 위해 getter로 접근
  LocaleSyncRepository get _repository =>
      LocaleSyncRepository(config: AppConfigStore.current);

  @override
  LocaleSyncState build() {
    return const LocaleSyncState(lastSyncedTag: null, isSyncing: false);
  }

  Future<void> sync(Locale? locale) async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    final tag = _resolveLocaleTag(locale);
    if (tag.isEmpty || tag == state.lastSyncedTag) {
      return;
    }
    state = state.copyWith(isSyncing: true);
    await _repository.updateLocale(
      localeTag: tag,
      accessToken: accessToken,
    );
    state = state.copyWith(lastSyncedTag: tag, isSyncing: false);
  }

  String _resolveLocaleTag(Locale? locale) {
    final resolved = locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    if (resolved.languageCode.isEmpty) {
      return '';
    }
    if (resolved.countryCode != null && resolved.countryCode!.isNotEmpty) {
      return '${resolved.languageCode}-${resolved.countryCode}';
    }
    return resolved.languageCode;
  }
}
