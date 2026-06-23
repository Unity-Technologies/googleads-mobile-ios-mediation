// Copyright 2025 Google LLC.
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
import UnityAds

final class BannerAdLoader: NSObject {

  private let adConfiguration: MediationBannerAdConfiguration

  weak var eventDelegate: MediationBannerAdEventDelegate?

  private var adLoadCompletionHandler: GADMediationBannerLoadCompletionHandler?

  private let client: UnityAdsClient

  private var bannerAd: UADSBannerAd?

  init(adConfiguration: MediationBannerAdConfiguration,
       loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.client = UnityAdsClientFactory.createClient()
  }

  func loadAd() {
    guard let placementId = adConfiguration.credentials.settings["zoneId"] as? String else {
      handleLoadedAd(
        nil,
        error: UnityAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing placement ID."
        ))
      return
    }
    
    var configBuilder = UADSBannerLoadConfigurationBuilder(placementId: placementId, bannerSize: adConfiguration.adSize.size, delegate: self)
    if let adMarkup = adConfiguration.bidResponse {
      configBuilder = configBuilder.with(adMarkup: adMarkup)
    }
    if let watermark  = adConfiguration.watermark?.base64EncodedString() {
      configBuilder = configBuilder.with(extras: [UnityAdapter.watermarkKey: watermark])
    }
    let config = configBuilder.with(mediationInfo: UnityAdapter.mediationInfo).build()

    client.loadBannerAd(configuration: config) { [weak self] banner, error in
      guard let self else { return }
      self.bannerAd = banner
      self.handleLoadedAd(error == nil ? self : nil, error: error)
    }
  }

  private func handleLoadedAd(_ ad: MediationBannerAd?, error: Error?) {
    guard let adLoadCompletionHandler else { return }
    eventDelegate = adLoadCompletionHandler(ad, error)
    self.adLoadCompletionHandler = nil
  }

}

// MARK: - UnityAdsBannerDelegate

extension BannerAdLoader: MediationBannerAd {
  var view: UIView {
    guard let bannerAd else {
      Util.log("The Unity Ads banner ad has not been loaded yet. Returning a default UIView.")
      return UIView()
    }
    return bannerAd.view
  }
}

// MARK: - UADSBannerAdDelegate

extension BannerAdLoader: UADSBannerAdDelegate {
  func bannerImpression(_ banner: UADSBannerAd) {
    eventDelegate?.reportImpression()
  }

  func bannerDidFailShow(_ banner: UADSBannerAd, error: any UnityAdsError) {
    eventDelegate?.didFailToPresentWithError(error.toNSError())
  }

  func bannerDidClick(_ banner: UADSBannerAd) {
    eventDelegate?.reportClick()
  }
}
