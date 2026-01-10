import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import 'ad_reward_constants.dart';
import 'ad_reward_logger.dart';
import 'reward_unlock_repository.dart';

enum RewardGateResult { earned, dismissed, failLoad, failShow, failConfig }

enum RewardGateState {
  idle,
  loading,
  ready,
  showing,
  completedEarned,
  completedDismissed,
  completedFailed,
}

enum AdLoadContext { preload, userAttempt }

class RewardGateOutcome {
  const RewardGateOutcome({
    required this.result,
    required this.context,
    this.unlockFailed = false,
    this.allowNavigationWithoutAd = false,
    this.suppressAlert = false,
  });

  final RewardGateResult result;
  final AdLoadContext context;
  final bool unlockFailed;
  final bool allowNavigationWithoutAd;
  final bool suppressAlert;

  bool get shouldAlert {
    if (suppressAlert) {
      return false;
    }
    if (context != AdLoadContext.userAttempt) {
      return false;
    }
    if (allowNavigationWithoutAd || unlockFailed) {
      return false;
    }
    return result == RewardGateResult.failLoad ||
        result == RewardGateResult.failShow ||
        result == RewardGateResult.failConfig;
  }
}

class _RewardGateSessionResult {
  const _RewardGateSessionResult({
    required this.result,
    required this.unlockFailed,
  });

