// Copyright 2021 Google LLC.
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

#import "GADUnityRouter.h"
#import <UnityAds/UnityAds.h>
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"

typedef void (^InitCompletionHandler)(NSError *);

@interface GADUnityRouter ()
@property(nonatomic, strong) NSMutableArray *completionBlocks;
@end

@implementation GADUnityRouter

+ (GADUnityRouter *)sharedRouter {
  static GADUnityRouter *sharedRouter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedRouter = [[GADUnityRouter alloc] init];
    sharedRouter.completionBlocks = [NSMutableArray array];
  });
  return sharedRouter;
}

- (void)sdkInitializeWithGameId:(NSString *)gameId
          withCompletionHandler:(InitCompletionHandler)complete {
  @synchronized(self.completionBlocks) {
    if ([UnityAds isInitialized]) {
      if (complete != nil) {
        complete(nil);
      }
      return;
    }

    if (complete != nil) {
      GADMAdapterUnityMutableArrayAddObject(self.completionBlocks, complete);
    }
  }

  static dispatch_once_t unityInitToken;
  dispatch_once(&unityInitToken, ^{
    UADSMediationInfo *mediationInfo =
    [[UADSMediationInfo alloc] initWithName:GADMAdapterUnityMediationNetworkName
                                    version:mediationVersion()
                             adapterVersion:GADMAdapterUnityVersion];
    
    UADSInitializationConfiguration *config =
    [[[[UADSInitializationConfigurationBuilder alloc] initWithGameId:gameId]
      withTestMode:GADMediationAdapterUnity.testMode]
     withMediationInfo:mediationInfo]
      .build;
    
      [UnityAds initialize:config
                completion:^(id<UnityAdsError> _Nullable error) {
      if (error) {
        NSError *adapterError = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdInitializationFailure, error.message);
        [[GADUnityRouter sharedRouter] callCompletionBlocks:adapterError];
      } else {
        [[GADUnityRouter sharedRouter] callCompletionBlocks:nil];
      }
    }];
  });
}

- (void)callCompletionBlocks:(NSError *)error {
  @synchronized(self.completionBlocks) {
    for (InitCompletionHandler block in self.completionBlocks) {
      block(error);
    }
    [self.completionBlocks removeAllObjects];
  }
}

@end
