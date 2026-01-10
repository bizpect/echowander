import Flutter
import GoogleMobileAds
import google_mobile_ads
import UIKit

// 종료 확인 바텀시트 네이티브 광고 팩토리
class ExitConfirmNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: GADNativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> GADNativeAdView {
    let adView = GADNativeAdView(frame: .zero)
    adView.backgroundColor = .clear

    let adChoicesView = GADAdChoicesView()
    adChoicesView.translatesAutoresizingMaskIntoConstraints = false

    let iconView = UIImageView()
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.contentMode = .scaleAspectFit
    NSLayoutConstraint.activate([
      iconView.widthAnchor.constraint(equalToConstant: 32),
      iconView.heightAnchor.constraint(equalToConstant: 32),
    ])

    let headlineLabel = UILabel()
    headlineLabel.translatesAutoresizingMaskIntoConstraints = false
    headlineLabel.textColor = .label
    headlineLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    headlineLabel.numberOfLines = 2

    let bodyLabel = UILabel()
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
    bodyLabel.textColor = .secondaryLabel
    bodyLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    bodyLabel.numberOfLines = 2

    let textStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel])
    textStack.translatesAutoresizingMaskIntoConstraints = false
    textStack.axis = .vertical
    textStack.spacing = 6

    let headerStack = UIStackView(arrangedSubviews: [iconView, textStack])
    headerStack.translatesAutoresizingMaskIntoConstraints = false
    headerStack.axis = .horizontal
    headerStack.spacing = 8
    headerStack.alignment = .center

    let mediaView = GADMediaView()
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      mediaView.heightAnchor.constraint(equalToConstant: 96),
    ])

    let ctaButton = UIButton(type: .system)
    ctaButton.translatesAutoresizingMaskIntoConstraints = false

    let contentStack = UIStackView(arrangedSubviews: [headerStack, mediaView, ctaButton])
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 8

    adView.addSubview(adChoicesView)
    adView.addSubview(contentStack)

    NSLayoutConstraint.activate([
      adChoicesView.topAnchor.constraint(equalTo: adView.topAnchor),
      adChoicesView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      contentStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      contentStack.topAnchor.constraint(equalTo: adChoicesView.bottomAnchor, constant: 4),
      contentStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
    ])

    adView.adChoicesView = adChoicesView
    adView.headlineView = headlineLabel
    adView.bodyView = bodyLabel

    headlineLabel.text = nativeAd.headline
    if let body = nativeAd.body {
      bodyLabel.text = body
      bodyLabel.isHidden = false
    } else {
      bodyLabel.isHidden = true
    }

    if let icon = nativeAd.icon?.image {
      iconView.image = icon
      iconView.isHidden = false
      adView.iconView = iconView
    } else {
      iconView.isHidden = true
      adView.iconView = nil
    }

    if let mediaContent = nativeAd.mediaContent {
      mediaView.mediaContent = mediaContent
      mediaView.isHidden = false
      adView.mediaView = mediaView
    } else {
      mediaView.isHidden = true
      adView.mediaView = nil
    }

    if let callToAction = nativeAd.callToAction {
      ctaButton.setTitle(callToAction, for: .normal)
      ctaButton.isHidden = false
      adView.callToActionView = ctaButton
    } else {
      ctaButton.isHidden = true
      adView.callToActionView = nil
    }

    adView.nativeAd = nativeAd
    return adView
  }
}
