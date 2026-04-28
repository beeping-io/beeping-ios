//
//  BeepingEvent.m
//  Beeping
//

#import "BeepingEvent.h"

@implementation BeepingEvent

- (instancetype)initWithStatus:(BeepingEventStatus)status
                           key:(nullable NSString *)key
                 decodedString:(nullable NSString *)decodedString
                          mode:(NSInteger)mode
                     timestamp:(NSInteger)timestamp
                    confidence:(float)confidence
               confidenceError:(float)confidenceError
               confidenceNoise:(float)confidenceNoise
           receivedBeepsVolume:(float)receivedBeepsVolume
{
    self = [super init];
    if (self) {
        _status = status;
        _key = [key copy];
        _decodedString = [decodedString copy];
        _mode = mode;
        _timestamp = timestamp;
        _confidence = confidence;
        _confidenceError = confidenceError;
        _confidenceNoise = confidenceNoise;
        _receivedBeepsVolume = receivedBeepsVolume;
    }
    return self;
}

@end
