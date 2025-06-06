#import "GADMediationAdapterMintegral.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>

#import "GADMediationAdapterMintegralConstants.h"

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kPlacementID = @"12345";
static NSString *const kUnitID = @"67890";

@interface AUTMintegralWaterfallBannerAdTests : XCTestCase
@end

@implementation AUTMintegralWaterfallBannerAdTests {
  /// An adapter instance that is used to test loading an app open ad.
  GADMediationAdapterMintegral *_adapter;

  /// A mock instance of MTGSplashAD.
  id _bannerAdMock;

  /// A banner ad delegate.
  __block id<MTGBannerAdViewDelegate> _bannerAdDelegate;

  /// The size passed through to banner initialization.
  CGSize _bannerSize;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterMintegral alloc] init];
  _bannerAdMock = OCMClassMock([MTGBannerAdView class]);
  OCMStub([_bannerAdMock alloc]).andReturn(_bannerAdMock);
  OCMStub([_bannerAdMock initBannerAdViewWithAdSize:CGSizeMake(0, 0)
                                        placementId:kPlacementID
                                             unitId:kUnitID
                                 rootViewController:OCMOCK_ANY])
      .ignoringNonObjectArgs()
      .andReturn(_bannerAdMock);

  // Whenever a delegate is set, save it and assert that it has the appropriate delegate type.
  OCMStub([_bannerAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_bannerAdDelegate = obj;
                           return [obj conformsToProtocol:@protocol(MTGBannerAdViewDelegate)];
                         }]]);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  [super tearDown];
}

- (nonnull AUTKMediationBannerAdEventDelegate *)loadAdWithSize:(CGSize)size {
  // All banners must have refresh disabled.
  OCMExpect([_bannerAdMock setAutoRefreshTime:0]);

  NSData *watermarkData = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_bannerAdMock loadBannerAd]).andDo(^(NSInvocation *invocation) {
    [self->_bannerAdDelegate adViewLoadSuccess:self->_bannerAdMock];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(size);
  configuration.watermark = watermarkData;

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(_bannerAdDelegate);

  [_bannerAdMock verify];
  return eventDelegate;
}

- (void)testLoadBannerSuccess {
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadBannerSuccessWithCOPPAEnabled {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadBannerSuccessWithCOPPADisabled {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolNo);
}

- (void)testBannerDelegateCallbacks {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadAdWithSize:CGSizeMake(320, 50)];

  XCTAssertNotNil(_bannerAdDelegate);

  [_bannerAdDelegate adViewWillLogImpression:_bannerAdMock];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);

  [_bannerAdDelegate adViewDidClicked:_bannerAdMock];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);

  [_bannerAdDelegate adViewWillOpenFullScreen:_bannerAdMock];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);

  [_bannerAdDelegate adViewCloseFullScreen:_bannerAdMock];
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
}

// Ensures that no crashes occur for callbacks that are unused by GMA.
- (void)testBannerDelegateCallbacksNotImplemented {
  [self loadAdWithSize:CGSizeMake(320, 50)];
  [_bannerAdDelegate adViewWillLeaveApplication:_bannerAdMock];
  [_bannerAdDelegate adViewClosed:_bannerAdMock];
}

- (void)testLoadFailureWithNoAdUnitID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralPlacementID : kPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithNoPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithInvalidBannerSize {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(0, 0));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegtalErrorBannerSizeInValid
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

@end
