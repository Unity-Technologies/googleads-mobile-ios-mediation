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
import UnityAds

@testable import UnityAdapter

@Suite("Unity adapter information")
@MainActor
final class UnityAdapterInfoTests {

  init() {
    UnityAdsClientFactory.debugClient = FakeUnityAdsClient()
  }

  @Test("Adapter version validation")
  func adapterVersion_validates() {
    let adapterVersion = UnityAdapter.adapterVersion()
    #expect(adapterVersion.majorVersion > 0)
    #expect(adapterVersion.minorVersion >= 0)
    #expect(adapterVersion.patchVersion >= 0)
  }

  @Test("Ad SDK version validation")
  func adSdkVersion_validates() {
    let adSdkVersion = UnityAdapter.adSDKVersion()
    #expect(adSdkVersion.majorVersion > 0)
    #expect(adSdkVersion.minorVersion >= 0)
    #expect(adSdkVersion.patchVersion >= 0)
  }

  @Test("Adapter extra validation")
  func adapterExtra_validates() {
    #expect(UnityAdapter.networkExtrasClass() == nil)
  }

}

@Suite("Unity adapter set up")
@MainActor
final class UnityAdapterInitTests {

  let client: FakeUnityAdsClient

  init() {
    client = FakeUnityAdsClient()
    UnityAdsClientFactory.debugClient = client
  }

  @Test("Set up succeeds")
  func setUp_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["gameId": "test_game_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      UnityAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.initializationConfiguration?.gameId == "test_game_id")
  }

  @Test("Set up configuration has expected fields")
  func setUp_configurationFields() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["gameId": "test_game_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      UnityAdapter.setUp(with: serverConfiguration) { error in
        setUpCompletion()
      }
    }

    let config = client.initializationConfiguration
    #expect(config?.gameId == "test_game_id")
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
    #expect(config?.isTestModeEnabled == false)
    #expect(config?.logLevel == .info)
  }

  @Test("Set up configuration has test mode enabled when set")
  func setUp_configurationWithTestMode() async {
    UnityAdapter.setTestMode(true)

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["gameId": "test_game_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      UnityAdapter.setUp(with: serverConfiguration) { error in
        setUpCompletion()
      }
    }

    let config = client.initializationConfiguration
    #expect(config?.isTestModeEnabled == true)
    #expect(config?.logLevel == .debug)

    UnityAdapter.setTestMode(false)
  }

  @Test("Set up fails when missing game ID")
  func setUp_failsMissingGameId() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      UnityAdapter.setUp(with: serverConfiguration) { error in
        #expect(error != nil)
        setUpCompletion()
      }
    }
  }

  @Test("Set up fails when initialization fails")
  func setUp_failsWhenInitFails() async {
    client.shouldInitializeSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["gameId": "test_game_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      UnityAdapter.setUp(with: serverConfiguration) { error in
        #expect(error != nil)
        setUpCompletion()
      }
    }
  }

}

@Suite("Unity adapter signals collection")
@MainActor
final class UnityAdapterSignalsCollectionTests {

  let client: FakeUnityAdsClient
  
  init() {
    client = FakeUnityAdsClient()
    UnityAdsClientFactory.debugClient = client
  }

  @Test("The adapter collects signals for a banner ad request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsBanner() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .banner
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let bannerSize = CGSize(width: 320, height: 50)
    requestParams.adSize = AdSize(size: bannerSize, flags: 0)

    let adapter = UnityAdapter()
    await confirmation("wait for the adapter collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error == nil)
          #expect(signals != nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
    let config = client.tokenConfiguration
    #expect(config?.adFormat == .banner)
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
    #expect(config?.bannerSize == bannerSize)
  }

  @Test("The adapter collects signals for an interstitial ad request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsInterstitial() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .interstitial
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = UnityAdapter()
    await confirmation("wait for the adapter collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error == nil)
          #expect(signals != nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
    let config = client.tokenConfiguration
    #expect(config?.adFormat == .interstitial)
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
    #expect(config?.bannerSize == .zero)
  }

  @Test("The adapter collects signals for a rewarded ad request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsRewarded() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .rewarded
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = UnityAdapter()
    await confirmation("wait for the adapter collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error == nil)
          #expect(signals != nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
    let config = client.tokenConfiguration
    #expect(config?.adFormat == .rewarded)
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
    #expect(config?.bannerSize == .zero)
  }

  @Test("The adapter collects signals for a rewarded interstitial ad request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsRewardedInterstitial() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .rewardedInterstitial
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = UnityAdapter()
    await confirmation("wait for the adapter collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error == nil)
          #expect(signals != nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
    let config = client.tokenConfiguration
    #expect(config?.adFormat == .rewarded)
    #expect(config?.mediationInfo?.name == UnityAdapter.mediationName)
    #expect(config?.mediationInfo?.adapterVersion == UnityAdapter.adapterVersionString)
    #expect(config?.bannerSize == .zero)
  }

  @Test("The adapter fails to collect signals for a native ad request.")
  func signalCollection_fails_whenRequestFormatIsNative() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .native
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = UnityAdapter()
    await confirmation("wait for the adapter collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error != nil)
          #expect(signals == nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
  }

}