  final RewardGateResult result;
  final bool unlockFailed;
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
  }) : _config = config,
       _logger = logger,
       _unlockRepository = unlockRepository;

  final AppConfig _config;
  final AdRewardLogger _logger;
  final RewardUnlockRepository _unlockRepository;
  bool _inFlight = false;
  RewardGateState _state = RewardGateState.idle;
  RewardedAd? _preloadedAd;
  int _sessionCounter = 0;
  int _preloadCounter = 0;

  Future<void> preloadRewarded({
    required String placementCode,
    required String contentId,
    required String accessToken,
    required String reqId,
  }) async {
    if (_inFlight ||
        _state == RewardGateState.loading ||
        _state == RewardGateState.showing) {
      return;
    }
    if (_preloadedAd != null && _state == RewardGateState.ready) {
      return;
    }
    _state = RewardGateState.loading;
    _preloadCounter += 1;
    final preloadToken = _preloadCounter;
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
        metadata: {'context': 'preload', 'reason': 'missing_ad_unit_id'},
      );
      if (_state == RewardGateState.loading &&
          !_inFlight &&
          _preloadCounter == preloadToken) {
        _state = RewardGateState.idle;
      }
      return;
    }
    final ad = await _loadAd(
      unitId: unitId,
      journeyId: contentId,
      placementCode: placementCode,
      envCode: envCode,
      accessToken: accessToken,
      reqId: reqId,
      context: AdLoadContext.preload,
    );
    if (ad == null) {
      if (_state == RewardGateState.loading &&
          !_inFlight &&
          _preloadCounter == preloadToken) {
        _state = RewardGateState.idle;
      }
      return;
    }
    if (_inFlight ||
        _state != RewardGateState.loading ||
        _preloadCounter != preloadToken) {
      ad.dispose();
      return;
    }
    _preloadedAd = ad;
    _state = RewardGateState.ready;
  }

  Future<RewardGateOutcome> showRewardedAndReturnResult({
    required String placementCode,
    required String contentId,
    required String accessToken,
    required String reqId,
  }) async {
    if (_inFlight) {
      return const RewardGateOutcome(
        result: RewardGateResult.failShow,
        context: AdLoadContext.userAttempt,
        suppressAlert: true,
      );
    }
    _inFlight = true;
    final envCode = _resolveEnvCode(_config.environment);
    final unitId = _resolveAdUnitId(_config);
    if (kDebugMode) {
      debugPrint(
        '[AdGate] START reqId=$reqId ctx=userAttempt env=$envCode unitId=$unitId',
      );
    }

    try {
      if (unitId.isEmpty) {
        await _safeLog(
          journeyId: contentId,
          placementCode: placementCode,
          envCode: envCode,
          adUnitId: unitId,
          eventCode: AdRewardEventCodes.failConfig,
          accessToken: accessToken,
          reqId: reqId,
          metadata: {'context': 'user_attempt', 'reason': 'missing_ad_unit_id'},
        );
        return const RewardGateOutcome(
          result: RewardGateResult.failConfig,
          context: AdLoadContext.userAttempt,
          allowNavigationWithoutAd: true,
        );
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

      RewardedAd? ad;
      if (_preloadedAd != null && _state == RewardGateState.ready) {
        ad = _preloadedAd;
        _preloadedAd = null;
        _state = RewardGateState.showing;
      } else {
        _state = RewardGateState.loading;
        ad = await _loadAd(
          unitId: unitId,
          journeyId: contentId,
          placementCode: placementCode,
          envCode: envCode,
          accessToken: accessToken,
          reqId: reqId,
          context: AdLoadContext.userAttempt,
        );
      }

      if (ad == null) {
        _state = RewardGateState.idle;
        return const RewardGateOutcome(
          result: RewardGateResult.failLoad,
          context: AdLoadContext.userAttempt,
        );
      }

      _state = RewardGateState.showing;
      _sessionCounter += 1;
      final sessionId = _sessionCounter;
      final sessionResult = await _showAd(
        ad: ad,
        journeyId: contentId,
        placementCode: placementCode,
        envCode: envCode,
        accessToken: accessToken,
        reqId: reqId,
        sessionId: sessionId,
      );
      return RewardGateOutcome(
        result: sessionResult.result,
        context: AdLoadContext.userAttempt,
        unlockFailed: sessionResult.unlockFailed,
      );
    } finally {
      _inFlight = false;
      _state = RewardGateState.idle;
    }
  }

  Future<RewardedAd?> _loadAd({
    required String unitId,
    required String journeyId,
    required String placementCode,
    required String envCode,
    required String accessToken,
    required String reqId,
    required AdLoadContext context,
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
            debugPrint(
              '[AdGate] FAIL reqId=$reqId stage=load ctx=${context == AdLoadContext.preload ? 'preload' : 'userAttempt'} '
              'code=${error.code} message=${error.message}',
            );
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
              'context': context == AdLoadContext.preload
                  ? 'preload'
                  : 'user_attempt',
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

  Future<_RewardGateSessionResult> _showAd({
    required RewardedAd ad,
    required String journeyId,
    required String placementCode,
    required String envCode,
    required String accessToken,
    required String reqId,
    required int sessionId,
  }) async {
    final completer = Completer<_RewardGateSessionResult>();
    var state = RewardGateState.showing;
    var earnedLatch = false;
    var unlockFailed = false;
    Future<bool>? unlockFuture;

    bool isCompleted(RewardGateState current) {
      return current == RewardGateState.completedEarned ||
          current == RewardGateState.completedDismissed ||
          current == RewardGateState.completedFailed;
    }

    void completeOnce(RewardGateResult result, RewardGateState nextState) {
      if (isCompleted(state)) {
        return;
      }
      state = nextState;
      _state = nextState;
      if (!completer.isCompleted) {
        completer.complete(
          _RewardGateSessionResult(result: result, unlockFailed: unlockFailed),
        );
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        if (_sessionCounter != sessionId) {
          return;
        }
        if (kDebugMode) {
          debugPrint('[AdGate] SHOW reqId=$reqId');
        }
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
      onAdDismissedFullScreenContent: (ad) async {
        if (_sessionCounter != sessionId) {
          ad.dispose();
          return;
        }
        ad.dispose();
        if (isCompleted(state)) {
          return;
        }
        if (!earnedLatch) {
          _safeLog(
            journeyId: journeyId,
            placementCode: placementCode,
            envCode: envCode,
            adUnitId: ad.adUnitId,
            eventCode: AdRewardEventCodes.dismiss,
            accessToken: accessToken,
            reqId: reqId,
          );
          completeOnce(
            RewardGateResult.dismissed,
            RewardGateState.completedDismissed,
          );
          return;
        }
        if (kDebugMode) {
          debugPrint('[AdGate] DISMISS reqId=$reqId latch=true');
        }
        final unlockTask = unlockFuture ?? Future.value(false);
        final unlockSuccess = await unlockTask;
        if (unlockSuccess) {
          completeOnce(
            RewardGateResult.earned,
            RewardGateState.completedEarned,
          );
        } else {
          unlockFailed = true;
          completeOnce(
            RewardGateResult.earned,
            RewardGateState.completedFailed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (_sessionCounter != sessionId) {
          ad.dispose();
          return;
        }
        if (isCompleted(state) || earnedLatch) {
          ad.dispose();
          return;
        }
        if (kDebugMode) {
          debugPrint(
            '[AdGate] FAIL reqId=$reqId stage=show ctx=userAttempt code=${error.code} message=${error.message}',
          );
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
          metadata: {'code': error.code, 'message': error.message},
        );
        completeOnce(
          RewardGateResult.failShow,
          RewardGateState.completedFailed,
        );
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        if (_sessionCounter != sessionId) {
          return;
        }
        if (isCompleted(state)) {
          return;
        }
        earnedLatch = true;
        if (kDebugMode) {
          debugPrint('[AdGate] EARN reqId=$reqId latch=true');
        }
        unlockFuture = _unlockRepository
            .upsertRewardUnlock(
              journeyId: journeyId,
              accessToken: accessToken,
              reqId: reqId,
            )
            .then((success) {
              if (kDebugMode) {
                debugPrint(
                  '[Unlock] upsert reqId=$reqId journeyId=$journeyId -> ${success ? 'OK' : 'FAIL'}',
                );
              }
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
