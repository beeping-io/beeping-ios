//
//  BeepingEvent.swift
//  Beeping
//
//  Decoded payload + metadata for a single beep event. Replaces the legacy
//  ObjC `BeepingEvent.{h,m}` while preserving the public ObjC name and
//  selectors (`@objc(BeepingEvent)`, `BeepingEventStatusStart` etc.) so
//  legacy ObjC consumers (`Beeping.m`, `BeepingDelegateTests.m`,
//  `BeepingEventTests.m`) keep compiling against the auto-generated
//  `Beeping-Swift.h` header without changes.
//
//  Sendable: the class is `final`, all stored properties are immutable
//  `let` of Sendable types, so the conformance is `Sendable` (NOT
//  `@unchecked Sendable`) — satisfies the BEE-68 "no @unchecked" gate.
//
//  The actor-based redesign in BEE-70 introduces a separate `BeepingEvent`
//  enum + `BeepingPayload` struct. This class persists alongside it for
//  backward ObjC compat through 0.x; planned removal at 1.0.
//

import Foundation

@objc(BeepingEvent)
public final class BeepingEvent: NSObject, Sendable {

    // MARK: - Status

    @objc(BeepingEventStatus)
    public enum Status: Int, Sendable {
        case start  = 0
        case endOk  = 1
        case endBad = 2
    }

    // MARK: - Properties (immutable)

    @objc public let status: Status
    @objc public let key: String?
    @objc public let decodedString: String?
    @objc public let mode: Int
    @objc public let timestamp: Int
    @objc public let confidence: Float
    @objc public let confidenceError: Float
    @objc public let confidenceNoise: Float
    @objc public let receivedBeepsVolume: Float

    // MARK: - Init

    @objc public init(
        status: Status,
        key: String?,
        decodedString: String?,
        mode: Int,
        timestamp: Int,
        confidence: Float,
        confidenceError: Float,
        confidenceNoise: Float,
        receivedBeepsVolume: Float
    ) {
        self.status              = status
        self.key                 = key
        self.decodedString       = decodedString
        self.mode                = mode
        self.timestamp           = timestamp
        self.confidence          = confidence
        self.confidenceError     = confidenceError
        self.confidenceNoise     = confidenceNoise
        self.receivedBeepsVolume = receivedBeepsVolume
        super.init()
    }
}
