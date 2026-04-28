//
//  Beeping.m
//  Beeping
//

#import "Beeping.h"
#import "BeepingCore.h"
#import <Beeping/Beeping-Swift.h>  // BeepingEvent + beepingDelegate (Swift)

@interface Beeping ()

@end

@implementation Beeping

- (void)dispatchToMain:(dispatch_block_t)block {
    if (!block) { return; }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (BeepingEvent *)buildEventForToken:(int)token {
    switch (token) {
        case BEEP_TOKEN_START:
            return [[BeepingEvent alloc] initWithStatus:BeepingEventStatusStart
                                                   key:nil
                                         decodedString:nil
                                                  mode:0
                                             timestamp:0
                                            confidence:0
                                       confidenceError:0
                                       confidenceNoise:0
                                   receivedBeepsVolume:0];
        case BEEP_TOKEN_END_OK: {
            NSString *decodedString = _beepingCore ? [_beepingCore getDecodedString] : nil;
            NSString *key = _beepingCore ? [_beepingCore getDecodedKey] : nil;
            if (key.length == 0 && decodedString.length >= 5) {
                key = [decodedString substringToIndex:5];
            }
            NSInteger mode = _beepingCore ? [_beepingCore getDecodedMode] : 0;
            NSInteger timestamp = _beepingCore ? [_beepingCore getDecodedTimeStamp] : 0;
            float confidence = _beepingCore ? [_beepingCore getConfidence] : 0;
            float confidenceError = _beepingCore ? [_beepingCore getConfidenceError] : 0;
            float confidenceNoise = _beepingCore ? [_beepingCore getConfidenceNoise] : 0;
            float receivedBeepsVolume = _beepingCore ? [_beepingCore getReceivedBeepsVolume] : 0;

            return [[BeepingEvent alloc] initWithStatus:BeepingEventStatusEndOk
                                                   key:key
                                         decodedString:decodedString
                                                  mode:mode
                                             timestamp:timestamp
                                            confidence:confidence
                                       confidenceError:confidenceError
                                       confidenceNoise:confidenceNoise
                                   receivedBeepsVolume:receivedBeepsVolume];
        }
        case BEEP_TOKEN_END_BAD: {
            NSString *decodedString = _beepingCore ? [_beepingCore getDecodedString] : nil;
            NSString *key = nil;
            if (decodedString.length >= 5) {
                key = [decodedString substringToIndex:5];
            }
            NSInteger mode = _beepingCore ? [_beepingCore getDecodedMode] : 0;
            float confidence = _beepingCore ? [_beepingCore getConfidence] : 0;
            float confidenceError = _beepingCore ? [_beepingCore getConfidenceError] : 0;
            float confidenceNoise = _beepingCore ? [_beepingCore getConfidenceNoise] : 0;
            float receivedBeepsVolume = _beepingCore ? [_beepingCore getReceivedBeepsVolume] : 0;

            return [[BeepingEvent alloc] initWithStatus:BeepingEventStatusEndBad
                                                   key:key
                                         decodedString:decodedString
                                                  mode:mode
                                             timestamp:0
                                            confidence:confidence
                                       confidenceError:confidenceError
                                       confidenceNoise:confidenceNoise
                                   receivedBeepsVolume:receivedBeepsVolume];
        }
        default:
            return nil;
    }
}

//
// @method init
//

+(Beeping*) instance
{
    // Declaración de variables
    static Beeping *beepingManager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        beepingManager = [[self alloc] init];
    });

    // Se devuelve la instancia
    return beepingManager;

}

//
// @method init
//


- (id) init {
    
    SEL beepingHandler = @selector(onBeep:);

    // Set callback that will be triggered when a beep is decoded/found
    _beepingCore = [[BeepingCore alloc] init:beepingHandler];

    // Set encoder/decoder mode, valid modes are defined in: BeepingCore.framework/Headers/BeepingCore.h
    // MODE_AUDIBLE | MODE_NONAUDIBLE | MODE_HIDDEN | MODE_ALL
    [_beepingCore configure:self withMode:MODE_ALL];
    
    //Show version of framework and audio library in log
    NSLog(@"%@", [NSString stringWithFormat:@"%@", [_beepingCore getVersionCoreFramework]]);
    
    // Tag SDK
    // NSLog(@"Nombre de la aplicación: %@", [NSString stringWithUTF8String:getprogname()]);
        
    return self;
}

//
// @method listen
//

-(void) listen {

    NSLog(@"[Beeping] Listening ...");

    // Empieza la escucha de beeps
    // Se pedirá acceso al micrófono en el caso de que no lo haya
    [_beepingCore startBeepingListen];

}

//
// @method stop
//

-(void) stop {

    NSLog(@"[Beeping] Stopped");

    // Empieza la escucha de beeps
    // Se pedirá acceso al micrófono en el caso de que no lo haya
    [_beepingCore stopBeepingListen];
}

//
// @method onBeep
//

- (void) onBeep:( NSNumber * ) value {

    int _value = [value intValue];

    BeepingEvent *event = [self buildEventForToken:_value];

    switch (_value) {
        case BEEP_TOKEN_START: {
            [self dispatchToMain:^{
                if ([self.delegate respondsToSelector:@selector(beepingDidReceiveEvent:)]) {
                    [self.delegate beepingDidReceiveEvent:event];
                }
            }];
            break;
        }
        case BEEP_TOKEN_END_OK: {
            NSString *key = event.key;

            [self dispatchToMain:^{
                if ([self.delegate respondsToSelector:@selector(beepingDidReceiveEvent:)]) {
                    [self.delegate beepingDidReceiveEvent:event];
                }
                if (key && [self.delegate respondsToSelector:@selector(beepIdWith:)]) {
                    [self.delegate beepIdWith:key];
                }
            }];
            break;
        }
        case BEEP_TOKEN_END_BAD: {
            [self dispatchToMain:^{
                if ([self.delegate respondsToSelector:@selector(beepingDidReceiveEvent:)]) {
                    [self.delegate beepingDidReceiveEvent:event];
                }
            }];
            break;
        }
        default:
            NSLog(@"[Beeping] Event not captured");
            break;
    }

}

- (void) dealloc {}

@end
