//
//  URLSessionHelpers.swift
//  CelestraKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import Testing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

// Register MockURLProtocol globally once when module loads
private let mockURLProtocolRegistration: Void = {
  URLProtocol.registerClass(MockURLProtocol.self)
}()

/// Semaphore to serialize test suites using MockURLProtocol
/// Prevents concurrent test suites from interfering with each other's mock handlers
internal let mockURLProtocolSemaphore = DispatchSemaphore(value: 1)

/// Tag for tests that use network mocking
extension Tag {
  @Tag static var networkMock: Self
}

/// Creates a URLSession configured to use MockURLProtocol
internal func createMockURLSession() -> URLSession {
  // Create a copy to avoid mutating shared .ephemeral singleton
  guard let config = URLSessionConfiguration.ephemeral.copy() as? URLSessionConfiguration else {
    preconditionFailure("Failed to copy URLSessionConfiguration")
  }
  config.protocolClasses = [MockURLProtocol.self]
  return URLSession(configuration: config)
}
