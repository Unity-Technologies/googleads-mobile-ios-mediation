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

import GoogleMobileAds
import UIKit
import UnityAds

@testable import UnityAdapter

final class FakeUnityAdsClient: NSObject, UnityAdsClient, @unchecked Sendable {

  // Use unsafeBitCast to create stub instances since Unity SDK types don't have accessible inits
  let fakeBannerAd: UADSBannerAd = unsafeBitCast(NSObject(), to: UADSBannerAd.self)
  let fakeInterstitialAd: UADSInterstitialAd = unsafeBitCast(NSObject(), to: UADSInterstitialAd.self)
  let fakeRewardedAd: UADSRewardedAd = unsafeBitCast(NSObject(), to: UADSRewardedAd.self)

  var shouldInitializeSucceed = true
  var shouldLoadSucceed = true
  var shouldShowSucceed = true

  // Captured configurations for verification
  var initializationConfiguration: UADSInitializationConfiguration?
  var tokenConfiguration: UADSTokenConfiguration?
  var bannerLoadConfiguration: UADSBannerLoadConfiguration?
  var interstitialLoadConfiguration: UADSLoadConfiguration?
  var rewardedLoadConfiguration: UADSLoadConfiguration?
  var interstitialShowConfiguration: UADSShowConfiguration?
  var rewardedShowConfiguration: UADSShowConfiguration?

  /// Last value passed to `setNonBehavioral(_:)`. `nil` if the method has never been called.
  var lastNonBehavioralValue: Bool?

  /// Number of times `setNonBehavioral(_:)` has been called on this fake.
  var setNonBehavioralCallCount = 0

  private var bannerDelegate: UADSBannerAdDelegate?
  private var interstitialDelegate: UADSInterstitialShowDelegate?
  private var rewardedDelegate: UADSRewardedShowDelegate?

  func version() -> String {
    return "4.16.3"
  }

  func initialize(
    configuration: UADSInitializationConfiguration,
    completion: @escaping (Error?) -> Void
  ) {
    initializationConfiguration = configuration
    if shouldInitializeSucceed {
      completion(nil)
    } else {
      completion(NSError(domain: "com.test.domain", code: 12345))
    }
  }

  func setNonBehavioral(_ nonBehavioral: Bool) {
    lastNonBehavioralValue = nonBehavioral
    setNonBehavioralCallCount += 1
  }

  func collectSignals(
    configuration: UADSTokenConfiguration,
    completionHandler: @escaping (String?) -> Void
  ) throws(UnityAdapterError) {
    tokenConfiguration = configuration
    completionHandler("Test signals")
  }

  func loadBannerAd(
    configuration: UADSBannerLoadConfiguration,
    completionHandler: @escaping (UADSBannerAd?, Error?) -> Void
  ) {
    bannerLoadConfiguration = configuration
    bannerDelegate = configuration.delegate
    if !shouldLoadSucceed {
      completionHandler(nil, NSError(domain: "com.test.domain", code: 12345))
      return
    }
    completionHandler(fakeBannerAd, nil)
  }

  func loadInterstitialAd(
    configuration: UADSLoadConfiguration,
    completionHandler: @escaping (UADSInterstitialAd?, Error?) -> Void
  ) {
    interstitialLoadConfiguration = configuration
    if !shouldLoadSucceed {
      completionHandler(nil, NSError(domain: "com.test.domain", code: 12345))
      return
    }
    completionHandler(fakeInterstitialAd, nil)
  }

  func presentInterstitial(
    _ interstitialAd: UADSInterstitialAd?,
    configuration: UADSShowConfiguration,
    delegate: UADSInterstitialShowDelegate
  ) throws(UnityAdapterError) {
    guard let interstitialAd else {
      throw UnityAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "Interstitial ad is not ready for presentation.")
    }

    interstitialShowConfiguration = configuration
    interstitialDelegate = delegate
    if shouldShowSucceed {
      delegate.showDidStart(interstitialAd)
      delegate.showDidComplete(interstitialAd, with: .completed)
    } else {
      delegate.showDidFail(interstitialAd, error: FakeUnityAdsError())
    }
  }

  func loadRewardedAd(
    configuration: UADSLoadConfiguration,
    completionHandler: @escaping (UADSRewardedAd?, Error?) -> Void
  ) {
    rewardedLoadConfiguration = configuration
    if !shouldLoadSucceed {
      completionHandler(nil, NSError(domain: "com.test.domain", code: 12345))
      return
    }
    completionHandler(fakeRewardedAd, nil)
  }

  func presentRewarded(
    _ rewardedAd: UADSRewardedAd?,
    configuration: UADSShowConfiguration,
    delegate: UADSRewardedShowDelegate
  ) throws(UnityAdapterError) {
    guard let rewardedAd else {
      throw UnityAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "Rewarded ad is not ready for presentation.")
    }

    rewardedShowConfiguration = configuration
    rewardedDelegate = delegate
    if shouldShowSucceed {
      delegate.showDidStart(rewardedAd)
      delegate.showDidReceiveReward(rewardedAd)
      delegate.showDidComplete(rewardedAd, with: .completed)
    } else {
      delegate.showDidFail(rewardedAd, error: FakeUnityAdsError())
    }
  }

  // MARK: - Test trigger methods

  func triggerBannerImpression() {
    bannerDelegate?.bannerImpression(fakeBannerAd)
  }

  func triggerBannerClick() {
    bannerDelegate?.bannerDidClick(fakeBannerAd)
  }

  func triggerInterstitialImpression() {
    interstitialDelegate?.showDidStart(fakeInterstitialAd)
  }

  func triggerInterstitialClick() {
    interstitialDelegate?.showDidClick(fakeInterstitialAd)
  }

  func triggerRewardedImpression() {
    rewardedDelegate?.showDidStart(fakeRewardedAd)
  }

  func triggerRewardedClick() {
    rewardedDelegate?.showDidClick(fakeRewardedAd)
  }

  func triggerRewardedReward() {
    rewardedDelegate?.showDidReceiveReward(fakeRewardedAd)
  }
}

// MARK: - Fake UnityAdsError

final class FakeUnityAdsError: UnityAdsError {
  var code: Int { 12345 }
  var message: String { "Test error" }
}
