// Copyright 2024 Google LLC.
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
import GoogleMobileAds
import MolocoSDK
import XCTest

@testable import MolocoAdapter

/// Tests for MolocoMediationAdapter.
final class MolocoMediationAdapterTest: XCTestCase {

  /// A test app key used in the tests.
  let appKey1 = "app_key_12345"

  /// Another test app key used in the tests.
  let appKey2 = "app_key_6789"

  override func tearDown() {
    // Unset child and under-age tags after every test.
    MobileAds.shared.requestConfiguration
      .tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration
      .tagForUnderAgeOfConsent = nil
  }

  /// A fake implementation of MolocoInitializer protocol that mimics successful initialization.
  class MolocoInitializerThatSucceeds: MolocoInitializer {

    /// Var to capture the app ID that is used to initialize the Moloco SDK. Used for assertion. It
    /// is initlialized to a value that is never asserted for.
    var appIDUsedToInitializeMoloco: String = ""

    @available(iOS 13.0, *)
    func initialize(
      initParams: MolocoInitParams, completion: ((Bool, Error?) -> Void)?
    ) {
      appIDUsedToInitializeMoloco = initParams.appKey
      completion?(true, nil)
    }

    func isInitialized() -> Bool {
      // Stub to return false.
      return false
    }
  }

  func testSetUpSuccess() throws {
    let molocoInitializer = MolocoInitializerThatSucceeds()
    MolocoMediationAdapter.setMolocoInitializer(molocoInitializer)
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.appIDKey: appKey1]

