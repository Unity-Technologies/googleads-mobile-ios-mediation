// Copyright 2019 Google LLC
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

#import "GADMAdapterFyberUtils.h"
#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberExtras.h"

void GADMAdapterFyberMutableArrayAddObject(NSMutableArray *_Nullable array,
                                           NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterFyberMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterFyberErrorWithCodeAndDescription(GADMAdapterFyberErrorCode code,
                                                              NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterFyberErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

GADVersionNumber GADMAdapterFyberVersionFromString(NSString *_Nonnull versionString) {
  NSArray<NSString *> *versionAsArray = [versionString componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};

  if (versionAsArray.count >= 3) {
    version.majorVersion = versionAsArray[0].integerValue;
    version.minorVersion = versionAsArray[1].integerValue;
    version.patchVersion = versionAsArray[2].integerValue;

    if (versionAsArray.count >= 4) {
      version.patchVersion = version.patchVersion * 100 + versionAsArray[3].integerValue;
    }
  }
  return version;
}

IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(
    NSString *_Nonnull spotID, GADMediationAdConfiguration *_Nonnull adConfiguration) {
  GADMAdapterFyberExtras *extras = adConfiguration.extras;

  IASDKCore.sharedInstance.userData = extras.userData;
  IASDKCore.sharedInstance.muteAudio = extras.muteAudio;

  IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder> _Nonnull builder) {
    builder.useSecureConnections = NO;
    builder.spotID = spotID;
    builder.timeout = 10;
  }];

  return request;
}

IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfiguration) {
  GADMAdapterFyberExtras *extras = adConfiguration.extras;

  IASDKCore.sharedInstance.userData = extras.userData;
  IASDKCore.sharedInstance.muteAudio = extras.muteAudio;

  IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder> _Nonnull builder) {
    builder.useSecureConnections = NO;
    builder.timeout = 10;
  }];

  return request;
}

void GADMAdapterFyberInitializeWithAppId(
    NSString *_Nonnull appID, GADMAdapterFyberInitCompletionHandler _Nonnull completionHandler) {
  if (IASDKCore.sharedInstance.isInitialised) {
    completionHandler(nil);
    return;
  }

  if (!appID.length) {
    NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
        GADMAdapterFyberErrorInvalidServerParameters, @"Missing or invalid Application ID.");
    GADMAdapterFyberLog(@"%@", error.localizedDescription);
    completionHandler(error);
    return;
  }

  GADMAdapterFyberLog(@"Initializing DT Exchange SDK with application ID: %@", appID);
  [IASDKCore.sharedInstance initWithAppID:appID
                          completionBlock:^(BOOL success, NSError *_Nullable error) {
                            completionHandler(error);
                          }
                          completionQueue:nil];
}
