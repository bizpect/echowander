import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'common_code.dart';
import 'supabase_common_code_repository.dart';

abstract class CommonCodeRepository {
  Future<List<CommonCode>> listCommonCodes({
    required String codeType,
    required String accessToken,
  });
}

final commonCodeRepositoryProvider = Provider<CommonCodeRepository>((ref) {
  return SupabaseCommonCodeRepository(config: AppConfigStore.current);
});
