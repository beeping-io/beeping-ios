//
//  BeepingDelegate.swift
//  Beeping
//
//  Public delegate protocol for receiving beep events. Replaces the legacy
//  `@protocol beepingDelegate <NSObject>` declaration that used to live in
//  `Beeping.h`, preserving the ObjC name (`beepingDelegate`) and all
//  selectors / Swift names so existing consumers don't break.
//
//  The actor-based redesign in BEE-70 deprecates this protocol in favor of
//  `AsyncStream<BeepingEvent>` on `BeepingClient`. Until then the legacy
//  delegate API is the public surface.
//

import Foundation

/// Receives decoded beep events on the main thread.
///
/// All callbacks are dispatched on the main queue by `Beeping`; consumers
/// don't need to hop themselves. Heavy work should be moved off-thread by
/// the consumer's implementation. The `@MainActor` annotation makes the
/// already-documented "main queue dispatch" contract explicit in the type
/// system so Swift 6 strict concurrency can verify conformers respect it.
@MainActor
@objc(beepingDelegate)
public protocol BeepingDelegate: NSObjectProtocol {

    /// Called when a beep with valid decoded data is received (`END_OK`
    /// token). `beepId` is the 5-character key.
    @objc(beepIdWith:)
    func beepId(with beepId: String)

    /// Called for every event including `START`, `END_OK`, `END_BAD`.
    /// Optional — implement when you need the full payload + confidence.
    @objc(beepingDidReceiveEvent:)
    optional func beepingDidReceive(event: BeepingEvent)
}
