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

#import "GADMUnityInterstitialMediationAdapterProxy.h"
#import "GADMAdapterUnityUtils.h"

@interface GADMUnityInterstitialMediationAdapterProxy ()
@property(nonatomic, weak) id<GADMediationInterstitialAd> ad;
@property(nonatomic, copy) GADMediationInterstitialLoadCompletionHandler loadCompletionHandler;
@end

@implementation GADMUnityInterstitialMediationAdapterProxy

- (nonnull instancetype)initWithAd:(id<GADMediationInterstitialAd>)ad
                 completionHandler:
                     (GADMediationInterstitialLoadCompletionHandler)completionHandler {
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

#pragma mark UADSInterstitialShowDelegate

- (void)showDidStart:(UADSInterstitialAd *_Nonnull)unityAd {
  [self.eventDelegate reportImpression];
}

- (void)showDidClick:(UADSInterstitialAd *_Nonnull)unityAd {
  [self.eventDelegate reportClick];
}

- (void)showDidComplete:(UADSInterstitialAd *_Nonnull)unityAd
                   with:(enum UADSShowFinishState)finishState {
  id<GADMediationAdEventDelegate> delegate = self.eventDelegate;
  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

- (void)showDidFail:(UADSInterstitialAd *_Nonnull)unityAd
              error:(id<UnityAdsError> _Nonnull)error {
  NSError *adapterError = GADMAdapterUnityErrorWithUnityAdsError(error);
  [self.eventDelegate didFailToPresentWithError:adapterError];
}

@end
