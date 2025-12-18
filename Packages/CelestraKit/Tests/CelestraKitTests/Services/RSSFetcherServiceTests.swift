//
//  RSSFetcherServiceTests.swift
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

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("RSSFetcherService Tests", .serialized, .tags(.networkMock))
final class RSSFetcherServiceTests {
  init() {
    mockURLProtocolSemaphore.wait()
  }

  deinit {
    MockURLProtocol.requestHandler = nil
    mockURLProtocolSemaphore.signal()
  }

  // MARK: - fetchFeed() Success Cases

  @Test("Fetch basic RSS feed successfully")
  func fetchBasicRSSFeed() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/basic-rss.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL,
        statusCode: 200,
        httpVersion: nil,
        headerFields: [
          "Content-Type": "application/rss+xml",
          "Last-Modified": "Mon, 01 Jan 2024 12:00:00 GMT",
          "ETag": "\"abc123\"",
        ]
      )!
      return (response, mockData)
    }

    let session = createMockURLSession()
    let service = RSSFetcherService(urlSession: session, userAgent: UserAgent.app(build: 1))

    let result = try await service.fetchFeed(from: feedURL)

    #expect(result.wasModified == true)
    #expect(result.lastModified == "Mon, 01 Jan 2024 12:00:00 GMT")
    #expect(result.etag == "\"abc123\"")
    #expect(result.feedData != nil)
    #expect(result.feedData?.title == "Example RSS Feed")
    #expect(result.feedData?.description == "A sample RSS feed for testing")
    #expect(result.feedData?.items.count == 2)
  }

  @Test("Fetch Atom feed successfully")
  func fetchAtomFeed() async throws {
    let feedURL = URL(string: "https://example.com/atom.xml")!
    let mockData = try FixtureLoader.load("Atom/basic-atom.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/atom+xml"]
      )!
      return (response, mockData)
    }

    let session = createMockURLSession()
    let service = RSSFetcherService(urlSession: session, userAgent: UserAgent.app(build: 1))

    let result = try await service.fetchFeed(from: feedURL)

    #expect(result.wasModified == true)
    #expect(result.feedData != nil)
    #expect(result.feedData?.title == "Example Atom Feed")
    #expect(result.feedData?.items.count == 1)

    let firstItem = try #require(result.feedData?.items.first)
    #expect(firstItem.title == "First Entry")
    #expect(firstItem.author == "Jane Doe")
  }

  @Test("Feed items contain all expected fields")
  func feedItemsContainAllFields() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/basic-rss.xml")

    MockURLProtocol.requestHandler = { _ in
      (
        HTTPURLResponse(
          url: feedURL, statusCode: 200, httpVersion: nil,
          headerFields: nil
        )!, mockData
      )
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let items = try #require(result.feedData?.items)
    #expect(items.count == 2)

    // First item (minimal fields)
    let item1 = items[0]
    #expect(item1.title == "First Post")
    #expect(item1.link == "https://example.com/post/1")
    #expect(item1.description == "This is the first post")
    #expect(item1.guid == "https://example.com/post/1")
    #expect(item1.author == nil)

    // Second item (all fields)
    let item2 = items[1]
    #expect(item2.title == "Second Post")
    #expect(item2.link == "https://example.com/post/2")
    #expect(item2.description == "This is the second post")
    #expect(item2.author == "John Doe")
    #expect(item2.guid == "unique-guid-123")
    #expect(item2.content != nil)
  }

  // MARK: - 304 Not Modified

  @Test("Handle 304 Not Modified response")
  func handle304NotModified() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!

    MockURLProtocol.requestHandler = { request in
      // Verify conditional headers were sent
      #expect(request.value(forHTTPHeaderField: "If-Modified-Since") != nil)
      #expect(request.value(forHTTPHeaderField: "If-None-Match") != nil)

      let response = HTTPURLResponse(
        url: feedURL,
        statusCode: 304,
        httpVersion: nil,
        headerFields: [
          "ETag": "\"abc123\""
        ]
      )!
      return (response, nil)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))

    let result = try await service.fetchFeed(
      from: feedURL,
      lastModified: "Mon, 01 Jan 2024 12:00:00 GMT",
      etag: "\"abc123\""
    )

    #expect(result.wasModified == false)
    #expect(result.feedData == nil)
    #expect(result.etag == "\"abc123\"")
    #expect(result.lastModified == "Mon, 01 Jan 2024 12:00:00 GMT")
  }

  // MARK: - Conditional Headers

  @Test("Send If-Modified-Since header when lastModified provided")
  func sendsIfModifiedSinceHeader() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let expectedLastModified = "Mon, 01 Jan 2024 12:00:00 GMT"

    var headersSent = false
    MockURLProtocol.requestHandler = { request in
      let ifModifiedSince = request.value(forHTTPHeaderField: "If-Modified-Since")
      #expect(ifModifiedSince == expectedLastModified)
      headersSent = true

      let response = HTTPURLResponse(
        url: feedURL, statusCode: 304,
        httpVersion: nil, headerFields: nil
      )!
      return (response, nil)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    _ = try await service.fetchFeed(from: feedURL, lastModified: expectedLastModified)

    #expect(headersSent)
  }

  @Test("Send If-None-Match header when etag provided")
  func sendsIfNoneMatchHeader() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let expectedEtag = "\"abc123\""

    var headersSent = false
    MockURLProtocol.requestHandler = { request in
      let ifNoneMatch = request.value(forHTTPHeaderField: "If-None-Match")
      #expect(ifNoneMatch == expectedEtag)
      headersSent = true

      let response = HTTPURLResponse(
        url: feedURL, statusCode: 304,
        httpVersion: nil, headerFields: nil
      )!
      return (response, nil)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    _ = try await service.fetchFeed(from: feedURL, etag: expectedEtag)

    #expect(headersSent)
  }

  // MARK: - Error Cases

  @Test("Throw error on invalid feed data")
  func throwErrorOnInvalidFeedData() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/invalid-rss.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))

    await #expect(throws: RSSFetcherError.self) {
      try await service.fetchFeed(from: feedURL)
    }
  }

  @Test("Throw error on network failure")
  func throwErrorOnNetworkFailure() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!

    MockURLProtocol.requestHandler = { _ in
      throw URLError(.notConnectedToInternet)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))

    await #expect(throws: RSSFetcherError.self) {
      try await service.fetchFeed(from: feedURL)
    }
  }

  @Test("Throw error on HTTP error status codes")
  func throwErrorOnHTTPErrorStatus() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!

    for statusCode in [400, 404, 500, 503] {
      MockURLProtocol.requestHandler = { _ in
        let response = HTTPURLResponse(
          url: feedURL, statusCode: statusCode,
          httpVersion: nil, headerFields: nil
        )!
        return (response, nil)
      }

      let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))

      await #expect(throws: RSSFetcherError.self) {
        try await service.fetchFeed(from: feedURL)
      }
    }
  }

  // MARK: - Item Filtering

  @Test(
    "All items have valid links", .disabled("SyndiKit doesn't parse RSS with empty link elements"))
  func filterItemsWithEmptyLinks() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/rss-with-empty-link-items.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let items = try #require(result.feedData?.items)

    // Should only have 1 valid item (the other 2 have empty links)
    #expect(items.count == 1)
    #expect(items[0].title == "Valid Item")
    #expect(items[0].link == "https://example.com/valid")
  }

  // MARK: - parseUpdateInterval() - TTL Tests

  @Test("Parse RSS TTL correctly")
  func parseRSSTTL() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/rss-with-ttl.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let interval = try #require(result.feedData?.minUpdateInterval)

    // TTL is 60 minutes = 3600 seconds
    #expect(interval == 3_600.0)
  }

  // MARK: - parseUpdateInterval() - Syndication Tests

  @Test("Parse syndication hourly period")
  func parseSyndicationHourly() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/rss-with-syndication-hourly.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let interval = try #require(result.feedData?.minUpdateInterval)

    // hourly (3600s) / frequency (2) = 1800 seconds (30 minutes)
    #expect(interval == 1_800.0)
  }

  @Test("Parse syndication daily period")
  func parseSyndicationDaily() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/rss-with-syndication-daily.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let interval = try #require(result.feedData?.minUpdateInterval)

    // daily (86400s) / frequency (1) = 86400 seconds
    #expect(interval == 86_400.0)
  }

  @Test("Parse syndication weekly period")
  func parseSyndicationWeekly() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/rss-with-syndication-weekly.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let interval = try #require(result.feedData?.minUpdateInterval)

    // weekly (604800s) / frequency (1) = 604800 seconds
    #expect(interval == 604_800.0)
  }

  @Test("Parse syndication monthly period")
  func parseSyndicationMonthly() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/rss-with-syndication-monthly.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let interval = try #require(result.feedData?.minUpdateInterval)

    // monthly (2592000s ≈ 30 days) / frequency (1) = 2592000 seconds
    #expect(interval == 2_592_000.0)
  }

  @Test("Parse syndication yearly period")
  func parseSyndicationYearly() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/rss-with-syndication-yearly.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let interval = try #require(result.feedData?.minUpdateInterval)

    // yearly (31536000s = 365 days) / frequency (1) = 31536000 seconds
    #expect(interval == 31_536_000.0)
  }

  // MARK: - parseUpdateInterval() - Priority Tests

  @Test("TTL takes priority over syndication module")
  func ttlTakesPriorityOverSyndication() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/rss-with-ttl-and-syndication.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    let interval = try #require(result.feedData?.minUpdateInterval)

    // TTL is 30 minutes (1800s), syndication is daily (86400s)
    // TTL should take priority
    #expect(interval == 1_800.0)
  }

  // MARK: - parseUpdateInterval() - Nil Cases

  @Test("Atom feeds return nil update interval")
  func atomFeedsReturnNilInterval() async throws {
    let feedURL = URL(string: "https://example.com/atom.xml")!
    let mockData = try FixtureLoader.load("Atom/basic-atom.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    // Atom feeds don't support TTL or syndication module
    #expect(result.feedData?.minUpdateInterval == nil)
  }

  @Test("RSS feed without TTL or syndication returns nil")
  func rssFeedWithoutUpdateInfoReturnsNil() async throws {
    let feedURL = URL(string: "https://example.com/feed.xml")!
    let mockData = try FixtureLoader.load("RSS/basic-rss.xml")

    MockURLProtocol.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: feedURL, statusCode: 200,
        httpVersion: nil, headerFields: nil
      )!
      return (response, mockData)
    }

    let service = RSSFetcherService(urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
    let result = try await service.fetchFeed(from: feedURL)

    #expect(result.feedData?.minUpdateInterval == nil)
  }
}
