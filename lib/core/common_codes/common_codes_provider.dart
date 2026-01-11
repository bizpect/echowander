import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_manager.dart';
import 'common_code.dart';
import 'common_code_repository.dart';

final commonCodesProvider = FutureProvider.autoDispose
    .family<List<CommonCode>, String>((ref, codeType) async {
  final sessionState = ref.watch(sessionManagerProvider);
  final accessToken = sessionState.accessToken;
  if (accessToken == null || accessToken.isEmpty) {
    return [];
  }

  final repository = ref.read(commonCodeRepositoryProvider);
  return repository.listCommonCodes(
    codeType: codeType,
    accessToken: accessToken,
  );
});
