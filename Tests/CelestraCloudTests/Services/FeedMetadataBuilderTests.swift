//
//  FeedMetadataBuilderTests.swift
//  CelestraCloud
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

import CelestraKit
import Foundation
import Testing

@testable import CelestraCloudKit

@Suite("FeedMetadataBuilder Tests")
internal struct FeedMetadataBuilderTests {
  // MARK: - Test Fixtures

  private func createFeed(
    title: String = "Original Title",
    description: String? = "Original Description",
    etag: String? = "original-etag",
    lastModified: String? = "Mon, 01 Jan 2024 00:00:00 GMT",
    minUpdateInterval: TimeInterval? = 3_600,
    totalAttempts: Int64 = 10,
    successfulAttempts: Int64 = 8,
    failureCount: Int64 = 2
  ) -> Feed {
    Feed(
      recordName: "feed-123",
      feedURL: "https://example.com/feed.xml",
      title: title,
      description: description,
      totalAttempts: totalAttempts,
      successfulAttempts: successfulAttempts,
      etag: etag,
      lastModified: lastModified,
      failureCount: failureCount,
      minUpdateInterval: minUpdateInterval
    )
  }

  private func createFeedData(
    title: String = "New Feed Title",
    description: String? = "New Feed Description",
    minUpdateInterval: TimeInterval? = 7_200
  ) -> FeedData {
    FeedData(
      title: title,
      description: description,
      items: [],  // Not used in metadata building
      minUpdateInterval: minUpdateInterval
    )
  }

  private func createFetchResponse(
    feedData: FeedData? = nil,
    etag: String? = "new-etag",
    lastModified: String? = "Tue, 02 Jan 2024 00:00:00 GMT"
  ) -> FetchResponse {
    FetchResponse(
      feedData: feedData,
      lastModified: lastModified,
      etag: etag,
      wasModified: feedData != nil
    )
  }

  // MARK: - Success Metadata Tests

  @Test("Success metadata uses new feed data")
  internal func testSuccessMetadataUsesNewData() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed()
    let feedData = createFeedData(
      title: "Updated Title",
      description: "Updated Description",
      minUpdateInterval: 7_200
    )
    let response = createFetchResponse(
      feedData: feedData,
      etag: "new-etag-123",
      lastModified: "Wed, 03 Jan 2024 12:00:00 GMT"
    )

    let metadata = builder.buildSuccessMetadata(
      feedData: feedData,
      response: response,
      feed: feed,
      totalAttempts: 11
    )

    // New feed data should override
    #expect(metadata.title == "Updated Title")
    #expect(metadata.description == "Updated Description")
    #expect(metadata.minUpdateInterval == 7_200)

    // HTTP headers from response
    #expect(metadata.etag == "new-etag-123")
    #expect(metadata.lastModified == "Wed, 03 Jan 2024 12:00:00 GMT")

