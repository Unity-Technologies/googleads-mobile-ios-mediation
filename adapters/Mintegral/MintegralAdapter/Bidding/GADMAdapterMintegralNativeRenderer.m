// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterMintegralNativeRenderer.h"
#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"
#import "GADMAdapterMintegralExtras.h"

#import <MTGSDK/MTGSDK.h>
#import <MTGSDK/MTGBidNativeAdManager.h>
#include <stdatomic.h>

@interface GADMAdapterMintegralNativeRenderer ()
<MTGBidNativeAdManagerDelegate,
GADMediationNativeAd,
MTGMediaViewDelegate>

@end

@implementation GADMAdapterMintegralNativeRenderer {
    // The completion handler to call when the ad loading succeeds or fails.
    GADMediationNativeLoadCompletionHandler _adLoadCompletionHandler;
    
    /// Holds the state for impression being logged.
    atomic_flag _impressionLogged;
    
    //The Mintegral native ad
    MTGBidNativeAdManager *_nativeManager;
    
    //The Mintegral media view
    MTGMediaView *_mediaView;
        
    // An ad event delegate to invoke when ad rendering events occur.
    __weak id<GADMediationNativeAdEventDelegate> _adEventDelegate;

    //The mintegral ad unitId
    NSString *_unitId;
    
    MTGCampaign *_campaign;
    
    GADNativeAdImage *_icon;
    
    NSArray<GADNativeAdImage *> *_images;
}

- (void)renderNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
    // Store the ad config and completion handler for later use.
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];
    _adLoadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(
        _Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationNativeAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };
    
    NSString *unitId = adConfiguration.credentials.settings[GADMAdapterMintegralAdUnitID];
    NSString *placementId = adConfiguration.credentials.settings[GADMAdapterMintegralPlacementID];
    UIViewController *rootViewController = adConfiguration.topViewController;
    
    // if the unitId is nil.
    if ([GADMAdapterMintegralUtils isEmpty:unitId]) {
        NSError *error =
        GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorInvalidServerParameters, @"Unit ID cannot be nil.");
        _adLoadCompletionHandler(nil, error);
        return;
    }
    
    if ([GADMAdapterMintegralUtils isEmpty:adConfiguration.bidResponse]) {
        NSError *error =
        GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorInvalidServerParameters, @"bid token cannot be nil.");
        _adLoadCompletionHandler(nil, error);
        return;
    }
    
    
    _nativeManager = [[MTGBidNativeAdManager alloc]initWithPlacementId:placementId unitID:unitId presentingViewController:rootViewController];
    _nativeManager.delegate = self;
    [_nativeManager loadWithBidToken:adConfiguration.bidResponse];
}

- (MTGMediaView *)createMediaView {
    
    if (_mediaView) {
        return _mediaView;
    }
    
    _mediaView= [[MTGMediaView alloc] initWithFrame:CGRectZero];
    _mediaView.delegate = self;
    return _mediaView;
}

#pragma mark - MTGBidNativeAdManagerDelegate
- (void)nativeAdsLoaded:(nullable NSArray *)nativeAds bidNativeManager:(nonnull MTGBidNativeAdManager *)bidNativeManager {
    
    if ([nativeAds isKindOfClass:NSArray.class] && nativeAds.count > 0) {
        _campaign = nativeAds.firstObject;
        
        if (![GADMAdapterMintegralUtils isEmpty:_campaign.iconUrl]) {
            _icon = [GADMAdapterMintegralUtils imageWithUrlString:_campaign.iconUrl];
        }
        
        if (![GADMAdapterMintegralUtils isEmpty:_campaign.imageUrl]) {
            GADNativeAdImage *image = [GADMAdapterMintegralUtils imageWithUrlString:_campaign.imageUrl];
            if (image) {
                _images = @[image];
            }
        }
        
        [self createMediaView];
        
        if (_adLoadCompletionHandler) {
            _adEventDelegate = _adLoadCompletionHandler(self,nil);
        }

    }else{
        NSError *error =
        GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorAdNotFill, @"Native ad not fill");
        if (_adLoadCompletionHandler) {
            _adLoadCompletionHandler(nil,error);
        }
    }
}

