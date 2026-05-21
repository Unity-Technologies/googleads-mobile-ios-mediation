#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"

@interface AUTUnityRewardedAdTests : AUTUnityTestCase
@end

@implementation AUTUnityRewardedAdTests

- (void)setUp {
  [super setUp];
  OCMStub(ClassMethod([self.unityAdsClassMock isInitialized])).andReturn(YES);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  [super tearDown];
}

- (void)loadWaterfallRewardedAd {
  id mockRewardedAd = OCMClassMock([UADSRewardedAd class]);
  OCMStub(ClassMethod([self.rewardedAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSRewardedAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockRewardedAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);
}

- (void)
    testLoadWaterfallRewardedAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallRewardedAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallRewardedAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallRewardedAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallRewardedAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallRewardedAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallRewardedAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallRewardedAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)loadBiddingRewardedAd {
  id mockRewardedAd = OCMClassMock([UADSRewardedAd class]);
  OCMStub(ClassMethod([self.rewardedAdClassMock
                  load:[OCMArg checkWithBlock:^BOOL(id value) {
                    XCTAssertTrue([value isKindOfClass:[UADSLoadConfiguration class]]);
                    UADSLoadConfiguration *config = (UADSLoadConfiguration *)value;
      UADSLoadConfiguration *expected = [[[[UADSLoadConfigurationBuilder alloc] initWithPlacementId:@""] withAdMarkup:AUTUnityBidResponse] build];
                    return [config isEqual:expected];
                  }]
            completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSRewardedAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockRewardedAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.bidResponse = AUTUnityBidResponse;
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);
}

- (void)
    testLoadBiddingRewardedAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingRewardedAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingRewardedAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingRewardedAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingRewardedAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingRewardedAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingRewardedAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingRewardedAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingRewardedAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)testLoadBiddingRewardedAdWithEmptySignal {
  id mockRewardedAd = OCMClassMock([UADSRewardedAd class]);
  OCMStub(ClassMethod([self.rewardedAdClassMock
                  load:[OCMArg checkWithBlock:^BOOL(id value) {
                    XCTAssertTrue([value isKindOfClass:[UADSLoadConfiguration class]]);
                    UADSLoadConfiguration *config = (UADSLoadConfiguration *)value;
      return true;// [config.adMarkup isEqualToString:@""];
                  }]
            completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSRewardedAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockRewardedAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.bidResponse = @"";
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);
}

- (void)testLoadRewardedAdFailure {
  id mockError = OCMProtocolMock(@protocol(UnityAdsError));
  OCMStub([mockError code]).andReturn(1);
  OCMStub([mockError message]).andReturn(@"abcdefg");

  OCMStub(ClassMethod([self.rewardedAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSRewardedAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(nil, mockError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *error = [NSError errorWithDomain:GADMAdapterUnitySDKErrorDomain code:1 userInfo:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(self.adapter, configuration, error);
}

- (void)testRewardedAdPresentLifecycle {
  // First load a rewarded ad.
  id mockRewardedAd = OCMClassMock([UADSRewardedAd class]);
  __block id<UADSRewardedShowDelegate> capturedShowDelegate = nil;

  OCMStub(ClassMethod([self.rewardedAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSRewardedAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockRewardedAd, nil);
      });

  OCMStub([mockRewardedAd show:OCMOCK_ANY delegate:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UADSRewardedShowDelegate> showDelegate = nil;
        [invocation getArgument:&showDelegate atIndex:3];
        capturedShowDelegate = showDelegate;
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = [[NSData alloc] initWithBase64EncodedString:AUTUnityWatermarkBase64
                                                                options:0];

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);

  // After loading a Rewarded ad, verify that present ad invokes UnityAd SDK's show method.
  UIViewController *presentViewController = [[UIViewController alloc] init];
  id<GADMediationRewardedAd> mediationRewardedAd = delegate.rewardedAd;

  // Simulate ad presenting.
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  [mediationRewardedAd presentFromViewController:presentViewController];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);

  // Simulate presented.
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [capturedShowDelegate showDidStart:mockRewardedAd];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);

  // Simulate dismissing the presented ad.
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didRewardUserInvokeCount, 0);
  [capturedShowDelegate showDidComplete:mockRewardedAd with:UADSShowFinishStateCompleted];
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);

  // Reward must be granted when video is dismissed with completed state.
  XCTAssertEqual(delegate.didRewardUserInvokeCount, 1);
}

- (void)testRewardedAdPresentFailureLifecycle {
  // First load a rewarded ad.
  id mockRewardedAd = OCMClassMock([UADSRewardedAd class]);
  __block id<UADSRewardedShowDelegate> capturedShowDelegate = nil;

  OCMStub(ClassMethod([self.rewardedAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSRewardedAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockRewardedAd, nil);
      });

  OCMStub([mockRewardedAd show:OCMOCK_ANY delegate:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UADSRewardedShowDelegate> showDelegate = nil;
        [invocation getArgument:&showDelegate atIndex:3];
        capturedShowDelegate = showDelegate;
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);

  // Present the ad.
  UIViewController *presentViewController = [[UIViewController alloc] init];
  id<GADMediationRewardedAd> mediationRewardedAd = delegate.rewardedAd;
  [mediationRewardedAd presentFromViewController:presentViewController];

  // Simulate ad present failure.
  NSString *presentationErrorMessage = @"abcdefg";
  id mockError = OCMProtocolMock(@protocol(UnityAdsError));
  OCMStub([mockError code]).andReturn(2);
  OCMStub([mockError message]).andReturn(presentationErrorMessage);

  [capturedShowDelegate showDidFail:mockRewardedAd error:mockError];
  NSError *presentationError = delegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, GADMAdapterUnitySDKErrorDomain);
  XCTAssertEqual(presentationError.code, 2);
  XCTAssertEqualObjects(presentationError.userInfo[NSLocalizedDescriptionKey],
                        presentationErrorMessage);
}

- (void)testAdClick {
  // First load a rewarded ad.
  id mockRewardedAd = OCMClassMock([UADSRewardedAd class]);
  __block id<UADSRewardedShowDelegate> capturedShowDelegate = nil;

  OCMStub(ClassMethod([self.rewardedAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSRewardedAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockRewardedAd, nil);
      });

  OCMStub([mockRewardedAd show:OCMOCK_ANY delegate:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UADSRewardedShowDelegate> showDelegate = nil;
        [invocation getArgument:&showDelegate atIndex:3];
        capturedShowDelegate = showDelegate;
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);

  // Present the ad.
  UIViewController *presentViewController = [[UIViewController alloc] init];
  id<GADMediationRewardedAd> mediationRewardedAd = delegate.rewardedAd;
  [mediationRewardedAd presentFromViewController:presentViewController];

  // Simulate ad clicking.
  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [capturedShowDelegate showDidClick:mockRewardedAd];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

@end
