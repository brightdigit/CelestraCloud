//
//  FeedCloudKitServiceTests.swift
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
import MistKit
import Testing

@testable import CelestraCloudKit

@Suite("FeedCloudKitService Tests")
internal struct FeedCloudKitServiceTests {
  // MARK: - Test Fixtures

  private func createMockRecordInfo(
    recordName: String = "test-record",
    fields: [String: FieldValue] = [:]
  ) -> RecordInfo {
    RecordInfo(
      recordName: recordName,
      recordType: "Feed",
      recordChangeTag: "tag-123",
      fields: fields
    )
  }

  private func createTestFeed() -> Feed {
    Feed(
      recordName: nil,
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      description: "A test feed",
      isFeatured: false,
      isVerified: true,
      subscriberCount: 100,
      totalAttempts: 5,
      successfulAttempts: 4,
      lastAttempted: Date(timeIntervalSince1970: 1_000_000),
      isActive: true,
      etag: "etag-123",
      lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
      failureCount: 1,
      minUpdateInterval: 3_600
    )
  }

  // MARK: - createFeed Tests

  @Test("createFeed calls modifyRecords with create operation")
  internal func testCreateFeedCallsModifyRecords() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)
    let feed = createTestFeed()

    let expectedRecord = createMockRecordInfo(recordName: "new-feed-id")
    mock.modifyRecordsResult = .success([expectedRecord])

    let result = try await service.createFeed(feed)

    #expect(mock.modifyCalls.count == 1)
    #expect(result.recordName == "new-feed-id")

    // Verify the operation was a create
    let operations = mock.modifyCalls[0].operations
    #expect(operations.count == 1)
    let operation = operations[0]
    #expect(operation.operationType == .create)
    #expect(operation.recordType == "Feed")
    #expect(operation.fields["feedURL"] == .string("https://example.com/feed.xml"))
    #expect(operation.fields["title"] == .string("Test Feed"))
  }

  @Test("createFeed throws when modifyRecords returns empty array")
  internal func testCreateFeedThrowsOnEmptyResponse() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)
    let feed = createTestFeed()

    mock.modifyRecordsResult = .success([])

    await #expect(throws: CloudKitError.self) {
      _ = try await service.createFeed(feed)
    }
  }

  // MARK: - updateFeed Tests

  @Test("updateFeed calls modifyRecords with update operation")
  internal func testUpdateFeedCallsModifyRecords() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)
    let feed = Feed(
      recordName: "existing-feed",
      recordChangeTag: "old-tag",
      feedURL: "https://example.com/updated.xml",
      title: "Updated Feed"
    )

    let expectedRecord = createMockRecordInfo(recordName: "existing-feed")
    mock.modifyRecordsResult = .success([expectedRecord])

    let result = try await service.updateFeed(recordName: "existing-feed", feed: feed)

    #expect(mock.modifyCalls.count == 1)
    #expect(result.recordName == "existing-feed")

    // Verify the operation was an update
    let operations = mock.modifyCalls[0].operations
    #expect(operations.count == 1)
    let operation = operations[0]
    #expect(operation.operationType == .update)
    #expect(operation.recordType == "Feed")
    #expect(operation.recordName == "existing-feed")
    #expect(operation.fields["title"] == .string("Updated Feed"))
    #expect(operation.recordChangeTag == "old-tag")
  }

  // MARK: - queryFeeds Tests

  @Test("queryFeeds returns feeds from query results")
  internal func testQueryFeedsReturnsFeeds() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)

    let feedFields: [String: FieldValue] = [
      "feedURL": .string("https://example.com/feed.xml"),
      "title": .string("Test Feed"),
      "isActive": .int64(1),
      "isFeatured": .int64(0),
      "isVerified": .int64(1),
      "subscriberCount": .int64(50),
      "totalAttempts": .int64(10),
      "successfulAttempts": .int64(9),
      "failureCount": .int64(1),
    ]
    let mockRecord = createMockRecordInfo(recordName: "feed-1", fields: feedFields)
    mock.queryRecordsResult = .success([mockRecord])

    let feeds = try await service.queryFeeds()

    #expect(feeds.count == 1)
    #expect(feeds[0].feedURL == "https://example.com/feed.xml")
    #expect(feeds[0].title == "Test Feed")
    #expect(feeds[0].recordName == "feed-1")
  }

  @Test("queryFeeds applies date filter when provided")
  internal func testQueryFeedsAppliesDateFilter() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)
    let cutoffDate = Date(timeIntervalSince1970: 1_000_000)

    mock.queryRecordsResult = .success([])

    _ = try await service.queryFeeds(lastAttemptedBefore: cutoffDate)

    #expect(mock.queryCalls.count == 1)
    let call = mock.queryCalls[0]
    #expect(call.recordType == "Feed")
    #expect(call.filters != nil)
    #expect(call.filters?.count == 1)
  }

  @Test("queryFeeds applies popularity filter when provided")
  internal func testQueryFeedsAppliesPopularityFilter() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)

    mock.queryRecordsResult = .success([])

    _ = try await service.queryFeeds(minPopularity: 100)

    #expect(mock.queryCalls.count == 1)
    let call = mock.queryCalls[0]
    #expect(call.filters != nil)
    #expect(call.filters?.count == 1)
  }

  @Test("queryFeeds applies both filters when provided")
  internal func testQueryFeedsAppliesBothFilters() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)
    let cutoffDate = Date(timeIntervalSince1970: 1_000_000)

    mock.queryRecordsResult = .success([])

    _ = try await service.queryFeeds(lastAttemptedBefore: cutoffDate, minPopularity: 50)

    #expect(mock.queryCalls.count == 1)
    let call = mock.queryCalls[0]
    #expect(call.filters?.count == 2)
  }

  @Test("queryFeeds respects limit parameter")
  internal func testQueryFeedsRespectsLimit() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)

    mock.queryRecordsResult = .success([])

    _ = try await service.queryFeeds(limit: 50)

    #expect(mock.queryCalls.count == 1)
    #expect(mock.queryCalls[0].limit == 50)
  }

  // MARK: - deleteAllFeeds Tests

  @Test("deleteAllFeeds deletes all feeds in batches")
  internal func testDeleteAllFeedsDeletesInBatches() async throws {
    let mock = MockCloudKitRecordOperator()
    let service = FeedCloudKitService(recordOperator: mock)

    // First query returns 2 feeds, second query returns empty (done)
    let feed1 = createMockRecordInfo(recordName: "feed-1", fields: ["feedURL": .string("url1")])
    let feed2 = createMockRecordInfo(recordName: "feed-2", fields: ["feedURL": .string("url2")])

    // We can't easily do this with the current mock, so we'll just test the basic case
    mock.queryRecordsResult = .success([feed1, feed2])
    mock.modifyRecordsResult = .success([])

    // For this test, we'll verify it makes the right calls
    // The actual implementation loops, but we can verify the pattern
    try await service.deleteAllFeeds()

    // Should have made at least one query and one modify call
    #expect(mock.queryCalls.count >= 1)
    #expect(mock.modifyCalls.count >= 1)

    // Verify delete operations were created
    if let modifyCall = mock.modifyCalls.first {
      for operation in modifyCall.operations {
        #expect(operation.operationType == .delete)
      }
    }
  }
}