    AUTKWaitAndAssertAdapterSetUpWithCredentials(MolocoMediationAdapter.self, credentials)
    XCTAssertEqual(molocoInitializer.appIDUsedToInitializeMoloco, appKey1)
  }

  func testSetUpSuccess_evenIfMultipleAppKeysFoundInCredentials() throws {
    MolocoMediationAdapter.setMolocoInitializer(
      MolocoInitializerThatSucceeds())
    let credentials1 = AUTKMediationCredentials()
    credentials1.settings = [MolocoConstants.appIDKey: appKey1]
    let credentials2 = AUTKMediationCredentials()
    credentials2.settings = [MolocoConstants.appIDKey: appKey2]
    let mediationServerConfig = AUTKMediationServerConfiguration()
    mediationServerConfig.credentials = [credentials1, credentials2]

    AUTKWaitAndAssertAdapterSetUpWithConfiguration(
      MolocoMediationAdapter.self, mediationServerConfig)
  }

  /// A fake implementation of MolocoInitializer protocol that is already initialized.
  class MolocoInitializerAlreadyInitialized: MolocoInitializer {

    @available(iOS 13.0, *)
    func initialize(
      initParams: MolocoInitParams, completion: ((Bool, Error?) -> Void)?
    ) {
      completion?(true, nil)
    }

    func isInitialized() -> Bool {
      return true
    }
  }

  func testSetUpSuccess_ifMolocoAlreadyInitialized() throws {
    MolocoMediationAdapter.setMolocoInitializer(MolocoInitializerAlreadyInitialized())
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.appIDKey: appKey1]

    AUTKWaitAndAssertAdapterSetUpWithCredentials(MolocoMediationAdapter.self, credentials)
  }

  /// A fake implementation of MolocoInitializer protocol that mimics initialization failure.
  class MolocoInitializerThatFailsToInitialize: MolocoInitializer {

    @available(iOS 13.0, *)
    func initialize(
      initParams: MolocoInitParams, completion: ((Bool, Error?) -> Void)?
    ) {
      let initializationError = NSError.init(domain: "moloco_sdk_domain", code: 1001)
      completion?(false, initializationError)
    }

    func isInitialized() -> Bool {
      // Stub to return false.
      return false
    }
  }

  func testSetUpFailure_ifMolocoInitializationFails() throws {
    MolocoMediationAdapter.setMolocoInitializer(MolocoInitializerThatFailsToInitialize())
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.appIDKey: appKey1]
    let mediationServerConfig = AUTKMediationServerConfiguration()
    mediationServerConfig.credentials = [credentials]

    let expectedError = NSError.init(domain: "moloco_sdk_domain", code: 1001)
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      MolocoMediationAdapter.self, mediationServerConfig, expectedError)
  }

  func testSetUpFailure_ifAppKeyIsMissing() throws {
    let mediationServerConfig = AUTKMediationServerConfiguration()
    mediationServerConfig.credentials = [AUTKMediationCredentials()]

    let expectedError = NSError.init(
      domain: MolocoConstants.adapterErrorDomain, code: MolocoAdapterErrorCode.invalidAppID.rawValue
    )
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      MolocoMediationAdapter.self, mediationServerConfig, expectedError)
  }

  func testCollectSignalsSuccess_ifMolocoReturnsBidToken() {
    let expectedBidToken = "a sample bid token"
    let molocoBidTokenGetter = FakeMolocoBidTokenGetter(bidToken: expectedBidToken)
    let adapter = MolocoMediationAdapter(molocoBidTokenGetter: molocoBidTokenGetter)
    let successExpectation = XCTestExpectation()
    let requestParameters = RTBRequestParameters()

    adapter.collectSignals(for: requestParameters) { bidToken, error in
      XCTAssertEqual(bidToken, expectedBidToken)
      XCTAssertNil(error)
      successExpectation.fulfill()
    }
    let result = XCTWaiter.wait(for: [successExpectation], timeout: AUTKExpectationTimeout)
    XCTAssertEqual(result, XCTWaiter.Result.completed)
  }

  func testCollectSignalsFailure_ifMolocoFailsToReturnBidToken() {
    let expectedError = NSError.init(domain: "moloco_sdk_domain", code: 1010)
    let molocoBidTokenGetter = FakeMolocoBidTokenGetter(error: expectedError)
    let adapter = MolocoMediationAdapter(molocoBidTokenGetter: molocoBidTokenGetter)
    let failureExpectation = XCTestExpectation()
    let requestParameters = RTBRequestParameters()

    adapter.collectSignals(for: requestParameters) { bidToken, error in
      XCTAssertNil(bidToken)
      let error = error as NSError?
      XCTAssertEqual(error?.domain, "moloco_sdk_domain")
      XCTAssertEqual(error?.code, 1010)
      failureExpectation.fulfill()
    }
    let result = XCTWaiter.wait(for: [failureExpectation], timeout: AUTKExpectationTimeout)
    XCTAssertEqual(result, XCTWaiter.Result.completed)
  }

  func testAdapterVersion() {
    let adapterVersion = MolocoMediationAdapter.adapterVersion()

    XCTAssertGreaterThan(adapterVersion.majorVersion, 0)
    XCTAssertLessThanOrEqual(adapterVersion.majorVersion, 99)
    XCTAssertGreaterThanOrEqual(adapterVersion.minorVersion, 0)
    XCTAssertLessThanOrEqual(adapterVersion.minorVersion, 99)
    XCTAssertGreaterThanOrEqual(adapterVersion.patchVersion, 0)
    XCTAssertLessThanOrEqual(adapterVersion.patchVersion, 9999)
  }

  func testAdSDKVersion_succeeds() {
    let molocoSdkVersionProviding = FakeMolocoSdkVersionProvider(sdkVersion: "3.21.430")
    MolocoMediationAdapter.setMolocoSdkVersionProvider(molocoSdkVersionProviding)

    let adSDKVersion = MolocoMediationAdapter.adSDKVersion()

    XCTAssertEqual(adSDKVersion.majorVersion, 3)
    XCTAssertEqual(adSDKVersion.minorVersion, 21)
    XCTAssertEqual(adSDKVersion.patchVersion, 430)
  }

  func testAdSDKVersion_lessThanThreePartsInVersion_returnsZeros() {
    let molocoSdkVersionProviding = FakeMolocoSdkVersionProvider(sdkVersion: "3.21")
    MolocoMediationAdapter.setMolocoSdkVersionProvider(molocoSdkVersionProviding)

    let adSDKVersion = MolocoMediationAdapter.adSDKVersion()

    XCTAssertEqual(adSDKVersion.majorVersion, 0)
    XCTAssertEqual(adSDKVersion.minorVersion, 0)
    XCTAssertEqual(adSDKVersion.patchVersion, 0)
  }

  func testAdSDKVersion_unparsableVersionString_returnsZeros() {
    let molocoSdkVersionProviding = FakeMolocoSdkVersionProvider(sdkVersion: "a.b.c")
    MolocoMediationAdapter.setMolocoSdkVersionProvider(molocoSdkVersionProviding)

    let adSDKVersion = MolocoMediationAdapter.adSDKVersion()

    XCTAssertEqual(adSDKVersion.majorVersion, 0)
    XCTAssertEqual(adSDKVersion.minorVersion, 0)
    XCTAssertEqual(adSDKVersion.patchVersion, 0)
  }

  func testAdSDKVersion_partiallyUnparsableVersionString_returnsZeros() {
    let molocoSdkVersionProviding = FakeMolocoSdkVersionProvider(sdkVersion: "3.abc.1")
    MolocoMediationAdapter.setMolocoSdkVersionProvider(molocoSdkVersionProviding)

    let adSDKVersion = MolocoMediationAdapter.adSDKVersion()

    XCTAssertEqual(adSDKVersion.majorVersion, 0)
    XCTAssertEqual(adSDKVersion.minorVersion, 0)
    XCTAssertEqual(adSDKVersion.patchVersion, 0)
  }

  func test_setUp_ifChildTagIsTrue_setsAgeRestrictedUserTrue() {
    MobileAds.shared.requestConfiguration
      .tagForChildDirectedTreatment = true

    MolocoMediationAdapter.setUp(
      with: AUTKMediationServerConfiguration(), completionHandler: { error in })

    XCTAssertTrue(MolocoPrivacySettings.isAgeRestrictedUser)
  }

  func test_setUp_ifUserIsUnderAgeOfConsent_setsAgeRestrictedUserTrue() {
    MobileAds.shared.requestConfiguration
      .tagForUnderAgeOfConsent = true

    MolocoMediationAdapter.setUp(
      with: AUTKMediationServerConfiguration(), completionHandler: { error in })

    XCTAssertTrue(MolocoPrivacySettings.isAgeRestrictedUser)
  }

  func test_setUp_ifNeitherChildTagNorUnderAgeTagIsSet_doesNotSetAgeRestrictedUser() {
    let molocoAgeRestrictedSetter = FakeMolocoAgeRestrictedSetter()
    MolocoMediationAdapter.setMolocoAgeRestrictedSetter(molocoAgeRestrictedSetter)

    MolocoMediationAdapter.setUp(
      with: AUTKMediationServerConfiguration(), completionHandler: { error in })

    XCTAssertFalse(molocoAgeRestrictedSetter.setIsAgeRestrictedUserWasCalled)
  }

  func test_setUp_ifBothChildTagAndUnderAgeTagAreFalse_setsAgeRestrictedUserFalse() {
    MobileAds.shared.requestConfiguration
      .tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration
      .tagForUnderAgeOfConsent = false

    MolocoMediationAdapter.setUp(
      with: AUTKMediationServerConfiguration(), completionHandler: { error in })

    XCTAssertFalse(MolocoPrivacySettings.isAgeRestrictedUser)
  }
}
