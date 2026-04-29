//
//  Beeping.h
//  Beeping
//
//  Framework umbrella header. Re-exports the public ObjC interfaces of
//  the legacy core wrapper (`BeepingCore.h`) and the internal ObjC++
//  bridge (`BeepingC.h`). The `Beeping` facade class itself lives in
//  `Beeping.swift` (post-BEE-68 phase 5) and is exposed to ObjC via the
//  auto-generated `Beeping-Swift.h` — module-import consumers
//  (`@import Beeping;` / `import Beeping`) get it transparently.
//
//  Forward declarations below let this header compile standalone for
//  consumers that only `#import <Beeping/Beeping.h>` and don't pull in
//  Beeping-Swift.h directly.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Beeping/BeepingC.h>      // ObjC++ bridge — Public for framework-internal Swift access; tightened in BEE-80 (private submodule)

NS_ASSUME_NONNULL_BEGIN

@class Beeping;               // defined in Beeping.swift / Beeping-Swift.h
@class BeepingEvent;          // defined in BeepingEvent.swift / Beeping-Swift.h
@protocol beepingDelegate;    // defined in BeepingDelegate.swift / Beeping-Swift.h

NS_ASSUME_NONNULL_END
