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
import UnityAds

public final class UnityAdapterError: Error, CustomNSError {
  
  public enum ErrorCode: Int, Sendable {
    // Raw values preserve the legacy ObjC `GADMAdapterUnityErrorCode` numeric
    // mapping (Public/Headers/GADMediationAdapterUnity.h) so that downstream
    // consumers filtering on the (domain, code) pair via GMA SDK's
    // GADAdNetworkResponseInfo.error / NSUnderlyingErrorKey surfaces continue
    // to see the historically-documented meanings.

    /// Server configuration missing a required game ID.
    /// Maps to legacy `GADMAdapterUnityErrorInvalidServerParameters` (101).
    case serverConfigurationMissingGameId = 101

    /// Fullscreen ad is not ready for presentation.
    /// Maps to legacy `GADMAdapterUnityErrorShowAdNotReady` (105).
    case adNotReadyForPresentation = 105

    /// The bidding signal collection request failed because the format is not supported.
    /// Maps to legacy `GADMAdapterUnityErrorAdUnsupportedAdFormat` (111).
    case unsupportedAdFormat = 111

    /// Invalid ad configuration for loading an ad.
    /// New code introduced in 4.19.0 — falls outside the legacy 101-111 range to
    /// avoid colliding with previously published meanings.
    case invalidAdConfiguration = 201
  }
  
  /// Domain for errors originated inside this adapter (invalid config, unsupported format, etc.).
  public static let errorDomain = "com.google.mediation.unity"

  /// Domain for errors originated inside the Unity Ads SDK and surfaced through the adapter.
  public static let sdkErrorDomain = "com.google.mediation.unitySDK"

  public var errorUserInfo: [String: Any] {
    [
      NSLocalizedDescriptionKey: description
    ]
  }

  public let errorCode: Int
  public let description: String

  init(errorCode: Int, description: String) {
    self.errorCode = errorCode
    self.description = description
  }

  init(errorCode: ErrorCode, description: String) {
    self.errorCode = errorCode.rawValue
    self.description = description
  }
}

// MARK: - UnityAdsError Extension

extension UnityAdsError {
    /// Bridges a Unity Ads SDK error to an `NSError` in the SDK-specific domain
    /// (`com.google.mediation.unitySDK`) so it stays distinguishable from adapter-originated errors.
    func toNSError() -> NSError {
        NSError(
            domain: UnityAdapterError.sdkErrorDomain,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