- (void)nativeAdsFailedToLoadWithError:(nonnull NSError *)error bidNativeManager:(nonnull MTGBidNativeAdManager *)bidNativeManager {
    if (_adLoadCompletionHandler) {
        _adLoadCompletionHandler(nil,error);
    }
}

#pragma mark - MTGBidNativeAdManagerDelegate
- (void)nativeAdDidClick:(nonnull MTGCampaign *)nativeAd bidNativeManager:(nonnull MTGBidNativeAdManager *)bidNativeManager {
    [_adEventDelegate reportClick];
}

- (void)nativeAdImpressionWithType:(MTGAdSourceType)type bidNativeManager:(nonnull MTGBidNativeAdManager *)bidNativeManager {
    [_adEventDelegate reportImpression];
}

#pragma mark -MTGMediaViewDelegate
- (void)MTGMediaViewWillEnterFullscreen:(MTGMediaView *)mediaView {
    [_adEventDelegate willPresentFullScreenView];
}

- (void)MTGMediaViewDidExitFullscreen:(MTGMediaView *)mediaView {
    [_adEventDelegate didDismissFullScreenView];
}

- (void)MTGMediaViewVideoDidStart:(MTGMediaView *)mediaView {
    [_adEventDelegate didPlayVideo];
}

- (void)MTGMediaViewVideoPlayCompleted:(MTGMediaView *)mediaView {
    [_adEventDelegate didEndVideo];
}

- (void)nativeAdDidClick:(nonnull MTGCampaign *)nativeAd mediaView:(MTGMediaView *)mediaView {
    [_adEventDelegate reportClick];
}

- (void)nativeAdImpressionWithType:(MTGAdSourceType)type mediaView:(MTGMediaView *)mediaView {
    [_adEventDelegate reportImpression];
}

#pragma mark -GADMediatedUnifiedNativeAd
- (NSString *)headline {
    return _campaign.appName;
}

- (NSArray *)images {
    return _images;
}

- (NSString *)body {
    return _campaign.appDesc;
}

- (GADNativeAdImage *)icon {
    return _icon;
}

- (NSString *)callToAction {
    return _campaign.adCall;
}

- (NSDecimalNumber *)starRating {
    
    NSString *star = [NSString stringWithFormat:@"%@",[_campaign valueForKey:@"star"]];
    return [NSDecimalNumber decimalNumberWithString:star];
}

- (NSString *)store {
    
    return @"";
}

- (NSString *)price {
    return @"";
}

-(NSString *)advertiser{
    return @"";
}

- (NSDictionary *)extraAssets {
    return nil;
}

- (BOOL)hasVideoContent {
    return YES;
}

-  (UIView *)mediaView{
    [_mediaView setMediaSourceWithCampaign:_campaign unitId:_unitId];
    return _mediaView;
}

#pragma mark - GADMediationNativeAd
- (BOOL)handlesUserClicks{
    return YES;
}

- (BOOL)handlesUserImpressions{
    return YES;
}

#pragma mark - GADMediatedNativeAdDelegate implementation
-(void)didRenderInView:(UIView *)view clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)clickableAssetViews nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)nonclickableAssetViews viewController:(UIViewController *)viewController{

    for (UIView *subView in view.subviews) {
        subView.userInteractionEnabled = NO;
    }

    [_nativeManager registerViewForInteraction:view withCampaign:_campaign];

}
- (void)didRecordImpression {
    ;
}


-(void)didRecordClickOnAssetWithName:(GADNativeAssetIdentifier)assetName view:(UIView *)view viewController:(UIViewController *)viewController{
    ;
}

- (void)didUntrackView:(nullable UIView *)view {
    ;
}

@end
