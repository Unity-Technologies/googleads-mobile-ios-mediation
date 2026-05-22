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

@Suite("Unity adapter RTB rewarded")
@MainActor
final class UnityRTBRewardedAdTests {

  let client: FakeUnityAdsClient

  init() {
    client = FakeUnityAdsClient()
    UnityAdsClientFactory.debugClient = client
  }

  @Test("RTB rewarded ad load succeeds")
  func load_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
  }

  @Test("RTB rewarded load configuration has expected fields")
  func load_configurationFields() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test_ad_markup"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)

    let config = client.rewardedLoadConfiguration
    #expect(config?.placementId == "test_placement")
    #expect(config?.adMarkup == "test_ad_markup")
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
  }

  @Test("RTB rewarded show configuration has watermark")
  func show_configurationHasWatermark() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    adConfig.watermark = "test_watermark".data(using: .utf8)
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)
    eventDelegate.rewardedAd?.present(from: UIViewController())

    let showConfig = client.rewardedShowConfiguration
    let expectedWatermark = "test_watermark".data(using: .utf8)?.base64EncodedString()
    #expect(showConfig?.extras[UnityAdapter.watermarkKey] == expectedWatermark)
  }

  @Test("RTB rewarded ad load fails when placement ID is missing")
  func load_fails_whenPlacementIdMissing() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let expectedError = UnityAdapterError(
      errorCode: .invalidAdConfiguration,
      description: "The ad configuration is missing placement ID."
    )
    AUTKWaitAndAssertLoadRewardedAdFailure(adapter, adConfig, expectedError)
  }

  @Test("RTB rewarded ad load fails when Unity fails")
  func load_fails_whenUnityFails() async {
    client.shouldLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadRewardedAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Presentation succeeds")
  func presentation_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)
    eventDelegate.rewardedAd?.present(from: UIViewController())

    XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1)
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldShowSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)
    eventDelegate.rewardedAd?.present(from: UIViewController())

    XCTAssertNotNil(eventDelegate.didFailToPresentError)
  }

  @Test("Impression count")
  func impression_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)

    client.triggerRewardedImpression()

    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  @Test("Click count")
  func click_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)

    client.triggerRewardedClick()

    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

  @Test("Reward count")
  func reward_count() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)

    client.triggerRewardedReward()

    XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1)
  }

}

@Suite("Unity adapter waterfall rewarded")
@MainActor
final class UnityWaterfallRewardedAdTests {

  let client: FakeUnityAdsClient

  init() {
    client = FakeUnityAdsClient()
    UnityAdsClientFactory.debugClient = client
  }

  @Test("Waterfall rewarded ad load succeeds")
  func load_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
  }

  @Test("Waterfall rewarded load configuration has expected fields")
  func load_configurationFields() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)

    let config = client.rewardedLoadConfiguration
    #expect(config?.placementId == "test_placement")
    #expect(config?.adMarkup == nil)
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
  }

  @Test("Waterfall rewarded show configuration has watermark")
  func show_configurationHasWatermark() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.credentials = credentials
    adConfig.watermark = "test_watermark".data(using: .utf8)
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)
    eventDelegate.rewardedAd?.present(from: UIViewController())

    let showConfig = client.rewardedShowConfiguration
    let expectedWatermark = "test_watermark".data(using: .utf8)?.base64EncodedString()
    #expect(showConfig?.extras[UnityAdapter.watermarkKey] == expectedWatermark)
  }

  @Test("Waterfall rewarded ad load fails")
  func load_fails() async {
    client.shouldLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    AUTKWaitAndAssertLoadRewardedAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Presentation succeeds")
  func presentation_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)
    eventDelegate.rewardedAd?.present(from: UIViewController())

    XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1)
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldShowSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zoneId": "test_placement"]
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.credentials = credentials
    let adapter = UnityAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.rewardedAd)
    eventDelegate.rewardedAd?.present(from: UIViewController())

    XCTAssertNotNil(eventDelegate.didFailToPresentError)
  }

}
