//
//  BeepingEvent.h
//  Beeping
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BeepingEventStatus) {
    BeepingEventStatusStart = 0,
    BeepingEventStatusEndOk = 1,
    BeepingEventStatusEndBad = 2
} NS_SWIFT_NAME(BeepingEvent.Status);

@interface BeepingEvent : NSObject

@property (nonatomic, readonly) BeepingEventStatus status;
@property (nonatomic, readonly, nullable) NSString *key;
@property (nonatomic, readonly, nullable) NSString *decodedString;
@property (nonatomic, readonly) NSInteger mode;
@property (nonatomic, readonly) NSInteger timestamp;
@property (nonatomic, readonly) float confidence;
@property (nonatomic, readonly) float confidenceError;
@property (nonatomic, readonly) float confidenceNoise;
@property (nonatomic, readonly) float receivedBeepsVolume;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStatus:(BeepingEventStatus)status
                           key:(nullable NSString *)key
                 decodedString:(nullable NSString *)decodedString
                          mode:(NSInteger)mode
                     timestamp:(NSInteger)timestamp
                    confidence:(float)confidence
               confidenceError:(float)confidenceError
               confidenceNoise:(float)confidenceNoise
           receivedBeepsVolume:(float)receivedBeepsVolume NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(status:key:decodedString:mode:timestamp:confidence:confidenceError:confidenceNoise:receivedBeepsVolume:));

@end

NS_ASSUME_NONNULL_END
