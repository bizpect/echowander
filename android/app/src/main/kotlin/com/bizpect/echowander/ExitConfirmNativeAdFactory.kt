package com.bizpect.echowander

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

// 네이티브 광고 레이아웃 팩토리 (종료 확인 바텀시트 전용)
class ExitConfirmNativeAdFactory(
    private val inflater: LayoutInflater,
) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = inflater.inflate(
            R.layout.native_ad_exit_confirm,
            null,
        ) as NativeAdView

        val adChoicesView = adView.findViewById<AdChoicesView>(R.id.ad_choices)
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)

        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView
        adView.adChoicesView = adChoicesView

        if (nativeAd.body == null) {
            bodyView.visibility = View.GONE
        } else {
            bodyView.visibility = View.VISIBLE
            bodyView.text = nativeAd.body
        }
        adView.bodyView = bodyView

        if (nativeAd.icon == null) {
            iconView.visibility = View.GONE
            adView.iconView = null
        } else {
            iconView.setImageDrawable(nativeAd.icon?.drawable)
            iconView.visibility = View.VISIBLE
            adView.iconView = iconView
        }

        if (nativeAd.mediaContent == null) {
            mediaView.visibility = View.GONE
            adView.mediaView = null
        } else {
            mediaView.visibility = View.VISIBLE
            mediaView.setMediaContent(nativeAd.mediaContent)
            adView.mediaView = mediaView
        }

        if (nativeAd.callToAction == null) {
            ctaView.visibility = View.GONE
            adView.callToActionView = null
        } else {
            ctaView.text = nativeAd.callToAction
            ctaView.visibility = View.VISIBLE
            adView.callToActionView = ctaView
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