    // Counters
    #expect(metadata.totalAttempts == 11)
    #expect(metadata.successfulAttempts == 9)  // 8 + 1
    #expect(metadata.failureCount == 0)  // Reset on success
  }

  @Test("Success metadata increments successful attempts")
  internal func testSuccessIncrementsSuccessfulAttempts() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed(successfulAttempts: 5)
    let feedData = createFeedData()
    let response = createFetchResponse(feedData: feedData)

    let metadata = builder.buildSuccessMetadata(
      feedData: feedData,
      response: response,
      feed: feed,
      totalAttempts: 11
    )

    #expect(metadata.successfulAttempts == 6)  // 5 + 1
  }

  @Test("Success metadata resets failure count")
  internal func testSuccessResetsFailureCount() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed(failureCount: 5)
    let feedData = createFeedData()
    let response = createFetchResponse(feedData: feedData)

    let metadata = builder.buildSuccessMetadata(
      feedData: feedData,
      response: response,
      feed: feed,
      totalAttempts: 11
    )

    #expect(metadata.failureCount == 0)  // Always reset on success
  }

  // MARK: - Not Modified Metadata Tests

  @Test("Not modified metadata preserves feed data")
  internal func testNotModifiedPreservesFeedData() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed(
      title: "Original Title",
      description: "Original Description",
      minUpdateInterval: 3_600
    )
    let response = createFetchResponse(
      feedData: nil,  // 304 response has no feed data
      etag: "updated-etag",
      lastModified: "Thu, 04 Jan 2024 00:00:00 GMT"
    )

    let metadata = builder.buildNotModifiedMetadata(
      feed: feed,
      response: response,
      totalAttempts: 11
    )

    // Feed data should be preserved
    #expect(metadata.title == "Original Title")
    #expect(metadata.description == "Original Description")
    #expect(metadata.minUpdateInterval == 3_600)

    // HTTP headers updated from response
    #expect(metadata.etag == "updated-etag")
    #expect(metadata.lastModified == "Thu, 04 Jan 2024 00:00:00 GMT")
  }

  @Test("Not modified metadata updates HTTP headers if provided")
  internal func testNotModifiedUpdatesHTTPHeaders() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed(
      etag: "old-etag",
      lastModified: "Old-Date"
    )
    let response = createFetchResponse(
      feedData: nil,
      etag: "new-etag",
      lastModified: "New-Date"
    )

    let metadata = builder.buildNotModifiedMetadata(
      feed: feed,
      response: response,
      totalAttempts: 11
    )

    #expect(metadata.etag == "new-etag")
    #expect(metadata.lastModified == "New-Date")
  }

  @Test("Not modified metadata keeps existing headers if none provided")
  internal func testNotModifiedKeepsExistingHeadersIfNoneProvided() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed(
      etag: "existing-etag",
      lastModified: "existing-date"
    )
    let response = createFetchResponse(
      feedData: nil,
      etag: nil,
      lastModified: nil
    )

    let metadata = builder.buildNotModifiedMetadata(
      feed: feed,
      response: response,
      totalAttempts: 11
    )

    #expect(metadata.etag == "existing-etag")
    #expect(metadata.lastModified == "existing-date")
  }

  @Test("Not modified counts as successful attempt")
  internal func testNotModifiedCountsAsSuccess() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed(
      successfulAttempts: 10,
      failureCount: 3
    )
    let response = createFetchResponse(feedData: nil)

    let metadata = builder.buildNotModifiedMetadata(
      feed: feed,
      response: response,
      totalAttempts: 14
    )

    #expect(metadata.successfulAttempts == 11)  // 10 + 1
    #expect(metadata.failureCount == 0)  // Reset on success
  }

  // MARK: - Error Metadata Tests

  @Test("Error metadata preserves all feed data")
  internal func testErrorMetadataPreservesAllData() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed(
      title: "Feed Title",
      description: "Feed Description",
      etag: "feed-etag",
      lastModified: "feed-date",
      minUpdateInterval: 1_800
    )

    let metadata = builder.buildErrorMetadata(
      feed: feed,
      totalAttempts: 11
    )

    // Everything preserved
    #expect(metadata.title == "Feed Title")
    #expect(metadata.description == "Feed Description")
    #expect(metadata.etag == "feed-etag")
    #expect(metadata.lastModified == "feed-date")
    #expect(metadata.minUpdateInterval == 1_800)
  }

  @Test("Error metadata increments failure count")
  internal func testErrorIncrementsFailureCount() {
    let builder = FeedMetadataBuilder()
    let feed = createFeed(
      successfulAttempts: 8,
      failureCount: 2
    )

    let metadata = builder.buildErrorMetadata(
      feed: feed,
      totalAttempts: 11
    )

    #expect(metadata.successfulAttempts == 8)  // No change on error
    #expect(metadata.failureCount == 3)  // 2 + 1
    #expect(metadata.totalAttempts == 11)
  }
}
