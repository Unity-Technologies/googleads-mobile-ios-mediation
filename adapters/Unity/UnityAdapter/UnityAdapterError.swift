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
    /// Server configuration missing a required game ID.
    case serverConfigurationMissingGameId = 101
    
    /// The bidding signal collection request failed because the format is not supported.
    case unsupportedAdFormat = 102
    
    /// Invalid ad configuration for loading an ad.
    case invalidAdConfiguration = 103
    
    /// Fullscreen ad is not ready for presentation.
    case adNotReadyForPresentation = 104
  }
  
  nonisolated(unsafe) public static var errorDomain: String = "com.google.mediation.adapter.unity"
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
    func toAdapterError() -> UnityAdapterError {
        UnityAdapterError(errorCode: code, description: message)
    }
}
