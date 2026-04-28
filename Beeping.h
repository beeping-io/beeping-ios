//
//  Beeping.h
//  Beeping
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Beeping/BeepingEvent.h>

NS_ASSUME_NONNULL_BEGIN

@class BeepingCore;
@class Beeping;

@protocol beepingDelegate <NSObject>

@required
- (void)beepIdWith:(NSString *)beep_id NS_SWIFT_NAME(beepId(with:));

@optional
- (void)beepingDidReceiveEvent:(BeepingEvent *)event NS_SWIFT_NAME(beepingDidReceive(event:));
@end

@interface Beeping : NSObject <NSURLConnectionDelegate> {

    // Private properties
    // Beeping object
    BeepingCore *_beepingCore;              

}

    // Public Methods
    // Singleton method
    +(Beeping *) instance NS_SWIFT_NAME(shared());

    // Public methods
    -(void) listen;
    -(void) stop;

    // Public properties
    // Delegate object
    @property (nonatomic, weak, nullable) id<beepingDelegate>delegate;

@end

NS_ASSUME_NONNULL_END
