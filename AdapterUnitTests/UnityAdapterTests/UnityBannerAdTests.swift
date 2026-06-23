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

import AdapterUnitTestKit
import Testing
import XCTest

@testable import UnityAdapter

@Suite("Unity adapter RTB banner")
@MainActor
final class UnityRTBBannerAdTests {

  let client: FakeUnityAdsClient

  init() {
    client = FakeUnityAdsClient()
    UnityAdsClientFactory.debugClient = client
  }

  @Test("RTB banner ad load succeeds")
  func load_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
  }

  @Test("RTB banner load configuration has expected fields")
  func load_configurationFields() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.bidResponse = "test_ad_markup"
    adConfig.credentials = credentials
    adConfig.watermark = "test_watermark".data(using: .utf8)
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)

    let config = client.bannerLoadConfiguration
    #expect(config?.placementId == "test_placement")
    #expect(config?.adMarkup == "test_ad_markup")
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
    let expectedWatermark = "test_watermark".data(using: .utf8)?.base64EncodedString()
    #expect(config?.extras[UnityAdapter.watermarkKey] == expectedWatermark)
  }

  @Test("RTB banner ad load fails when placement ID is missing")
  func load_fails_whenPlacementIdMissing() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let expectedError = UnityAdapterError(
      errorCode: .invalidAdConfiguration,
      description: "The ad configuration is missing placement ID."
    )
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, adConfig, expectedError)
  }

  @Test("RTB banner ad load fails when Unity fails")
  func load_fails_whenUnityFails() async {
    client.shouldLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadBannerAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Impression count")
  func impression_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.bannerAd)

    client.triggerBannerImpression()

    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  @Test("Click count")
  func click_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.bannerAd)

    client.triggerBannerClick()

    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

}

@Suite("Unity adapter waterfall banner")
@MainActor
final class UnityWaterfallBannerAdTests {

  let client: FakeUnityAdsClient

  init() {
    client = FakeUnityAdsClient()
    UnityAdsClientFactory.debugClient = client
  }

  @Test("Waterfall banner ad load succeeds for banner size")
  func load_succeeds_forBanner() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.adSize = AdSizeBanner
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
  }

  @Test("Waterfall banner load configuration has expected fields")
  func load_configurationFields() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.adSize = AdSizeBanner
    adConfig.credentials = credentials
    adConfig.watermark = "test_watermark".data(using: .utf8)
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)

    let config = client.bannerLoadConfiguration
    #expect(config?.placementId == "test_placement")
    #expect(config?.adMarkup == nil)
    #expect(config?.bannerSize == CGSize(width: 320, height: 50))
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
    let expectedWatermark = "test_watermark".data(using: .utf8)?.base64EncodedString()
    #expect(config?.extras[UnityAdapter.watermarkKey] == expectedWatermark)
  }

  @Test("Waterfall banner ad load succeeds for medium rectangle")
  func load_succeeds_forMREC() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.adSize = AdSizeMediumRectangle
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
  }

  @Test("Waterfall banner ad load succeeds for leaderboard")
  func load_succeeds_forLeaderboard() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.adSize = AdSizeLeaderboard
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
  }

  @Test("Waterfall banner ad load fails when Unity fails")
  func load_fails_whenUnityFails() async {
    client.shouldLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadBannerAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Impression count")
  func impression_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.adSize = AdSizeBanner
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.bannerAd)

    client.triggerBannerImpression()

    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  @Test("Click count")
  func click_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationBannerAdConfiguration()
    adConfig.adSize = AdSizeBanner
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.bannerAd)

    client.triggerBannerClick()

    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

}
