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

import BidMachine
import Foundation
import GoogleMobileAds

final class RewardedAdLoader: NSObject {

  /// The rewarded ad configuration.
  private let adConfiguration: MediationRewardedAdConfiguration

  /// The ad event delegate which is used to report rewarded related information to the Google
  /// Mobile Ads SDK.
  private weak var eventDelegate: MediationRewardedAdEventDelegate?

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var rewardedAdLoadCompletionHandler: ((MediationRewardedAd?, NSError?) -> Void)?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationRewardedLoadCompletionHandler?

  private let client: BidMachineClient

  private var rewardedAd: BidMachineRewarded?

  init(
    adConfiguration: MediationRewardedAdConfiguration,
    loadCompletionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationRewardedAdLoadCompletionQueue")
    self.client = BidMachineClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    guard let bidResponse = adConfiguration.bidResponse else {
      handleLoadedAd(
        nil,
        error: BidMachineAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing bid response."
        ).toNSError())
      return
    }

    guard let watermark = adConfiguration.watermark?.base64EncodedString() else {
      handleLoadedAd(
        nil,
        error: BidMachineAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing watermark."
        ).toNSError())
      return
    }

    do {
      try client.loadRTBRewardedAd(with: bidResponse, delegate: self, watermark: watermark) {
        [weak self] error in
        guard let self else { return }
        guard error == nil else {
          self.handleLoadedAd(nil, error: error)
          return
        }
      }
    } catch {
      handleLoadedAd(nil, error: error as NSError)
    }
  }

  private func handleLoadedAd(_ ad: MediationRewardedAd?, error: Error?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - GADMediationRewardedAd

extension RewardedAdLoader: MediationRewardedAd {

  func present(from viewController: UIViewController) {
    do {
      try client.present(rewardedAd, from: viewController)
    } catch {
      eventDelegate?.didFailToPresentWithError(error.toNSError())
    }
  }

}

// MARK: - BidMachineAdDelegate

extension RewardedAdLoader: BidMachineAdDelegate {

  func didLoadAd(_ ad: any BidMachine.BidMachineAdProtocol) {
    rewardedAd = ad as? BidMachineRewarded
    handleLoadedAd(self, error: nil)
  }

  func didFailLoadAd(_ ad: any BidMachine.BidMachineAdProtocol, _ error: any Error) {
    handleLoadedAd(nil, error: error as NSError)
  }

  func didTrackImpression(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.reportImpression()
  }

  func didTrackInteraction(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.reportClick()
  }

  func willPresentScreen(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.willPresentFullScreenView()
  }

  func didDismissAd(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.didDismissFullScreenView()
  }

  func didFailPresentAd(_ ad: any BidMachineAdProtocol, _ error: any Error) {
    eventDelegate?.didFailToPresentWithError(error)
  }

  func didReceiveReward(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.didRewardUser()
  }

}
