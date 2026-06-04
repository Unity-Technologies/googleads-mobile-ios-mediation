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
import GoogleMobileAds

final class Util {

  private enum MediationConfigurationSettingKey: String {
    case gameId = "gameId"
    case placementId = "zoneId"
  }

  static func log(_ message: String) {
    #if DEBUG
      print("UnityAdapter: \(message)")
    #endif
  }

  static func gameId(from config: MediationServerConfiguration) throws(UnityAdapterError)
    -> String
  {
    let gameIdSet = Set<String>(
      config.credentials.compactMap {
        $0.settings[MediationConfigurationSettingKey.gameId.rawValue] as? String
      })

    guard let gameId = gameIdSet.randomElement() else {
      throw UnityAdapterError(
        errorCode: .serverConfigurationMissingGameId,
        description: "The server configuration is missing a game ID.")
    }

    if gameIdSet.count > 1 {
      log("Found more than one game ID in the server configuration. Using \(gameId)")
    }

    return gameId
  }

  static func adFormat(
    from params: RTBRequestParameters
  ) throws(UnityAdapterError) -> AdFormat {
    guard let adFormat = params.configuration.credentials.first?.format else {
      throw UnityAdapterError(
        errorCode: .unsupportedAdFormat,
        description:
          "Failed to collect signals because the configuration is missing the credentials.")
    }

    return adFormat
  }

}
