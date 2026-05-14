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

#import "GADMediationAdapterUnity.h"
#import <UnityAds/UnityAds.h>
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"
#import "GADMUnityBannerMediationAdapterProxy.h"
#import "GADMUnityInterstitialMediationAdapterProxy.h"
#import "GADMUnityRewardedMediationAdapterProxy.h"
#import "GADMediationConfigurationSettings.h"
#import "GADUnityRouter.h"
#import "NSErrorUnity.h"

@interface GADMediationAdapterUnity () <GADMediationRewardedAd,
GADMediationInterstitialAd,
GADMediationBannerAd>
@property(nonatomic, strong) NSString *placementId;
@property(nonatomic, strong) GADUnityBaseMediationAdapterProxy *adapterProxy;
@property(nonatomic, strong) UADSBannerAd *bannerAd;
@property(nonatomic, strong) UADSInterstitialAd *interstitialAd;
@property(nonatomic, strong) UADSRewardedAd *rewardedAd;
@property(nonatomic, strong, nullable) NSData *watermarkForFullScreenAd;
@end

@implementation GADMediationAdapterUnity

static BOOL _isTestMode = NO;

// Called on Admob->init
+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSSet *gameIDs = configuration.gameIds;
  if (!gameIDs.count) {
    completionHandler([NSError noValidGameId]);
    return;
  }
  
  NSString *gameID = [gameIDs anyObject];
  if (gameIDs.count > 1) {
    NSLog(@"Found the following game IDs: %@. "
          @"Please remove any game IDs you are not using from the AdMob UI.",
          gameIDs);
    NSLog(@"Initializing Unity Ads SDK with the game ID %@.", gameID);
  }
  
  [GADMediationAdapterUnity updatePrivacyPreferences];
  
  [[GADUnityRouter sharedRouter] sdkInitializeWithGameId:gameID
                                   withCompletionHandler:completionHandler];
}

+ (GADVersionNumber)adSDKVersion {
  return extractVersionFromString([UnityAds getVersion]);
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

+ (GADVersionNumber)adapterVersion {
  return extractVersionFromString(GADMAdapterUnityVersion);
}

+ (UADSMediationInfo *)mediationInfo {
  return [[UADSMediationInfo alloc] initWithName:GADMAdapterUnityMediationNetworkName
                                         version:mediationVersion()
                                  adapterVersion:GADMAdapterUnityVersion];
}

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  GADAdFormat adFormat = params.configuration.credentials.firstObject.format;
  if (adFormat == GADAdFormatBanner || adFormat == GADAdFormatInterstitial ||
      adFormat == GADAdFormatRewarded || adFormat == GADAdFormatRewardedInterstitial) {
    UADSAdFormat format = UADSAdFormatInterstitial;
    if (adFormat == GADAdFormatBanner) {
      format = UADSAdFormatBanner;
    } else if (adFormat == GADAdFormatRewarded || adFormat == GADAdFormatRewardedInterstitial) {
      format = UADSAdFormatRewarded;
    }
    
    UADSTokenConfigurationBuilder *builder =
    [[[UADSTokenConfigurationBuilder alloc] initWithAdFormat:format]
     withMediationInfo:[GADMediationAdapterUnity mediationInfo]];
    
    UADSTokenConfiguration *config = [builder build];
    
    [UnityAds getToken:config
            completion:^(NSString *_Nullable token) {
      NSString *unityToken = token ?: @"";
      completionHandler(unityToken, nil);
    }];
  } else {
    completionHandler(
                      nil, GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdUnsupportedAdFormat,
                                                                       @"Unsupported ad format."));
  }
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
(GADMediationRewardedLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity updatePrivacyPreferences];
  GADMUnityRewardedMediationAdapterProxy *proxy =
  [[GADMUnityRewardedMediationAdapterProxy alloc] initWithAd:self
                                           completionHandler:completionHandler];
  self.adapterProxy = proxy;
  
  GADMediationAdapterUnity *__weak weakself = self;
  [self initializeWithConfiguration:adConfiguration
                  completionHandler:^(NSError *_Nullable error) {
    GADMediationAdapterUnity *strongSelf = weakself;
    if (!strongSelf) {
      return;
    }
    if (error) {
      completionHandler(nil, error);
      return;
    }
    
    [strongSelf loadRewardedAdWithConfiguration:adConfiguration proxy:proxy];
  }];
}

