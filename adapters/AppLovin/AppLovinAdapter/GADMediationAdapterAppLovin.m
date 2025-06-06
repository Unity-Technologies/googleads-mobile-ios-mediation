// Copyright 2018 Google LLC
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

#import "GADMediationAdapterAppLovin.h"

#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinInitializer.h"
#import "GADMAdapterAppLovinRewardedRenderer.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMRTBAdapterAppLovinInterstitialRenderer.h"

@implementation GADMediationAdapterAppLovin {
  /// AppLovin interstitial ad wrapper.
  GADMRTBAdapterAppLovinInterstitialRenderer *_interstitialRenderer;

  /// AppLovin rewarded ad wrapper.
  GADMAdapterAppLovinRewardedRenderer *_rewardedRenderer;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if ([GADMAdapterAppLovinUtils isChildUser]) {
    completionHandler(GADMAdapterAppLovinChildUserError());
    return;
  }

  // Compile all the SDK keys that should be initialized.
  NSMutableSet<NSString *> *SDKKeys = [NSMutableSet set];

  // Compile SDK keys from configuration credentials.
  for (GADMediationCredentials *credentials in configuration.credentials) {
    NSString *SDKKey = credentials.settings[GADMAdapterAppLovinSDKKey];
    if ([GADMAdapterAppLovinUtils isValidAppLovinSDKKey:SDKKey]) {
      GADMAdapterAppLovinMutableSetAddObject(SDKKeys, SDKKey);
    }
  }

  if (!SDKKeys.count) {
    NSString *errorString = @"No SDK keys are found. Please add valid SDK keys in the AdMob UI.";
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorMissingSDKKey, errorString);
    completionHandler(error);
    return;
  }

  NSString *SDKKey = [SDKKeys anyObject];
  if (SDKKeys.count > 1) {
    [GADMAdapterAppLovinUtils log:@"More than one SDK key was found. The adapter will use %@ to "
                                  @"initialize the AppLovin SDK.",
                                  SDKKey];
  }

  [GADMAdapterAppLovinUtils
      log:@"Found %lu SDK keys. Please remove any SDK keys you are not using from the AdMob UI.",
          (unsigned long)SDKKeys.count];
  [GADMAdapterAppLovinInitializer initializeWithSDKKey:SDKKey
                                     completionHandler:^(void) {
                                       completionHandler(nil);
                                     }];
}

+ (GADVersionNumber)adapterVersion {
  NSString *versionString = GADMAdapterAppLovinAdapterVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  [GADMAdapterAppLovinUtils
      log:[NSString stringWithFormat:@"AppLovin adapter version: %@", versionString]];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = ALSdk.version;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  [GADMAdapterAppLovinUtils
      log:[NSString stringWithFormat:@"AppLovin SDK version: %@", versionString]];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
                             (nonnull GADRTBSignalCompletionHandler)completionHandler {
  if ([GADMAdapterAppLovinUtils isChildUser]) {
    completionHandler(nil, GADMAdapterAppLovinChildUserError());
    return;
  }

  [GADMAdapterAppLovinUtils log:@"AppLovin adapter collecting signals."];
  // Check if supported ad format.
  if (params.configuration.credentials.firstObject.format == GADAdFormatNative) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorUnsupportedAdFormat,
        @"Requested to collect signal for unsupported native ad format. Ignoring...");
    completionHandler(nil, error);
    return;
  }

  if (!ALSdk.shared) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorAppLovinSDKNotInitialized,
        @"Failed to retrieve ALSdk shared instance.");
    completionHandler(nil, error);
    return;
  }

  [ALSdk.shared.adService collectBidTokenWithCompletion:^(NSString *_Nullable bidToken,
                                                          NSString *_Nullable errorMessage) {
    if (errorMessage) {
      NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
          GADMAdapterAppLovinErrorFailedToReturnBidToken, errorMessage);
      completionHandler(nil, error);
      return;
    }
    if (bidToken.length > 0) {
      [GADMAdapterAppLovinUtils log:@"Generated bid token %@.", bidToken];
      completionHandler(bidToken, nil);
    } else {
      NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
          GADMAdapterAppLovinErrorEmptyBidToken, @"Bid token is empty.");
      completionHandler(nil, error);
    }
  }];
}

#pragma mark - GADMediationAdapter load Ad

- (void)loadInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                               completionHandler {
  if ([GADMAdapterAppLovinUtils isChildUser]) {
    completionHandler(nil, GADMAdapterAppLovinChildUserError());
    return;
  }

  _interstitialRenderer = [[GADMRTBAdapterAppLovinInterstitialRenderer alloc]
      initWithAdConfiguration:adConfiguration
            completionHandler:completionHandler];
  [_interstitialRenderer loadAd];
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  if ([GADMAdapterAppLovinUtils isChildUser]) {
    completionHandler(nil, GADMAdapterAppLovinChildUserError());
    return;
  }

  __weak GADMediationAdapterAppLovin *weakSelf = self;
  NSString *SDKKey =
      [GADMAdapterAppLovinUtils retrieveSDKKeyFromCredentials:adConfiguration.credentials.settings];
  [GADMAdapterAppLovinInitializer initializeWithSDKKey:SDKKey
                                     completionHandler:^(void) {
                                       GADMediationAdapterAppLovin *strongSelf = weakSelf;
                                       if (!strongSelf) {
                                         return;
                                       }

                                       strongSelf->_rewardedRenderer =
                                           [[GADMAdapterAppLovinRewardedRenderer alloc]
                                               initWithAdConfiguration:adConfiguration
                                                     completionHandler:completionHandler];
                                       [strongSelf->_rewardedRenderer requestRewardedAd];
                                     }];
}

@end
