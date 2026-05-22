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

@Suite("Unity adapter RTB interstitial")
@MainActor
final class UnityRTBInterstitialAdTests {

  let client: FakeUnityAdsClient

  init() {
    client = FakeUnityAdsClient()
    UnityAdsClientFactory.debugClient = client
  }

  @Test("RTB interstitial ad load succeeds")
  func loadInterstitial_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
  }

  @Test("RTB interstitial load configuration has expected fields")
  func load_configurationFields() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test_ad_markup"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)

    let config = client.interstitialLoadConfiguration
    #expect(config?.placementId == "test_placement")
    #expect(config?.adMarkup == "test_ad_markup")
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
  }

  @Test("RTB interstitial show configuration has watermark")
  func show_configurationHasWatermark() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    adConfig.watermark = "test_watermark".data(using: .utf8)
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    eventDelegate.interstitialAd?.present(from: UIViewController())

    let showConfig = client.interstitialShowConfiguration
    let expectedWatermark = "test_watermark".data(using: .utf8)?.base64EncodedString()
    #expect(showConfig?.extras[UnityAdapter.watermarkKey] == expectedWatermark)
  }

  @Test("RTB interstitial ad load fails when placement ID is missing")
  func loadInterstitial_fails_whenPlacementIdMissing() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let expectedError = UnityAdapterError(
      errorCode: .invalidAdConfiguration,
      description: "The ad configuration is missing placement ID."
    )
    AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, adConfig, expectedError)
  }

  @Test("RTB interstitial ad load fails when Unity fails")
  func loadInterstitial_fails_whenUnityFails() async {
    client.shouldLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Presentation succeeds")
  func presentation_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    eventDelegate.interstitialAd?.present(from: UIViewController())

    XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1)
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldShowSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    eventDelegate.interstitialAd?.present(from: UIViewController())

    XCTAssertNotNil(eventDelegate.didFailToPresentError)
  }

  @Test("Impression count")
  func impression_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)

    client.triggerInterstitialImpression()

    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  @Test("Click count")
  func click_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)

    client.triggerInterstitialClick()

    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

}

@Suite("Unity adapter waterfall interstitial")
@MainActor
final class UnityWaterfallInterstitialAdTests {

  let client: FakeUnityAdsClient

  init() {
    client = FakeUnityAdsClient()
    UnityAdsClientFactory.debugClient = client
  }

  @Test("Waterfall interstitial ad load succeeds")
  func loadInterstitial_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
  }

  @Test("Waterfall interstitial load configuration has expected fields")
  func load_configurationFields() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)

    let config = client.interstitialLoadConfiguration
    #expect(config?.placementId == "test_placement")
    #expect(config?.adMarkup == nil)
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
  }

  @Test("Waterfall interstitial show configuration has watermark")
  func show_configurationHasWatermark() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.credentials = credentials
    adConfig.watermark = "test_watermark".data(using: .utf8)
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    eventDelegate.interstitialAd?.present(from: UIViewController())

    let showConfig = client.interstitialShowConfiguration
    let expectedWatermark = "test_watermark".data(using: .utf8)?.base64EncodedString()
    #expect(showConfig?.extras[UnityAdapter.watermarkKey] == expectedWatermark)
  }

  @Test("Waterfall interstitial ad load fails")
  func loadInterstitial_fails() async {
    client.shouldLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Presentation succeeds")
  func presentation_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    eventDelegate.interstitialAd?.present(from: UIViewController())

    XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1)
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldShowSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    eventDelegate.interstitialAd?.present(from: UIViewController())

    XCTAssertNotNil(eventDelegate.didFailToPresentError)
  }

}
