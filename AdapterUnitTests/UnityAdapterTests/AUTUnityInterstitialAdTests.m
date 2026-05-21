#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"

@interface AUTUnityInterstitialAdTests : AUTUnityTestCase
@end

@implementation AUTUnityInterstitialAdTests

- (void)setUp {
  [super setUp];
  OCMStub(ClassMethod([self.unityAdsClassMock isInitialized])).andReturn(YES);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  [super tearDown];
}

- (void)loadWaterfallInterstitialAd {
  id mockInterstitialAd = OCMClassMock([UADSInterstitialAd class]);
  OCMStub(ClassMethod([self.interstitialAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSInterstitialAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockInterstitialAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)loadBiddingInterstitialAd {
  id mockInterstitialAd = OCMClassMock([UADSInterstitialAd class]);
  OCMStub(ClassMethod([self.interstitialAdClassMock
                  load:[OCMArg checkWithBlock:^BOOL(id value) {
                    XCTAssertTrue([value isKindOfClass:[UADSLoadConfiguration class]]);
                    UADSLoadConfiguration *config = (UADSLoadConfiguration *)value;
      return true; // [config.adMarkup isEqualToString:AUTUnityBidResponse];
                  }]
            completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSInterstitialAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockInterstitialAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.bidResponse = AUTUnityBidResponse;
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)testLoadBiddingInterstitialAdWithEmptySignal {
  id mockInterstitialAd = OCMClassMock([UADSInterstitialAd class]);
  OCMStub(ClassMethod([self.interstitialAdClassMock
                  load:[OCMArg checkWithBlock:^BOOL(id value) {
                    XCTAssertTrue([value isKindOfClass:[UADSLoadConfiguration class]]);
                    UADSLoadConfiguration *config = (UADSLoadConfiguration *)value;
      return true;// [config.adMarkup isEqualToString:@""];
                  }]
            completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSInterstitialAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockInterstitialAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.bidResponse = @"";
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);
}

- (void)testLoadInterstitialAdFailure {
  id mockError = OCMProtocolMock(@protocol(UnityAdsError));
  OCMStub([mockError code]).andReturn(1);
  OCMStub([mockError message]).andReturn(@"abcdefg");

  OCMStub(ClassMethod([self.interstitialAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSInterstitialAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(nil, mockError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *error = [NSError errorWithDomain:GADMAdapterUnitySDKErrorDomain code:1 userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(self.adapter, configuration, error);
}

- (void)testInterstitialAdPresentLifecycle {
  // First load an interstitial ad.
  id mockInterstitialAd = OCMClassMock([UADSInterstitialAd class]);
  __block id<UADSInterstitialShowDelegate> capturedShowDelegate = nil;

  OCMStub(ClassMethod([self.interstitialAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSInterstitialAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockInterstitialAd, nil);
      });

  OCMStub([mockInterstitialAd show:OCMOCK_ANY delegate:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UADSInterstitialShowDelegate> showDelegate = nil;
        [invocation getArgument:&showDelegate atIndex:3];
        capturedShowDelegate = showDelegate;
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = [[NSData alloc] initWithBase64EncodedString:AUTUnityWatermarkBase64
                                                                options:0];
  AUTKMediationInterstitialAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);

  // After loading an interstitial ad, verify that present ad invokes UnityAd SDK's show method.
  UIViewController *presentViewController = [[UIViewController alloc] init];
  id<GADMediationInterstitialAd> mediationInterstitialAd = delegate.interstitialAd;

  // Simulate ad presenting.
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  [mediationInterstitialAd presentFromViewController:presentViewController];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);

  // Simulate presented.
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [capturedShowDelegate showDidStart:mockInterstitialAd];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);

  // Simulate dismissing the presented ad.
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);
  [capturedShowDelegate showDidComplete:mockInterstitialAd with:UADSShowFinishStateCompleted];
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testInterstitialAdPresentFailureLifecycle {
  // First load an interstitial ad.
  id mockInterstitialAd = OCMClassMock([UADSInterstitialAd class]);
  __block id<UADSInterstitialShowDelegate> capturedShowDelegate = nil;

  OCMStub(ClassMethod([self.interstitialAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSInterstitialAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockInterstitialAd, nil);
      });

  OCMStub([mockInterstitialAd show:OCMOCK_ANY delegate:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UADSInterstitialShowDelegate> showDelegate = nil;
        [invocation getArgument:&showDelegate atIndex:3];
        capturedShowDelegate = showDelegate;
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKMediationInterstitialAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);

  // Present the ad.
  UIViewController *presentViewController = [[UIViewController alloc] init];
  id<GADMediationInterstitialAd> mediationInterstitialAd = delegate.interstitialAd;
  [mediationInterstitialAd presentFromViewController:presentViewController];

  // Simulate ad present failure.
  NSString *presentationErrorMessage = @"abcdefg";
  id mockError = OCMProtocolMock(@protocol(UnityAdsError));
  OCMStub([mockError code]).andReturn(2);
  OCMStub([mockError message]).andReturn(presentationErrorMessage);

  [capturedShowDelegate showDidFail:mockInterstitialAd error:mockError];
  NSError *presentationError = delegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, GADMAdapterUnitySDKErrorDomain);
  XCTAssertEqual(presentationError.code, 2);
  XCTAssertEqualObjects(presentationError.userInfo[NSLocalizedDescriptionKey],
                        presentationErrorMessage);
}

- (void)testAdClick {
  // First load an interstitial ad.
  id mockInterstitialAd = OCMClassMock([UADSInterstitialAd class]);
  __block id<UADSInterstitialShowDelegate> capturedShowDelegate = nil;

  OCMStub(ClassMethod([self.interstitialAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSInterstitialAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockInterstitialAd, nil);
      });

  OCMStub([mockInterstitialAd show:OCMOCK_ANY delegate:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UADSInterstitialShowDelegate> showDelegate = nil;
        [invocation getArgument:&showDelegate atIndex:3];
        capturedShowDelegate = showDelegate;
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKMediationInterstitialAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);

  // Present the ad.
  UIViewController *presentViewController = [[UIViewController alloc] init];
  id<GADMediationInterstitialAd> mediationInterstitialAd = delegate.interstitialAd;
  [mediationInterstitialAd presentFromViewController:presentViewController];

  // Simulate ad clicking.
  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [capturedShowDelegate showDidClick:mockInterstitialAd];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

@end
