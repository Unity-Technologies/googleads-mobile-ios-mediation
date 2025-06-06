// Copyright 2024 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import GoogleMobileAds
import MolocoSDK

/// Loads banner ads on Moloco ads SDK.
final class BannerAdLoader: NSObject {

  /// The banner ad configuration.
  private let adConfiguration: MediationBannerAdConfiguration

  /// The ad event delegate which is used to report banner related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationBannerAdEventDelegate?

  /// The completion handler to call when the rewarded ad loading succeeds or fails.
  private let loadCompletionHandler: GADMediationBannerLoadCompletionHandler

  /// The factory class used to create banner ads.
  private let molocoBannerFactory: MolocoBannerFactory

  /// The MolocoBannerAdView. MolocoBannerAdView type on iOS 13+, otherwise nil.
  private var bannerAdView: (UIView & MolocoAd)?

  init(
    adConfiguration: MediationBannerAdConfiguration,
    molocoBannerFactory: MolocoBannerFactory,
    loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.loadCompletionHandler = loadCompletionHandler
    self.molocoBannerFactory = molocoBannerFactory
    super.init()
  }

  func loadAd() {
    guard #available(iOS 13.0, *) else {
      let error = MolocoUtils.error(
        code: .adServingNotSupported,
        description: "Moloco SDK does not support serving ads on iOS 12 and below")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let molocoAdUnitID = MolocoUtils.getAdUnitId(from: adConfiguration)
    guard let molocoAdUnitID else {
      let error = MolocoUtils.error(
        code: .invalidAdUnitId, description: "Missing required parameter")
      _ = loadCompletionHandler(nil, error)
      return
    }

    guard let bidResponse = adConfiguration.bidResponse else {
      let error = MolocoUtils.error(code: .nilBidResponse, description: "Nil bid response.")
      _ = loadCompletionHandler(nil, error)
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      if isAdSizeEqualToSize(size1: adConfiguration.adSize, size2: AdSizeMediumRectangle) {
        self.bannerAdView = self.molocoBannerFactory.createMREC(
          for: molocoAdUnitID, delegate: self, watermarkData: adConfiguration.watermark)
      } else {
        self.bannerAdView = self.molocoBannerFactory.createBanner(
          for: molocoAdUnitID, delegate: self, watermarkData: adConfiguration.watermark)
      }
      self.bannerAdView?.load(bidResponse: bidResponse)
    }
  }

}

// MARK: - MediationBannerAd

extension BannerAdLoader: MediationBannerAd {

  var view: UIView {
    guard #available(iOS 13.0, *) else {
      MolocoUtils.log(
        "The Moloco banner ad are only supported on iOS 13+. Returning a default UIView.")
      return UIView()
    }
    guard let bannerAdView else {
      MolocoUtils.log("The Moloco banner ad has not been loaded yet. Returning a default UIView.")
      return UIView()
    }
    return bannerAdView
  }

}

// MARK: - MolocoBannerDelegate

extension BannerAdLoader: MolocoBannerDelegate {

  func didLoad(ad: MolocoAd) {
    eventDelegate = loadCompletionHandler(self, nil)
  }

  func failToLoad(ad: MolocoAd, with error: Error?) {
    _ = loadCompletionHandler(nil, error)
  }

  func didShow(ad: MolocoAd) {
    eventDelegate?.reportImpression()
  }

  func failToShow(ad: MolocoAd, with error: Error?) {
    let showError =
      error
      ?? MolocoUtils.error(
        code: .adFailedToShow, description: "Ad failed to show")
    eventDelegate?.didFailToPresentWithError(showError)
  }

  func didHide(ad: MolocoAd) {
    MolocoUtils.log("The Moloco banner ad did hide.")
  }

  func didClick(on ad: MolocoAd) {
    eventDelegate?.reportClick()
  }

}
