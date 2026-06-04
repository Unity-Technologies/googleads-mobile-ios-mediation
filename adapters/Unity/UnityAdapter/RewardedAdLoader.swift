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

final class RewardedAdLoader: NSObject {
  
  private let adConfiguration: MediationRewardedAdConfiguration
  
  weak var eventDelegate: MediationRewardedAdEventDelegate?
  
  private var adLoadCompletionHandler: GADMediationRewardedLoadCompletionHandler?
  
  private let client: UnityAdsClient
  
  private var rewardedAd: UADSRewardedAd?
  
  init(adConfiguration: MediationRewardedAdConfiguration,
    loadCompletionHandler: @escaping GADMediationRewardedLoadCompletionHandler) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.client = UnityAdsClientFactory.createClient()
    super.init()
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
    
    var configBuilder = UADSLoadConfigurationBuilder(placementId: placementId)
    if let adMarkup = adConfiguration.bidResponse{
      configBuilder = configBuilder.with(adMarkup: adMarkup)
    }
    let config = configBuilder.with(mediationInfo: UnityAdapter.mediationInfo).build()
    
    client.loadRewardedAd(configuration: config) { [weak self] ad, error in
      guard let self else { return }
      self.rewardedAd = ad
      self.handleLoadedAd(error == nil ? self : nil, error: error)
    }
  }
  
  private func handleLoadedAd(_ ad: MediationRewardedAd?, error: Error?) {
    guard let adLoadCompletionHandler else { return }
    eventDelegate = adLoadCompletionHandler(ad, error)
    self.adLoadCompletionHandler = nil
  }
  
}

// MARK: - MediationRewardedAd

extension RewardedAdLoader: MediationRewardedAd {
  func present(from viewController: UIViewController) {
    eventDelegate?.willPresentFullScreenView()
    
    var configBuilder = UADSShowConfigurationBuilder().with(viewController: viewController)
    if let watermark = adConfiguration.watermark?.base64EncodedString() {
      configBuilder = configBuilder.with(extras: [UnityAdapter.watermarkKey: watermark])
    }
    let showConfig = configBuilder.build()
    
    do {
      try client.presentRewarded(rewardedAd, configuration: showConfig, delegate: self)
    } catch {
      eventDelegate?.didFailToPresentWithError(error)
    }
  }

}

// MARK: - UADSRewardedShowDelegate

extension RewardedAdLoader: UADSRewardedShowDelegate {
    func showDidStart(_ unityAd: UADSRewardedAd) {
        eventDelegate?.didStartVideo()
        eventDelegate?.reportImpression()
    }
    
    func showDidClick(_ unityAd: UADSRewardedAd) {
        eventDelegate?.reportClick()
    }
    
    func showDidComplete(_ unityAd: UADSRewardedAd, with finishState: UADSShowFinishState) {
        eventDelegate?.didEndVideo()
        eventDelegate?.willDismissFullScreenView()
        eventDelegate?.didDismissFullScreenView()
    }
    
    func showDidFail(_ unityAd: UADSRewardedAd, error: any UnityAdsError) {
        eventDelegate?.didFailToPresentWithError(error.toNSError())
    }
    
    func showDidReceiveReward(_ unityAd: UADSRewardedAd) {
        eventDelegate?.didRewardUser()
    }
}
