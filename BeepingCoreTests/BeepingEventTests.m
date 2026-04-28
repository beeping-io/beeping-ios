@import XCTest;

#import "BeepingEvent.h"

@interface BeepingEventTests : XCTestCase
@end

@implementation BeepingEventTests

- (void)testInitializerAssignsAllFields {
    BeepingEvent *event = [[BeepingEvent alloc] initWithStatus:BeepingEventStatusEndOk
                                                           key:@"12345"
                                                 decodedString:@"12345abcd"
                                                          mode:2
                                                     timestamp:42
                                                    confidence:0.9f
                                               confidenceError:0.2f
                                               confidenceNoise:0.3f
                                           receivedBeepsVolume:-10.f];

    XCTAssertEqual(event.status, BeepingEventStatusEndOk);
    XCTAssertEqualObjects(event.key, @"12345");
    XCTAssertEqualObjects(event.decodedString, @"12345abcd");
    XCTAssertEqual(event.mode, 2);
    XCTAssertEqual(event.timestamp, 42);
    XCTAssertEqualWithAccuracy(event.confidence, 0.9f, 0.0001);
    XCTAssertEqualWithAccuracy(event.confidenceError, 0.2f, 0.0001);
    XCTAssertEqualWithAccuracy(event.confidenceNoise, 0.3f, 0.0001);
    XCTAssertEqualWithAccuracy(event.receivedBeepsVolume, -10.f, 0.0001);
}

- (void)testStartAllowsEmptyPayload {
    BeepingEvent *event = [[BeepingEvent alloc] initWithStatus:BeepingEventStatusStart
                                                           key:nil
                                                 decodedString:nil
                                                          mode:0
                                                     timestamp:0
                                                    confidence:0
                                               confidenceError:0
                                               confidenceNoise:0
                                           receivedBeepsVolume:0];
    XCTAssertEqual(event.status, BeepingEventStatusStart);
    XCTAssertNil(event.key);
    XCTAssertNil(event.decodedString);
    XCTAssertEqual(event.mode, 0);
    XCTAssertEqual(event.timestamp, 0);
}

- (void)testEndBadAllowsEmptyPayload {
    BeepingEvent *event = [[BeepingEvent alloc] initWithStatus:BeepingEventStatusEndBad
                                                           key:nil
                                                 decodedString:nil
                                                          mode:0
                                                     timestamp:0
                                                    confidence:0
                                               confidenceError:0
                                               confidenceNoise:0
                                           receivedBeepsVolume:0];
    XCTAssertEqual(event.status, BeepingEventStatusEndBad);
    XCTAssertNil(event.key);
    XCTAssertNil(event.decodedString);
}

- (void)testPropertiesAreReadonly {
    BeepingEvent *event = [[BeepingEvent alloc] initWithStatus:BeepingEventStatusEndOk
                                                           key:@"abcde"
                                                 decodedString:@"abcde1234"
                                                          mode:1
                                                     timestamp:1
                                                    confidence:1
                                               confidenceError:1
                                               confidenceNoise:1
                                           receivedBeepsVolume:1];

    XCTAssertFalse([event respondsToSelector:@selector(setKey:)]);
    XCTAssertFalse([event respondsToSelector:@selector(setDecodedString:)]);
    XCTAssertFalse([event respondsToSelector:@selector(setMode:)]);
    XCTAssertFalse([event respondsToSelector:@selector(setTimestamp:)]);
    XCTAssertFalse([event respondsToSelector:@selector(setConfidence:)]);
    XCTAssertFalse([event respondsToSelector:@selector(setConfidenceError:)]);
    XCTAssertFalse([event respondsToSelector:@selector(setConfidenceNoise:)]);
    XCTAssertFalse([event respondsToSelector:@selector(setReceivedBeepsVolume:)]);
}

@end
