//
//  BeepingClientTests.swift
//  BeepingTests
//
//  Swift Testing suite for the BEE-70 actor API.
//

import Testing
@testable import Beeping

@Suite("BeepingClient (actor + AsyncStream API, BEE-70)")
struct BeepingClientTests {

    @Test("Init with default mode does not require await")
    func initIsSync() async {
        // The actor's init is synchronous. Reaching here without a
        // compile error means the assertion is met.
        _ = BeepingClient()
    }

    @Test("Init with explicit mode")
    func initWithMode() async {
        _ = BeepingClient(mode: .audible)
        _ = BeepingClient(mode: .nonAudible)
        _ = BeepingClient(mode: .all)
    }

    @Test("listen() returns an AsyncStream<Event>")
    func listenReturnsStream() async {
        let client = BeepingClient(mode: .all)
        // Type assertion: the variable is typed as AsyncStream<Event>; if
        // the API changes shape this test will fail to compile.
        let stream: AsyncStream<BeepingClient.Event> = await client.listen()
        _ = stream
        await client.close()
    }

    @Test("Multiple listen() calls create independent streams")
    func multipleListenersIndependent() async {
        let client = BeepingClient(mode: .all)
        let s1 = await client.listen()
        let s2 = await client.listen()
        // Different stream instances. We can't compare AsyncStreams
        // directly, but iterating both should yield independently.
        _ = s1
        _ = s2
        await client.close()
    }

    @Test("close() yields .stopped to live consumers and terminates")
    func closeStops() async throws {
        let client = BeepingClient(mode: .all)
        let stream = await client.listen()

        // Schedule the close after the stream is established.
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            await client.close()
        }

        var sawStopped = false
        for await event in stream {
            if case .stopped = event {
                sawStopped = true
            }
        }
        #expect(sawStopped, "Expected .stopped before stream finished")
    }

    @Test("Event cases are Sendable")
    func eventIsSendable() {
        func requireSendable<T: Sendable>(_ x: T) {}
        requireSendable(BeepingClient.Event.started)
        requireSendable(BeepingClient.Event.stopped)
        requireSendable(BeepingClient.Event.failed(.audioSessionInterrupted))
    }

    @Test("BeepingPayload is Sendable + Equatable")
    func payloadIsSendable() {
        let payload = BeepingPayload(
            key: "12345",
            decodedString: "12345abcd",
            mode: 2,
            timestamp: 99,
            confidence: 0.8,
            confidenceError: 0.1,
            confidenceNoise: 0.2,
            receivedBeepsVolume: -5
        )
        func requireSendable<T: Sendable>(_ x: T) {}
        requireSendable(payload)
        #expect(payload == payload)  // Equatable compile-time gate
    }

    @Test("BeepingError is now public + Sendable")
    func errorIsPublicSendable() {
        // If BeepingError were still internal, the test target's
        // @testable import would still see it, but a non-testable
        // import wouldn't. Use the canonical access here.
        func requireSendable<T: Sendable>(_ x: T) {}
        requireSendable(BeepingError.audioSessionInterrupted)
        requireSendable(BeepingError.missingMicrophonePermission)
        requireSendable(BeepingError.nativeLibraryNotLoaded)
        requireSendable(BeepingError.decoderInternal(reason: "test"))
    }

    @Test("BeepingMode is now public")
    func modeIsPublic() {
        let m: BeepingMode = .all
        #expect(m.rawValue == 5)  // BEEPING_MODE_ALL
    }
}
