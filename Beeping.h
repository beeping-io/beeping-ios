//
//  Beeping.h
//  Beeping
//
//  Public umbrella header. The `BeepingEvent` payload class and the
//  `beepingDelegate` protocol moved to Swift in BEE-68 — they're declared
//  in the auto-generated `Beeping-Swift.h` (included via the framework's
//  module map). Forward declarations below let this header compile
//  standalone; module-import consumers (`@import Beeping;` /
//  `import Beeping`) get the full definitions automatically.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Beeping/BeepingCore.h>   // public ObjC API of the legacy core wrapper (replaced in phase 5/7)
#import <Beeping/BeepingC.h>      // ObjC++ bridge — needed in umbrella so Swift in this target sees it; visibility tightened in BEE-80 (Package.swift) when private modules are first-class

NS_ASSUME_NONNULL_BEGIN

@class BeepingEvent;          // defined in Beeping-Swift.h
@protocol beepingDelegate;    // defined in Beeping-Swift.h
@class Beeping;

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
