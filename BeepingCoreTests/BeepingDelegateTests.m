@import XCTest;

#import "Beeping.h"
#import "BeepingEvent.h"

@interface Beeping (Testing)
- (void)onBeep:(NSNumber *)value;
- (BeepingEvent *)buildEventForToken:(int)token;
@end

@interface BeepingDelegateMock : NSObject <beepingDelegate>
@property (nonatomic) NSInteger beepIdCalls;
@property (nonatomic) NSInteger eventCalls;
@property (nonatomic, strong) BeepingEvent *lastEvent;
@property (nonatomic, strong) NSString *lastKey;
@end

@implementation BeepingDelegateMock

- (void)beepIdWith:(NSString *)beep_id {
    XCTAssertTrue([NSThread isMainThread]);
    self.beepIdCalls += 1;
    self.lastKey = beep_id;
}

- (void)beepingDidReceiveEvent:(BeepingEvent *)event {
    XCTAssertTrue([NSThread isMainThread]);
    self.eventCalls += 1;
    self.lastEvent = event;
}

@end

@interface StubBeepingCore : NSObject
@property (nonatomic, copy) NSString *decodedString;
@property (nonatomic, copy) NSString *decodedKey;
@property (nonatomic) NSInteger decodedMode;
@property (nonatomic) NSInteger decodedTimeStamp;
@property (nonatomic) float confidence;
@property (nonatomic) float confidenceError;
@property (nonatomic) float confidenceNoise;
@property (nonatomic) float receivedBeepsVolume;
@end

@implementation StubBeepingCore
- (NSString *)getDecodedString { return self.decodedString; }
- (NSString *)getDecodedKey { return self.decodedKey; }
- (int)getDecodedMode { return (int)self.decodedMode; }
- (int)getDecodedTimeStamp { return (int)self.decodedTimeStamp; }
- (float)getConfidence { return self.confidence; }
- (float)getConfidenceError { return self.confidenceError; }
- (float)getConfidenceNoise { return self.confidenceNoise; }
- (float)getReceivedBeepsVolume { return self.receivedBeepsVolume; }
@end

@interface BeepingDelegateTests : XCTestCase
@end

@implementation BeepingDelegateTests

- (Beeping *)freshBeepingWithStub:(StubBeepingCore *)stub delegate:(BeepingDelegateMock *)delegate {
    Beeping *beeping = [Beeping instance];
    [beeping setDelegate:delegate];
    [beeping setValue:stub forKey:@"_beepingCore"];
    return beeping;
}

- (void)testEndOkEmitsEventAndBeepId {
    StubBeepingCore *stub = [StubBeepingCore new];
    stub.decodedString = @"12345abcd";
    stub.decodedKey = @"12345";
    stub.decodedMode = 2;
    stub.decodedTimeStamp = 99;
    stub.confidence = 0.8f;
    stub.confidenceError = 0.1f;
    stub.confidenceNoise = 0.2f;
    stub.receivedBeepsVolume = -5.f;

    BeepingDelegateMock *delegate = [BeepingDelegateMock new];
    Beeping *beeping = [self freshBeepingWithStub:stub delegate:delegate];

    [beeping onBeep:@(BEEP_TOKEN_END_OK)];

    XCTAssertEqual(delegate.eventCalls, 1);
    XCTAssertEqual(delegate.beepIdCalls, 1);
    XCTAssertEqual(delegate.lastEvent.status, BeepingEventStatusEndOk);
    XCTAssertEqualObjects(delegate.lastEvent.key, @"12345");
    XCTAssertNotNil(delegate.lastEvent.decodedString);
}

- (void)testEndBadEmitsOnlyEvent {
    StubBeepingCore *stub = [StubBeepingCore new];
    stub.decodedString = @"99999abcd";
    stub.decodedMode = 1;
    stub.confidence = 0.2f;

    BeepingDelegateMock *delegate = [BeepingDelegateMock new];
    Beeping *beeping = [self freshBeepingWithStub:stub delegate:delegate];

    [beeping onBeep:@(BEEP_TOKEN_END_BAD)];

    XCTAssertEqual(delegate.eventCalls, 1);
    XCTAssertEqual(delegate.beepIdCalls, 0);
    XCTAssertEqual(delegate.lastEvent.status, BeepingEventStatusEndBad);
}

- (void)testStartEmitsEventOnly {
    StubBeepingCore *stub = [StubBeepingCore new];
    BeepingDelegateMock *delegate = [BeepingDelegateMock new];
    Beeping *beeping = [self freshBeepingWithStub:stub delegate:delegate];

    [beeping onBeep:@(BEEP_TOKEN_START)];

    XCTAssertEqual(delegate.eventCalls, 1);
    XCTAssertEqual(delegate.beepIdCalls, 0);
    XCTAssertEqual(delegate.lastEvent.status, BeepingEventStatusStart);
}

@end
