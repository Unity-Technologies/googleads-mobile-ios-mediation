// Copyright 2020 Google LLC.
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

#import "GADMAdapterUnityUtils.h"
#import "GADMAdapterUnityConstants.h"

void GADMAdapterUnityMutableArrayAddObject(NSMutableArray *_Nullable array,
                                           NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterUnityMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorCode code,
                                                              NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterUnityErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

NSError *_Nonnull GADMAdapterUnityErrorWithUnityAdsError(id<UnityAdsError> _Nonnull error) {
  NSString *message = error.message ?: @"Unknown Unity Ads error";
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : message, NSLocalizedFailureReasonErrorKey : message};
  return [NSError errorWithDomain:GADMAdapterUnitySDKErrorDomain
                             code:error.code
                         userInfo:userInfo];
}

GADVersionNumber extractVersionFromString(NSString *_Nonnull string) {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [string componentsSeparatedByString:@"."];
  if (components.count >= 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    NSInteger patch = components[2].integerValue;
    version.patchVersion = components.count == 4 ? patch * 100 + components[3].integerValue : patch;
  }
  return version;
}

NSString *_Nonnull mediationVersion(void) {
    return [NSString stringWithFormat:@"%ld.%ld.%ld",
            GADMobileAds.sharedInstance.versionNumber.majorVersion,
            GADMobileAds.sharedInstance.versionNumber.minorVersion,
            GADMobileAds.sharedInstance.versionNumber.patchVersion];
}
