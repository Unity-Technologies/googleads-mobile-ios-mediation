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
import UnityAds

@objc(GADMediationAdapterUnity)
final class UnityAdapter: NSObject, RTBAdapter {

  static let adapterVersionString = "4.19.0.0"
  static let mediationName = "AdMob"
  
  static let watermarkKey = "watermark"

  nonisolated(unsafe) private static var isTestMode = false
  
  var bannerAdLoader: BannerAdLoader?

  var interstitialAdLoader: InterstitialAdLoader?

  var rewardedAdLoader: RewardedAdLoader?

  @objc static func setUp(with configuration: MediationServerConfiguration,
                          completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock) {
    do {
      let gameId = try Util.gameId(from: configuration)
      let client = UnityAdsClientFactory.createClient()

      updatePrivacyPreferences(client: client)

      let initConfig = UADSInitializationConfigurationBuilder(gameId: gameId)
        .with(testMode: isTestMode)
        .with(mediationInfo: Self.mediationInfo)
        .with(logLevel: isTestMode ? .debug : .info)
        .build()

      Util.log("setUp: initializing UnityAds (gameId=\(gameId), testMode=\(isTestMode))")
      client.initialize(configuration: initConfig) { error in
        if let error {
          Util.log("setUp: UnityAds init failed — \(error.localizedDescription)")
        } else {
          Util.log("setUp: UnityAds init succeeded")
        }
        completionHandler(error)
      }
    } catch {
      Util.log("setUp: aborted before SDK init — \(error.localizedDescription)")
      completionHandler(error)
    }
  }

  @objc static func networkExtrasClass() -> (any AdNetworkExtras.Type)? {
    return nil
  }

  @objc static func adapterVersion() -> VersionNumber {
    let adapterVersion = Self.adapterVersionString.components(separatedBy: ".").compactMap {
      Int($0)
    }
    guard adapterVersion.count >= 3 else {
      return VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
    }
    let patch =
      adapterVersion.count == 4
      ? adapterVersion[2] * 100 + adapterVersion[3] : adapterVersion[2]
    return VersionNumber(
      majorVersion: adapterVersion[0],
      minorVersion: adapterVersion[1],
      patchVersion: patch
    )
  }

  @objc static func adSDKVersion() -> VersionNumber {
    let adSDKVersion = UnityAdsClientFactory.createClient().version().components(
      separatedBy: "."
    )
    .compactMap { Int($0) }
    guard adSDKVersion.count >= 3 else {
      return VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
    }
    return VersionNumber(
      majorVersion: adSDKVersion[0],
      minorVersion: adSDKVersion[1],
      patchVersion: adSDKVersion[2]
    )
  }
  
  static var mediationInfo: UADSMediationInfo {
    UADSMediationInfo(
      name: Self.mediationName,
      version: "\(MobileAds.shared.versionNumber.majorVersion).\(MobileAds.shared.versionNumber.minorVersion).\(MobileAds.shared.versionNumber.patchVersion)",
      adapterVersion: Self.adapterVersionString
    )
  }

  @objc static func setTestMode(_ testMode: Bool) {
    Util.log("Updating test mode flag to `\(testMode ? "YES" : "NO")`")
    isTestMode = testMode
  }

  @objc static func testMode() -> Bool {
    return isTestMode
  }

  @objc func collectSignals(for params: RTBRequestParameters,
                            completionHandler: @escaping GADRTBSignalCompletionHandler) {
    do {
      let format = try Util.adFormat(from: params).toUnityAdFormat()
      var configBuilder = UADSTokenConfigurationBuilder(adFormat: format)
      configBuilder = configBuilder.with(mediationInfo: Self.mediationInfo)
      configBuilder = configBuilder.with(bannerSize: params.adSize.size)
      let tokenConfig = configBuilder.build()
      try UnityAdsClientFactory.createClient().collectSignals(configuration: tokenConfig) { signals in
        completionHandler(signals, nil)
      }
    } catch  {
      completionHandler(nil, error)
    } 
  }

  @objc
  func loadBanner(
    for adConfiguration: MediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    Self.updatePrivacyPreferences(client: UnityAdsClientFactory.createClient())

    bannerAdLoader = BannerAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    bannerAdLoader?.loadAd()
  }

  @objc
  func loadInterstitial(
    for adConfiguration: MediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    Self.updatePrivacyPreferences(client: UnityAdsClientFactory.createClient())

    interstitialAdLoader = InterstitialAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    interstitialAdLoader?.loadAd()
  }

  @objc
  func loadRewardedAd(
    for adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    Self.updatePrivacyPreferences(client: UnityAdsClientFactory.createClient())

    rewardedAdLoader = RewardedAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    rewardedAdLoader?.loadAd()
  }

  private static func updatePrivacyPreferences(client: UnityAdsClient) {
    let tagForChildDirectedTreatment =
      MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment
    let tagForUnderAgeOfConsent = MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent

    let isChildDirected = tagForChildDirectedTreatment?.boolValue == true
    let isUnderAge = tagForUnderAgeOfConsent?.boolValue == true
    let isNotChildDirected = tagForChildDirectedTreatment?.boolValue == false
    let isNotUnderAge = tagForUnderAgeOfConsent?.boolValue == false

    if !isChildDirected && !isUnderAge && (isNotChildDirected || isNotUnderAge) {
      client.setNonBehavioral(false)
    } else {
      client.setNonBehavioral(true)
    }
  }

}

// MARK: - AdFormat Extension

extension GoogleMobileAds.AdFormat {
  
  fileprivate func toUnityAdFormat() throws(UnityAdapterError) -> UADSAdFormat {
    switch self {
    case .banner: return .banner
    case .interstitial: return .interstitial
    case .rewarded, .rewardedInterstitial: return .rewarded
    default:
      throw UnityAdapterError(
        errorCode: .unsupportedAdFormat,
        description: "Unsupported ad format. Provided format: \(self).")
    }
  }
  
}
