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
