// Copyright 2023 Google LLC.
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

#import "AUTUnityTestCase.h"

#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

@implementation AUTUnityTestCase

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterUnity alloc] init];
  _unityAdsClassMock = OCMClassMock([UnityAds class]);
  _interstitialAdClassMock = OCMClassMock([UADSInterstitialAd class]);
  _rewardedAdClassMock = OCMClassMock([UADSRewardedAd class]);
  _bannerAdClassMock = OCMClassMock([UADSBannerAd class]);
  
  OCMStub(ClassMethod([_unityAdsClassMock initialize:OCMOCK_ANY  completion:OCMOCK_ANY]))
    .andDo(^(NSInvocation *invocation) {
      __unsafe_unretained void (^completionHandler)(id<UnityAdsError> *_Nullable error);
      [invocation getArgument:&completionHandler atIndex:3];
      completionHandler(nil);
    });
}

@end
