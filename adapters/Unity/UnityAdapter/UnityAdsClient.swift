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


/// Factory that creates UnityAdsClient.
final class UnityAdsClientFactory {

  private init() {}

  #if DEBUG
    nonisolated(unsafe) static var debugClient: UnityAdsClient?
  #endif

  static func createClient() -> UnityAdsClient {
    #if DEBUG
      return debugClient ?? UnityAdsClientImpl()
    #else
      return UnityAdsClientImpl()
    #endif
  }

}

protocol UnityAdsClient: NSObject {

  /// Returns a version string of Unity Ads SDK.
  func version() -> String

  /// Initializes the Unity Ads SDK.
  func initialize(configuration: UADSInitializationConfiguration,
                  completion: @escaping (Error?) -> Void)

  /// Collects the bidding token for the specified ad format.
  func collectSignals(configuration: UADSTokenConfiguration,
                      completionHandler: @escaping (String?) -> Void) throws(UnityAdapterError)

  /// Loads a banner ad.
  func loadBannerAd(configuration: UADSBannerLoadConfiguration,
                    completionHandler: @escaping (UADSBannerAd?, Error?) -> Void)

  /// Loads an interstitial ad.
  func loadInterstitialAd(configuration: UADSLoadConfiguration,
                          completionHandler: @escaping (UADSInterstitialAd?, Error?) -> Void)

  /// Presents the loaded interstitial ad.
  func presentInterstitial(_ interstitialAd: UADSInterstitialAd?,
                           configuration: UADSShowConfiguration,
                           delegate: UADSInterstitialShowDelegate) throws(UnityAdapterError)

  /// Loads a rewarded ad.
  func loadRewardedAd(configuration: UADSLoadConfiguration,
                      completionHandler: @escaping (UADSRewardedAd?, Error?) -> Void)

  /// Presents the loaded rewarded ad.
  func presentRewarded(_ rewardedAd: UADSRewardedAd?,
                       configuration: UADSShowConfiguration,
                       delegate: UADSRewardedShowDelegate) throws(UnityAdapterError)
}


final class UnityAdsClientImpl: NSObject, UnityAdsClient {

  private static let mediationName = "AdMob"
  private static let adapterVersion = "4.18.0.0"
  private static let watermarkKey = "watermark"

  func version() -> String {
    return UnityAds.getVersion()
  }

  func initialize(configuration: UADSInitializationConfiguration,
                  completion: @escaping (Error?) -> Void) {
    guard !UnityAds.isInitialized() else {
      completion(nil)
      return
    }

    UnityAds.initialize(configuration) { error in
      completion(error?.toAdapterError())
    }
  }

  func collectSignals(configuration: UADSTokenConfiguration, completionHandler: @escaping (String?) -> Void) throws(UnityAdapterError) {
    UnityAds.getToken(configuration) { token in
      completionHandler(token ?? "")
    }
  }

  func loadBannerAd(configuration: UADSBannerLoadConfiguration, completionHandler: @escaping (UADSBannerAd?, Error?) -> Void) {
    UADSBannerAd.load(configuration) { banner, error in
      completionHandler(banner, error?.toAdapterError())
    }
  }

  func loadInterstitialAd(configuration: UADSLoadConfiguration, completionHandler: @escaping (UADSInterstitialAd?, Error?) -> Void) {
    UADSInterstitialAd.load(configuration) { ad, error in
      completionHandler(ad, error?.toAdapterError())
    }
  }

  func presentInterstitial(_ interstitialAd: UADSInterstitialAd?, configuration: UADSShowConfiguration, delegate: UADSInterstitialShowDelegate) throws(UnityAdapterError) {
    guard let interstitialAd else {
      throw UnityAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "Interstitial ad is not ready for presentation.")
    }

    interstitialAd.show(configuration, delegate: delegate)
  }

  func loadRewardedAd(configuration: UADSLoadConfiguration, completionHandler: @escaping (UADSRewardedAd?, Error?) -> Void) {
    UADSRewardedAd.load(configuration) { ad, error in
      completionHandler(ad, error?.toAdapterError())
    }
  }

func presentRewarded(_ rewardedAd: UADSRewardedAd?, configuration: UADSShowConfiguration, delegate: UADSRewardedShowDelegate) throws(UnityAdapterError) {
    guard let rewardedAd else {
      throw UnityAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "Rewarded ad is not ready for presentation.")
    }

    rewardedAd.show(configuration, delegate: delegate)
  }

}

