import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/ads/ad_config.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_skeleton.dart';
import '../../../../l10n/app_localizations.dart';

/// 홈 탭 종료 확인 바텀시트
class ExitConfirmBottomSheet extends StatefulWidget {
  const ExitConfirmBottomSheet({
    super.key,
    required this.onCancel,
    required this.onExit,
  });

  final VoidCallback onCancel;
  final VoidCallback onExit;

  @override
  State<ExitConfirmBottomSheet> createState() => _ExitConfirmBottomSheetState();
}

class _ExitConfirmBottomSheetState extends State<ExitConfirmBottomSheet> {
  NativeAd? _nativeAd;
  bool _adLoaded = false;
  bool _adFailed = false;
  bool _adLoading = false;
  late final String _requestId;

  @override
  void initState() {
    super.initState();
    _requestId = DateTime.now().microsecondsSinceEpoch.toString();
    _loadAd();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('[ExitAd] dispose reqId=$_requestId');
    }
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    if (_adLoading || _adLoaded) {
      return;
    }
    final config = AppConfigStore.current;
    final unitId = AdConfig.exitConfirmNativeUnitId(config);
    if (unitId.isEmpty) {
      setState(() {
        _adFailed = true;
      });
      return;
    }

    _adLoading = true;
    if (kDebugMode) {
      debugPrint(
        '[ExitAd] load start reqId=$_requestId factory=exit_confirm unitId=$unitId',
      );
    }
    _nativeAd = NativeAd(
      adUnitId: unitId,
      factoryId: 'exit_confirm',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _adLoaded = true;
            _adLoading = false;
          });
          if (kDebugMode) {
            debugPrint('[ExitAd] loaded reqId=$_requestId');
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) {
            return;
          }
          setState(() {
            _adFailed = true;
            _adLoading = false;
          });
          if (kDebugMode) {
            debugPrint(
              '[ExitAd] failed reqId=$_requestId code=${error.code} msg=${error.message}',
            );
          }
        },
      ),
      request: const AdRequest(),
    );
    _nativeAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sheetHeight = MediaQuery.of(context).size.height * 0.50;
    const adAspectRatio = 5 / 6;
    final maxWidth = MediaQuery.of(context).size.width - (AppSpacing.lg * 2);
    final maxHeight = sheetHeight * 0.5;
    final widthByHeight = maxHeight / adAspectRatio;
    final adWidth = widthByHeight < maxWidth ? widthByHeight : maxWidth;
    final adHeight = adWidth * adAspectRatio * 1.2;
    if (kDebugMode) {
      debugPrint(
        '[ExitAd] build reqId=$_requestId ready=$_adLoaded width=$adWidth height=$adHeight',
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _buildAdArea(l10n, adWidth, adHeight),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      onPressed: widget.onCancel,
                      child: Text(l10n.homeExitCancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppFilledButton(
                      onPressed: widget.onExit,
                      child: Text(l10n.homeExitConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdArea(AppLocalizations l10n, double adWidth, double adHeight) {
    final radius = BorderRadius.circular(AppRadius.radiusLarge);
    if (_adLoaded && _nativeAd != null) {
      return Center(
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: adHeight,
            width: adWidth,
            child: AdWidget(ad: _nativeAd!),
          ),
        ),
      );
    }

    if (_adFailed) {
      return SizedBox(
        height: adHeight,
        width: adWidth,
        child: Center(
          child: Text(
            l10n.homeExitAdLoading,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Center(
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: adHeight,
          width: adWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppSkeleton(height: 120),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeExitAdLoading,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