- (void)loadInterstitialForAdConfiguration:
(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
(GADMediationInterstitialLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity updatePrivacyPreferences];
  GADMUnityInterstitialMediationAdapterProxy *proxy =
  [[GADMUnityInterstitialMediationAdapterProxy alloc] initWithAd:self
                                               completionHandler:completionHandler];
  self.adapterProxy = proxy;
  
  GADMediationAdapterUnity *__weak weakself = self;
  [self initializeWithConfiguration:adConfiguration
                  completionHandler:^(NSError *_Nullable error) {
    GADMediationAdapterUnity *strongSelf = weakself;
    if (!strongSelf) {
      return;
    }
    if (error) {
      completionHandler(nil, error);
      return;
    }
    
    [strongSelf loadInterstitialAdWithConfiguration:adConfiguration proxy:proxy];
  }];
}

- (void)loadRewardedAdWithConfiguration:(GADMediationAdConfiguration *)adConfiguration
                                  proxy:(GADMUnityRewardedMediationAdapterProxy *)proxy {
  self.placementId = adConfiguration.placementId;
  self.watermarkForFullScreenAd = adConfiguration.watermark;
  
  UADSLoadConfigurationBuilder *builder =
  [[UADSLoadConfigurationBuilder alloc] initWithPlacementId:self.placementId];
  
  if (adConfiguration.bidResponse) {
    builder = [builder withAdMarkup:adConfiguration.bidResponse];
  }
  builder = [builder withMediationInfo:[GADMediationAdapterUnity mediationInfo]];
  
  UADSLoadConfiguration *loadConfig = [builder build];
  
  GADMediationAdapterUnity *__weak weakself = self;
  [UADSRewardedAd load:loadConfig
            completion:^(UADSRewardedAd *_Nullable rewardedAd, id<UnityAdsError> _Nullable error) {
    GADMediationAdapterUnity *strongSelf = weakself;
    if (!strongSelf) {
      return;
    }
    if (error) {
      [proxy adDidFailToLoadWithError:error];
    } else {
      strongSelf.rewardedAd = rewardedAd;
      [proxy adDidLoad];
    }
  }];
}

