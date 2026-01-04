import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'social_auth_service.dart';

final socialAuthServiceProvider = Provider<SocialAuthService>(
  (ref) => SocialAuthService(config: AppConfigStore.current),
);
