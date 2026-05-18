//
//  MockURLProtocol.swift
//  BeepingTests
//
//  Test helper that intercepts requests made through a URLSession
//  configured with `protocolClasses = [MockURLProtocol.self]`. Lets us
//  assert URL / headers / body shape on `CloudEncoder` without standing
//  up a real `beepbox-server`.
//
//  Usage:
//
//      let config = URLSessionConfiguration.ephemeral
//      config.protocolClasses = [MockURLProtocol.self]
//      let session = URLSession(configuration: config)
//
//      MockURLProtocol.responder = { request in
//          let response = HTTPURLResponse(url: request.url!,
//                                         statusCode: 200,
//                                         httpVersion: nil,
//                                         headerFields: nil)!
//          return (Data(), response)
//      }
//      // ... exercise code that uses `session`
//      let captured = MockURLProtocol.lastRequest
//
//  ⚠️  PARALLEL TEST EXECUTION CAVEAT (BEE-2257):
//
//  `responder` and `lastRequest` are shared static state because
//  `URLProtocol` instances are spawned per-request by the URL loading
//  system and have no clean way to receive per-test configuration. With
//  Swift Testing's default parallel suite execution, two suites that
//  both set `responder` race against each other, and one suite's
//  `defer reset` can fire before the other's request has been served —
//  surfacing as cross-test contamination ("HTTP 400: key must be ..." in
//  a test that never set a 400 responder).
//
//  Required to keep tests stable:
//    1. Every suite using this protocol annotates with `.serialized`
//       (in-suite test ordering).
//    2. CI runs `xcodebuild test -parallel-testing-enabled NO` to
//       serialize across suites (configured in `.github/workflows/ci.yml`).
//
//  A future refactor could move the responder into per-session userInfo,
//  but the static + serialization combo is the pragmatic minimum.
//

import Foundation

final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    /// Closure invoked for every intercepted request. Set in tests
    /// before exercising code under test.
    nonisolated(unsafe) static var responder: ((URLRequest) -> (Data, HTTPURLResponse))?

    /// The most recent request that the protocol intercepted. Tests
    /// inspect this to verify URL / headers / body.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    /// Resets `responder` and `lastRequest`. Call from `defer` in tests
    /// to keep state from leaking between cases.
    static func reset() {
        responder = nil
        lastRequest = nil
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        guard let responder = Self.responder else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(
                    domain: "MockURLProtocol",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No responder set"]
                ))
            return
        }
        let (data, response) = responder(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