- (void)loadInterstitialAdWithConfiguration:(GADMediationAdConfiguration *)adConfiguration
                                      proxy:(GADMUnityInterstitialMediationAdapterProxy *)proxy {
  self.placementId = adConfiguration.placementId;
  self.watermarkForFullScreenAd = adConfiguration.watermark;
  
  UADSLoadConfigurationBuilder *builder =
  [[UADSLoadConfigurationBuilder alloc] initWithPlacementId:self.placementId];
  
  if (adConfiguration.bidResponse) {
    builder = [builder withAdMarkup:adConfiguration.bidResponse];
  }
  builder = [builder withMediationInfo:[GADMediationAdapterUnity mediationInfo]];
  
  UADSLoadConfiguration *loadConfig = [builder build];
  
  GADMediationAdapterUnity *__weak weakself = self;
  [UADSInterstitialAd
   load:loadConfig
   completion:^(UADSInterstitialAd *_Nullable interstitialAd, id<UnityAdsError> _Nullable error) {
    GADMediationAdapterUnity *strongSelf = weakself;
    if (!strongSelf) {
      return;
    }
    if (error) {
      [proxy adDidFailToLoadWithError:error];
    } else {
      strongSelf.interstitialAd = interstitialAd;
      [proxy adDidLoad];
    }
  }];
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity updatePrivacyPreferences];
  GADMediationAdapterUnity *__weak weakself = self;
  [self initializeWithConfiguration:adConfiguration
                  completionHandler:^(NSError *_Nullable error) {
    GADMediationAdapterUnity *strongSelf = weakself;
    if (!strongSelf) {
      return;
    }
    if (error) {
      completionHandler(nil, error);
      return;
    }
    
    strongSelf.placementId = adConfiguration.placementId;
    GADMUnityBannerMediationAdapterProxy *proxy =
    [[GADMUnityBannerMediationAdapterProxy alloc]
     initWithAd:strongSelf
     requestedAdSize:adConfiguration.adSize
     forBidding:adConfiguration.bidResponse != nil
     completionHandler:completionHandler];
    strongSelf.adapterProxy = proxy;
    
    CGSize bannerSize = adConfiguration.adSize.size;
    UADSBannerLoadConfigurationBuilder *builder =
    [[UADSBannerLoadConfigurationBuilder alloc]
     initWithPlacementId:strongSelf.placementId
     bannerSize:bannerSize
     delegate:proxy];
    
    if (adConfiguration.bidResponse) {
      builder = [builder withAdMarkup:adConfiguration.bidResponse];
    }
    builder = [builder withMediationInfo:[GADMediationAdapterUnity mediationInfo]];
    NSData *watermark = adConfiguration.watermark;
    if (watermark != nil) {
      NSString *watermarkString = [watermark base64EncodedStringWithOptions:0];
      builder = [builder withExtras:@{GADMAdapterUnityWatermarkKey: watermarkString}];
    }
    
    UADSBannerLoadConfiguration *loadConfig = [builder build];
    
    [UADSBannerAd
     load:loadConfig
     completion:^(UADSBannerAd *_Nullable bannerAd,
                  id<UnityAdsError> _Nullable loadError) {
      if (loadError) {
        [proxy adDidFailToLoadWithError:loadError];
      } else {
        strongSelf.bannerAd = bannerAd;
        [proxy adDidLoadWithBannerView:bannerAd.view];
      }
    }];
  }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  UADSShowConfigurationBuilder *builder = [[UADSShowConfigurationBuilder alloc] init];
  builder = [builder withViewController:viewController];
  
  if (self.watermarkForFullScreenAd != nil) {
    NSString *watermarkString = [self.watermarkForFullScreenAd base64EncodedStringWithOptions:0];
    builder = [builder withExtras:@{GADMAdapterUnityWatermarkKey: watermarkString}];
  }
  
  UADSShowConfiguration *showConfig = [builder build];
  
  [self.adapterProxy.eventDelegate willPresentFullScreenView];
  
  if (self.rewardedAd) {
    [self.rewardedAd
     show:showConfig
     delegate:(id<UADSRewardedShowDelegate>)self.adapterProxy];
  } else if (self.interstitialAd) {
    [self.interstitialAd
     show:showConfig
     delegate:(id<UADSInterstitialShowDelegate>)self.adapterProxy];
  }
}

- (void)initializeWithConfiguration:(GADMediationAdConfiguration *)adConfiguration
                  completionHandler:(void (^)(NSError *_Nullable error))completion {
  [[GADUnityRouter sharedRouter] sdkInitializeWithGameId:adConfiguration.gameId
                                   withCompletionHandler:completion];
}

#pragma mark Utility Methods

/// Updates privacy settings using the new Unity Ads API based on Google Mobile Ads'
/// tagForChildDirectedTreatment and tagForUnderAgeOfConsent.
+ (void)updatePrivacyPreferences {
  NSNumber *tagForChildDirectedTreatment =
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  NSNumber *tagForUnderAgeOfConsent =
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent;
  
  BOOL isChildDirected = [tagForChildDirectedTreatment isEqual:@YES];
  BOOL isUnderAge = [tagForUnderAgeOfConsent isEqual:@YES];
  BOOL isNotChildDirected = [tagForChildDirectedTreatment isEqual:@NO];
  BOOL isNotUnderAge = [tagForUnderAgeOfConsent isEqual:@NO];
  
  // If at least one signal indicates adult, and other api does not signal child, we are adult for
  // this session - allow behavioral ads
  if (!isChildDirected && !isUnderAge && (isNotChildDirected || isNotUnderAge)) {
    [UnityAds setNonBehavioral:NO];
  }
  // If there is any child signal, conflicts between api's, or both unspecified, we treat them as
  // a child - use non-behavioral ads
  else {
    [UnityAds setNonBehavioral:YES];
  }
}

+ (BOOL)testMode {
  return _isTestMode;
}

+ (void)setTestMode:(BOOL)testMode {
  GADMUnityLog(@"Updating test mode flag to `%@`", (testMode ? @"YES" : @"NO"));
  _isTestMode = testMode;
}

#pragma mark GADMediationBannerAd

- (UIView *)view {
  return self.bannerAd.view;
}

@end
