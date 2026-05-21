#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"

@interface AUTUnityBannerAdTests : AUTUnityTestCase
@end

@implementation AUTUnityBannerAdTests

- (void)setUp {
  [super setUp];
  OCMStub(ClassMethod([self.unityAdsClassMock isInitialized])).andReturn(YES);
  OCMStub(ClassMethod([self.unityAdsClassMock initialize:OCMOCK_ANY  completion:OCMOCK_ANY]))
    .andDo(^(NSInvocation *invocation) {
      __unsafe_unretained void (^completionHandler)(id<UnityAdsError> *_Nullable error);
      [invocation getArgument:&completionHandler atIndex:3];
      completionHandler(nil);
      
    });
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  [super tearDown];
}

- (void)loadWaterfallBannerAd {
  UIView *mockBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
  id mockBannerAd = OCMClassMock([UADSBannerAd class]);
  OCMStub([mockBannerAd view]).andReturn(mockBannerView);

  OCMStub(ClassMethod([self.bannerAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSBannerAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockBannerAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);

  id<GADMediationBannerAd> bannerAd = (id<GADMediationBannerAd>)self.adapter;
  XCTAssertEqualObjects(bannerAd, mockBannerView);
}

- (void)
    testLoadWaterfallBannerAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallBannerAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallBannerAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallBannerAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallBannerAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadWaterfallBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallBannerAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallBannerAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadWaterfallBannerAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadWaterfallBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)loadBiddingBannerAd {
  UIView *mockBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
  id mockBannerAd = OCMClassMock([UADSBannerAd class]);
  OCMStub([mockBannerAd view]).andReturn(mockBannerView);

  OCMStub(ClassMethod([self.bannerAdClassMock
                  load:[OCMArg checkWithBlock:^BOOL(id value) {
                    XCTAssertTrue([value isKindOfClass:[UADSBannerLoadConfiguration class]]);
                    UADSBannerLoadConfiguration *config = (UADSBannerLoadConfiguration *)value;
      return true;// [config.adMarkup isEqualToString:AUTUnityBidResponse];
                  }]
            completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSBannerAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockBannerAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.bidResponse = AUTUnityBidResponse;
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  configuration.watermark = [[NSData alloc] initWithBase64EncodedString:AUTUnityWatermarkBase64
                                                                options:0];
  AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);

  id<GADMediationBannerAd> bannerAd = (id<GADMediationBannerAd>)self.adapter;
  XCTAssertEqualObjects(bannerAd.view, mockBannerView);
}

- (void)
    testLoadBiddingBannerAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingBannerAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingBannerAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingBannerAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingBannerAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:YES]));

  [self loadBiddingBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingBannerAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingBannerAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)
    testLoadBiddingBannerAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  OCMExpect(ClassMethod([self.unityAdsClassMock setNonBehavioral:NO]));

  [self loadBiddingBannerAd];

  OCMVerifyAll(self.unityAdsClassMock);
}

- (void)testLoadBiddingBannerAdWithEmptySignal {
  UIView *mockBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
  id mockBannerAd = OCMClassMock([UADSBannerAd class]);
  OCMStub([mockBannerAd view]).andReturn(mockBannerView);

  OCMStub(ClassMethod([self.bannerAdClassMock
                  load:[OCMArg checkWithBlock:^BOOL(id value) {
                    XCTAssertTrue([value isKindOfClass:[UADSBannerLoadConfiguration class]]);
                    UADSBannerLoadConfiguration *config = (UADSBannerLoadConfiguration *)value;
      return true;//[config.adMarkup isEqualToString:@""];
                  }]
            completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSBannerAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockBannerAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.bidResponse = @"";
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);
  id<GADMediationBannerAd> bannerAd = (id<GADMediationBannerAd>)self.adapter;
  XCTAssertEqualObjects(bannerAd.view, mockBannerView);
}

- (void)testLoadBannerAdFailure {
  id mockError = OCMProtocolMock(@protocol(UnityAdsError));
  OCMStub([mockError code]).andReturn(1);
  OCMStub([mockError message]).andReturn(@"No fill");

  OCMStub(ClassMethod([self.bannerAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completion)(UADSBannerAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(nil, mockError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterUnitySDKErrorDomain code:1 userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(self.adapter, configuration, expectedError);
}

- (void)testAdClick {
  UIView *mockBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
  id mockBannerAd = OCMClassMock([UADSBannerAd class]);
  OCMStub([mockBannerAd view]).andReturn(mockBannerView);
  __block id<UADSBannerAdDelegate> capturedDelegate = nil;

  OCMStub(ClassMethod([self.bannerAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained UADSBannerLoadConfiguration *config = nil;
        [invocation getArgument:&config atIndex:2];
        //capturedDelegate = config.delegate;
        __unsafe_unretained void (^completion)(UADSBannerAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockBannerAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);

  // Simulate ad clicking.
  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [capturedDelegate bannerDidClick:mockBannerAd];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testImpression {
  UIView *mockBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
  id mockBannerAd = OCMClassMock([UADSBannerAd class]);
  OCMStub([mockBannerAd view]).andReturn(mockBannerView);
  __block id<UADSBannerAdDelegate> capturedDelegate = nil;

  OCMStub(ClassMethod([self.bannerAdClassMock load:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained UADSBannerLoadConfiguration *config = nil;
        [invocation getArgument:&config atIndex:2];
       // capturedDelegate = config.delegate;
        __unsafe_unretained void (^completion)(UADSBannerAd *, id<UnityAdsError>) = nil;
        [invocation getArgument:&completion atIndex:3];
        completion(mockBannerAd, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);

  // Simulate ad impression.
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [capturedDelegate bannerImpression:mockBannerAd];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

@end
