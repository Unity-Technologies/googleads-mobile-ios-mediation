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

#import "GADMUnityRewardedMediationAdapterProxy.h"
#import "GADMAdapterUnityUtils.h"

@interface GADMUnityRewardedMediationAdapterProxy ()
@property(nonatomic, weak) id<GADMediationRewardedAd> ad;
@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler loadCompletionHandler;
@end

@implementation GADMUnityRewardedMediationAdapterProxy

- (nonnull instancetype)initWithAd:(id<GADMediationRewardedAd>)ad
                 completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _ad = ad;
    _loadCompletionHandler = completionHandler;
  }
  return self;
}

- (void)adDidLoad {
  self.eventDelegate = self.loadCompletionHandler(self.ad, nil);
}

- (void)adDidFailToLoadWithError:(id<UnityAdsError>)error {
  NSError *adapterError = GADMAdapterUnityErrorWithUnityAdsError(error);
  self.loadCompletionHandler(self.ad, adapterError);
}

#pragma mark UADSRewardedShowDelegate

- (void)showDidStart:(UADSRewardedAd *_Nonnull)unityAd {
  [self.eventDelegate reportImpression];
  [(id<GADMediationRewardedAdEventDelegate>)self.eventDelegate didStartVideo];
}

- (void)showDidClick:(UADSRewardedAd *_Nonnull)unityAd {
  [self.eventDelegate reportClick];
}

- (void)showDidComplete:(UADSRewardedAd *_Nonnull)unityAd
                   with:(enum UADSShowFinishState)finishState {
  id<GADMediationRewardedAdEventDelegate> eventDelegate =
      (id<GADMediationRewardedAdEventDelegate>)self.eventDelegate;

  [eventDelegate didEndVideo];
  if (finishState == UADSShowFinishStateCompleted) {
    [eventDelegate didRewardUser];
  }

  [eventDelegate willDismissFullScreenView];
  [eventDelegate didDismissFullScreenView];
}

- (void)showDidFail:(UADSRewardedAd *_Nonnull)unityAd
              error:(id<UnityAdsError> _Nonnull)error {
  NSError *adapterError = GADMAdapterUnityErrorWithUnityAdsError(error);
  [self.eventDelegate didFailToPresentWithError:adapterError];
}

- (void)showDidReceiveReward:(UADSRewardedAd *_Nonnull)unityAd {
  // Reward is handled in showDidComplete: based on finish state
}

@end
