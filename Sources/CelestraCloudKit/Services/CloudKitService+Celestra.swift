//
//  CloudKitService+Celestra.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import CelestraKit
public import Foundation
public import Logging
public import MistKit

/// CloudKit service extensions for Celestra operations
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  // MARK: - Feed Operations

  /// Create a new Feed record
  public func createFeed(_ feed: Feed) async throws -> RecordInfo {
    CelestraLogger.cloudkit.info("📝 Creating feed: \(feed.feedURL)")

    let operation = RecordOperation.create(
      recordType: "Feed",
      recordName: UUID().uuidString,
      fields: feed.toFieldsDict()
    )
    let results = try await self.modifyRecords([operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Update an existing Feed record
  public func updateFeed(recordName: String, feed: Feed) async throws -> RecordInfo {
    CelestraLogger.cloudkit.info("🔄 Updating feed: \(feed.feedURL)")

    let operation = RecordOperation.update(
      recordType: "Feed",
      recordName: recordName,
      fields: feed.toFieldsDict(),
      recordChangeTag: feed.recordChangeTag
    )
    let results = try await self.modifyRecords([operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Query feeds with optional filters (demonstrates QueryFilter and QuerySort)
  public func queryFeeds(
    lastAttemptedBefore: Date? = nil,
    minPopularity: Int? = nil,
    limit: Int = 100
  ) async throws -> [Feed] {
    var filters: [QueryFilter] = []

    // Filter by last attempted date if provided
    if let cutoff = lastAttemptedBefore {
      filters.append(.lessThan("attemptedTimestamp", .date(cutoff)))
    }

    // Filter by minimum popularity if provided
    if let minPop = minPopularity {
      filters.append(.greaterThanOrEquals("subscriberCount", .int64(minPop)))
    }

    // Query with filters and sort by feedURL (always queryable+sortable)
    let records = try await queryRecords(
      recordType: "Feed",
      filters: filters.isEmpty ? nil : filters,
      sortBy: [.ascending("feedURL")],  // Use feedURL since usageCount might have issues
      limit: limit
    )

    do {
      return try records.map { try Feed(from: $0) }
    } catch {
      CelestraLogger.errors.error("Failed to convert Feed records: \(error)")
      throw error
    }
  }

  // MARK: - Article Operations

  /// Query existing articles by GUIDs for duplicate detection
  /// - Parameters:
  ///   - guids: Array of article GUIDs to check
  ///   - feedRecordName: Optional feed record name filter to scope the query
  /// - Returns: Array of existing Article records matching the GUIDs
  public func queryArticlesByGUIDs(
    _ guids: [String],
    feedRecordName: String? = nil
  ) async throws -> [Article] {
    guard !guids.isEmpty else {
      return []
    }

    // Batch size: 150 (safe margin below CloudKit's 200 limit)
    let batchSize = 150
    var allArticles: [Article] = []

    // Process GUIDs in batches
    let guidBatches = guids.chunked(into: batchSize)

    for batch in guidBatches {
      var filters: [QueryFilter] = []

      // Add feed filter if provided
      if let feedName = feedRecordName {
        filters.append(.equals("feedRecordName", .string(feedName)))
      }

      // Add GUID IN filter
      let guidValues = batch.map { FieldValue.string($0) }
      filters.append(.in("guid", guidValues))

      // Query with combined filters
      let records = try await queryRecords(
        recordType: "Article",
        filters: filters,
        limit: 200,
        desiredKeys: nil  // Fetch all fields
      )

      // Convert to Article objects, skipping any that fail validation
      for record in records {
        do {
          let article = try Article(from: record)
          allArticles.append(article)
        } catch {
          CelestraLogger.errors.warning(
            "Skipping invalid article record \(record.recordName): \(error)")
          // Continue processing other articles
        }
      }
    }

    return allArticles
  }

  /// Create multiple Article records in batches with retry logic
  /// - Parameter articles: Articles to create
  /// - Returns: Batch operation result with success/failure tracking
  public func createArticles(_ articles: [Article]) async throws -> BatchOperationResult {
    guard !articles.isEmpty else {
      return BatchOperationResult()
    }

    CelestraLogger.cloudkit.info("📦 Creating \(articles.count) article(s)...")

    // Chunk articles into batches of 10 to keep payload size manageable with full content
    let batches = articles.chunked(into: 10)
    var result = BatchOperationResult()

    for (index, batch) in batches.enumerated() {
      CelestraLogger.operations.info(
        "   Batch \(index + 1)/\(batches.count): \(batch.count) article(s)")

      do {
        let operations = batch.map { article in
          RecordOperation.create(
            recordType: "Article",
            recordName: UUID().uuidString,
            fields: article.toFieldsDict()
          )
        }

        let recordInfos = try await self.modifyRecords(operations)

        result.appendSuccesses(recordInfos)
        CelestraLogger.cloudkit.info(
          "   ✅ Batch \(index + 1) complete: \(recordInfos.count) created")
      } catch {
        CelestraLogger.errors.error("   ❌ Batch \(index + 1) failed: \(error.localizedDescription)")

        // Track individual failures
        for article in batch {
          result.appendFailure(article: article, error: error)
        }
      }
    }

    CelestraLogger.cloudkit.info(
      "📊 Batch operation complete: \(result.successCount)/\(result.totalProcessed) succeeded (\(String(format: "%.1f", result.successRate))%)"
    )

    return result
  }

  /// Update multiple Article records in batches with retry logic
  /// - Parameter articles: Articles to update (must have recordName set)
  /// - Returns: Batch operation result with success/failure tracking
  public func updateArticles(_ articles: [Article]) async throws -> BatchOperationResult {
    guard !articles.isEmpty else {
      return BatchOperationResult()
    }

    CelestraLogger.cloudkit.info("🔄 Updating \(articles.count) article(s)...")

    // Filter out articles without recordName
    let validArticles = articles.filter { $0.recordName != nil }
    if validArticles.count != articles.count {
      CelestraLogger.errors.warning(
        "⚠️ Skipping \(articles.count - validArticles.count) article(s) without recordName"
      )
    }

    guard !validArticles.isEmpty else {
      return BatchOperationResult()
    }

    // Chunk articles into batches of 10 to keep payload size manageable with full content
    let batches = validArticles.chunked(into: 10)
    var result = BatchOperationResult()

    for (index, batch) in batches.enumerated() {
      CelestraLogger.operations.info(
        "   Batch \(index + 1)/\(batches.count): \(batch.count) article(s)")

      do {
        let operations = batch.compactMap { article -> RecordOperation? in
          guard let recordName = article.recordName else { return nil }

          return RecordOperation.update(
            recordType: "Article",
            recordName: recordName,
            fields: article.toFieldsDict(),
            recordChangeTag: nil
          )
        }

        let recordInfos = try await self.modifyRecords(operations)

        result.appendSuccesses(recordInfos)
        CelestraLogger.cloudkit.info(
          "   ✅ Batch \(index + 1) complete: \(recordInfos.count) updated")
      } catch {
        CelestraLogger.errors.error("   ❌ Batch \(index + 1) failed: \(error.localizedDescription)")

        // Track individual failures
        for article in batch {
          result.appendFailure(article: article, error: error)
        }
      }
    }

    CelestraLogger.cloudkit.info(
      "📊 Update complete: \(result.successCount)/\(result.totalProcessed) succeeded (\(String(format: "%.1f", result.successRate))%)"
    )

    return result
  }

  // MARK: - Cleanup Operations

  /// Delete all Feed records (paginated)
  public func deleteAllFeeds() async throws {
    var totalDeleted = 0

    while true {
      let feeds = try await queryRecords(
        recordType: "Feed",
        limit: 200,
        desiredKeys: ["___recordID"]
      )

      guard !feeds.isEmpty else {
        break  // No more feeds to delete
      }

      let operations = feeds.map { record in
        RecordOperation.delete(
          recordType: "Feed",
          recordName: record.recordName,
          recordChangeTag: record.recordChangeTag
        )
      }

      _ = try await modifyRecords(operations)
      totalDeleted += feeds.count

      CelestraLogger.operations.info("Deleted \(feeds.count) feeds (total: \(totalDeleted))")

      // If we got fewer than the limit, we're done
      if feeds.count < 200 {
        break
      }
    }

    CelestraLogger.cloudkit.info("✅ Deleted \(totalDeleted) total feeds")
  }

  /// Delete all Article records (paginated)
  public func deleteAllArticles() async throws {
    var totalDeleted = 0

    while true {
      let articles = try await queryRecords(
        recordType: "Article",
        limit: 200,
        desiredKeys: ["___recordID"]
      )

      guard !articles.isEmpty else {
        break  // No more articles to delete
      }

      let operations = articles.map { record in
        RecordOperation.delete(
          recordType: "Article",
          recordName: record.recordName,
          recordChangeTag: record.recordChangeTag
        )
      }

      _ = try await modifyRecords(operations)
      totalDeleted += articles.count

      CelestraLogger.operations.info("Deleted \(articles.count) articles (total: \(totalDeleted))")

      // If we got fewer than the limit, we're done
      if articles.count < 200 {
        break
      }
    }

    CelestraLogger.cloudkit.info("✅ Deleted \(totalDeleted) total articles")
  }
}
