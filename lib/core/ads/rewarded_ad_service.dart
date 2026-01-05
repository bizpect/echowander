import 'dart:io';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      final loaded = await _loadAd();
      if (!loaded) {
        return false;
      }
    }
    final ad = _rewardedAd;
    if (ad == null) {
      return false;
    }
    _rewardedAd = null;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          debugPrint('rewarded: show failed ${error.message}');
        }
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );
    return completer.future;
  }

  Future<bool> _loadAd() async {
    if (_isLoading) {
      return false;
    }
    _isLoading = true;
    final unitId = _resolveAdUnitId();
    if (unitId.isEmpty) {
      _isLoading = false;
      return false;
    }
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint('rewarded: load failed ${error.message}');
          }
          _rewardedAd = null;
          _isLoading = false;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );
    return completer.future;
  }

  String _resolveAdUnitId() {
    final config = AppConfigStore.current;
    if (Platform.isAndroid) {
      if (config.admobRewardedUnitIdAndroid.isNotEmpty) {
        return config.admobRewardedUnitIdAndroid;
      }
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    if (Platform.isIOS) {
      if (config.admobRewardedUnitIdIos.isNotEmpty) {
        return config.admobRewardedUnitIdIos;
      }
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }
}
