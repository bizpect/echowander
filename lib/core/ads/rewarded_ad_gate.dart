import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import 'ad_reward_constants.dart';
import 'ad_reward_logger.dart';
import 'reward_unlock_repository.dart';

enum RewardedAdGateResult {
  earned,
  dismissed,
  failedToLoad,
  failedToShow,
  skippedByConfig,
}

final rewardedAdGateProvider = Provider<RewardedAdGate>((ref) {
  final config = AppConfigStore.current;
  return RewardedAdGate(
    config: config,
    logger: AdRewardLogger(config: config),
    unlockRepository: RewardUnlockRepository(config: config),
  );
});

class RewardedAdGate {
  RewardedAdGate({
    required AppConfig config,
    required AdRewardLogger logger,
    required RewardUnlockRepository unlockRepository,
  })  : _config = config,
        _logger = logger,
        _unlockRepository = unlockRepository;

  final AppConfig _config;
  final AdRewardLogger _logger;
  final RewardUnlockRepository _unlockRepository;

  Future<RewardedAdGateResult> showRewardedAndReturnResult({
    required String placementCode,
    required String contentId,
    required String accessToken,
    required String reqId,
  }) async {
    final envCode = _resolveEnvCode(_config.environment);
    final unitId = _resolveAdUnitId(_config);

    if (unitId.isEmpty) {
      await _safeLog(
        journeyId: contentId,
        placementCode: placementCode,
        envCode: envCode,
        adUnitId: unitId,
        eventCode: AdRewardEventCodes.failConfig,
        accessToken: accessToken,
        reqId: reqId,
        metadata: {
          'reason': 'missing_ad_unit_id',
        },
      );
      // PROD에서 광고 ID가 비어 있으면 광고 없이 진입 허용 (잠금해제는 하지 않음)
      return RewardedAdGateResult.skippedByConfig;
    }

    await _safeLog(
      journeyId: contentId,
      placementCode: placementCode,
      envCode: envCode,
      adUnitId: unitId,
      eventCode: AdRewardEventCodes.request,
      accessToken: accessToken,
      reqId: reqId,
    );

    final ad = await _loadAd(
      unitId: unitId,
      journeyId: contentId,
      placementCode: placementCode,
      envCode: envCode,
      accessToken: accessToken,
      reqId: reqId,
    );

    if (ad == null) {
      return RewardedAdGateResult.failedToLoad;
    }

    return _showAd(
      ad: ad,
      journeyId: contentId,
      placementCode: placementCode,
      envCode: envCode,
      accessToken: accessToken,
      reqId: reqId,
    );
  }

  Future<RewardedAd?> _loadAd({
    required String unitId,
    required String journeyId,
    required String placementCode,
    required String envCode,
    required String accessToken,
    required String reqId,
  }) async {
    final completer = Completer<RewardedAd?>();

    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint('[RewardedAdGate] load failed: ${error.code} ${error.message}');
          }
          _safeLog(
            journeyId: journeyId,
            placementCode: placementCode,
            envCode: envCode,
            adUnitId: unitId,
            eventCode: AdRewardEventCodes.failLoad,
            accessToken: accessToken,
            reqId: reqId,
            metadata: {
              'code': error.code,
              'message': error.message,
            },
          );
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );

    return completer.future;
  }

  Future<RewardedAdGateResult> _showAd({
    required RewardedAd ad,
    required String journeyId,
    required String placementCode,
    required String envCode,
    required String accessToken,
    required String reqId,
  }) async {
    final completer = Completer<RewardedAdGateResult>();
    var earned = false;
    Future<bool>? unlockFuture;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _safeLog(
          journeyId: journeyId,
          placementCode: placementCode,
          envCode: envCode,
          adUnitId: ad.adUnitId,
          eventCode: AdRewardEventCodes.show,
          accessToken: accessToken,
          reqId: reqId,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!earned) {
          _safeLog(
            journeyId: journeyId,
            placementCode: placementCode,
            envCode: envCode,
            adUnitId: ad.adUnitId,
            eventCode: AdRewardEventCodes.dismiss,
            accessToken: accessToken,
            reqId: reqId,
          );
          if (!completer.isCompleted) {
            completer.complete(RewardedAdGateResult.dismissed);
          }
          return;
        }
        final unlockTask = unlockFuture ?? Future.value(false);
        unlockTask.then((success) {
          if (!completer.isCompleted) {
            completer.complete(
              success ? RewardedAdGateResult.earned : RewardedAdGateResult.failedToShow,
            );
          }
        });
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          debugPrint('[RewardedAdGate] show failed: ${error.code} ${error.message}');
        }
        ad.dispose();
        _safeLog(
          journeyId: journeyId,
          placementCode: placementCode,
          envCode: envCode,
          adUnitId: ad.adUnitId,
          eventCode: AdRewardEventCodes.failShow,
          accessToken: accessToken,
          reqId: reqId,
          metadata: {
            'code': error.code,
            'message': error.message,
          },
        );
        if (!completer.isCompleted) {
          completer.complete(RewardedAdGateResult.failedToShow);
        }
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        unlockFuture = _unlockRepository
            .upsertRewardUnlock(
              journeyId: journeyId,
              accessToken: accessToken,
            )
            .then((success) {
              _safeLog(
                journeyId: journeyId,
                placementCode: placementCode,
                envCode: envCode,
                adUnitId: ad.adUnitId,
                eventCode: AdRewardEventCodes.earn,
                accessToken: accessToken,
                reqId: reqId,
                metadata: {
                  'type': reward.type,
                  'amount': reward.amount,
                  'unlock_success': success,
                },
              );
              return success;
            })
            .catchError((_) {
              _safeLog(
                journeyId: journeyId,
                placementCode: placementCode,
                envCode: envCode,
                adUnitId: ad.adUnitId,
                eventCode: AdRewardEventCodes.earn,
                accessToken: accessToken,
                reqId: reqId,
                metadata: {
                  'type': reward.type,
                  'amount': reward.amount,
                  'unlock_success': false,
                },
              );
              return false;
            });
      },
    );

    return completer.future;
  }

  String _resolveEnvCode(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.prod:
        return AdEnvCodes.prod;
      case AppEnvironment.stg:
        return AdEnvCodes.stg;
      case AppEnvironment.dev:
        return AdEnvCodes.dev;
    }
  }

  String _resolveAdUnitId(AppConfig config) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return '';
    }

    if (config.environment == AppEnvironment.prod) {
      if (Platform.isAndroid) {
        return config.admobRewardedUnitIdAndroidProd;
      }
      return config.admobRewardedUnitIdIosProd;
    }

    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    return 'ca-app-pub-3940256099942544/1712485313';
  }

  Future<void> _safeLog({
    required String? journeyId,
    required String placementCode,
    required String envCode,
    required String adUnitId,
    required String eventCode,
    required String accessToken,
    required String reqId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _logger.logEvent(
        journeyId: journeyId,
        placementCode: placementCode,
        envCode: envCode,
        adUnitId: adUnitId,
        eventCode: eventCode,
        accessToken: accessToken,
        reqId: reqId,
        metadata: metadata,
      );
    } catch (_) {
      // 광고 로그 실패는 UX에 영향이 없도록 무시
    }
  }
}
