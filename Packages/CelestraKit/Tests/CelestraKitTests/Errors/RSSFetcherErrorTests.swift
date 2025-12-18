//
//  RSSFetcherErrorTests.swift
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

@testable import CelestraKit

@Suite("RSSFetcherError Tests")
struct RSSFetcherErrorTests {
  @Test("invalidFeedData error has correct description")
  func testInvalidFeedDataDescription() async throws {
    let error = RSSFetcherError.invalidFeedData("Malformed XML")
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description!.contains("Invalid feed data"))
    #expect(description!.contains("Malformed XML"))
  }

  @Test("rssFetchFailed error includes URL and underlying error")
  func testRssFetchFailedDescription() async throws {
    let url = URL(string: "https://example.com/feed.xml")!
    let underlyingError = URLError(.badServerResponse)
    let error = RSSFetcherError.rssFetchFailed(url, underlying: underlyingError)

    let description = error.errorDescription!
    #expect(description.contains("https://example.com/feed.xml"))
    #expect(description.contains("Failed to fetch RSS feed"))
  }

  @Test("Errors conform to LocalizedError")
  func testLocalizedErrorConformance() async throws {
    let error = RSSFetcherError.invalidFeedData("Test")
    let _: any LocalizedError = error  // Compile-time check
    #expect(error.errorDescription != nil)
  }
}
