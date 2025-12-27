//
//  ArticleCloudKitService.swift
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
import Logging
public import MistKit

/// Service for Article-related CloudKit operations with dependency injection support
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct ArticleCloudKitService: Sendable {
  private let recordOperator: any CloudKitRecordOperating

  /// Initialize with a CloudKit record operator
  /// - Parameter recordOperator: The record operator to use for CloudKit operations
  public init(recordOperator: any CloudKitRecordOperating) {
    self.recordOperator = recordOperator
  }

  // MARK: - Query Operations

  /// Query existing articles by GUIDs for duplicate detection
  /// - Parameters:
  ///   - guids: Array of article GUIDs to check
  ///   - feedRecordName: Optional feed record name filter to scope the query
  /// - Returns: Array of existing Article records matching the GUIDs
  public func queryArticlesByGUIDs(
    _ guids: [String],
    feedRecordName: String? = nil
  ) async throws(CloudKitError) -> [Article] {
    guard !guids.isEmpty else {
      return []
    }

    // Batch size: 150 (safe margin below CloudKit's 200 limit)
    let batchSize = 150
    var allArticles: [Article] = []

    let guidBatches = guids.chunked(into: batchSize)

    for batch in guidBatches {
      var filters: [QueryFilter] = []

      if let feedName = feedRecordName {
        filters.append(.equals("feedRecordName", .string(feedName)))
      }

      let guidValues = batch.map { FieldValue.string($0) }
      filters.append(.in("guid", guidValues))

      let records = try await recordOperator.queryRecords(
        recordType: "Article",
        filters: filters,
        sortBy: nil,
        limit: 200,
        desiredKeys: nil
      )

      for record in records {
        do {
          let article = try Article(from: record)
          allArticles.append(article)
        } catch {
          CelestraLogger.errors.warning(
            "Skipping invalid article record \(record.recordName): \(error)"
          )
        }
      }
    }

    return allArticles
  }

  // MARK: - Create Operations

  /// Create multiple Article records in batches
  /// - Parameter articles: Articles to create
  /// - Returns: Batch operation result with success/failure tracking
  public func createArticles(_ articles: [Article]) async throws(CloudKitError)
    -> BatchOperationResult
  {
    guard !articles.isEmpty else {
      return BatchOperationResult()
    }

    CelestraLogger.cloudkit.info("Creating \(articles.count) article(s)...")

    let batches = articles.chunked(into: 10)
    var result = BatchOperationResult()

    for (index, batch) in batches.enumerated() {
      CelestraLogger.operations.info(
        "   Batch \(index + 1)/\(batches.count): \(batch.count) article(s)"
      )

      do {
        let operations = batch.map { article in
          RecordOperation.create(
            recordType: "Article",
            recordName: UUID().uuidString,
            fields: article.toFieldsDict()
          )
        }

        let recordInfos = try await recordOperator.modifyRecords(operations)

        result.appendSuccesses(recordInfos)
        CelestraLogger.cloudkit.info(
          "   Batch \(index + 1) complete: \(recordInfos.count) created"
        )
      } catch {
        CelestraLogger.errors.error("   Batch \(index + 1) failed: \(error.localizedDescription)")

        for article in batch {
          result.appendFailure(article: article, error: error)
        }
      }
    }

    let rate = String(format: "%.1f", result.successRate)
    CelestraLogger.cloudkit.info(
      "Batch complete: \(result.successCount)/\(result.totalProcessed) (\(rate)%)"
    )
    return result
  }

  // MARK: - Update Operations

  /// Update multiple Article records in batches
  /// - Parameter articles: Articles to update (must have recordName set)
  /// - Returns: Batch operation result with success/failure tracking
  public func updateArticles(_ articles: [Article]) async throws(CloudKitError)
    -> BatchOperationResult
  {
    guard !articles.isEmpty else {
      return BatchOperationResult()
    }

    CelestraLogger.cloudkit.info("Updating \(articles.count) article(s)...")

    let validArticles = articles.filter { $0.recordName != nil }
    if validArticles.count != articles.count {
      CelestraLogger.errors.warning(
        "Skipping \(articles.count - validArticles.count) article(s) without recordName"
      )
    }

    guard !validArticles.isEmpty else {
      return BatchOperationResult()
    }

    let batches = validArticles.chunked(into: 10)
    var result = BatchOperationResult()

    for (index, batch) in batches.enumerated() {
      CelestraLogger.operations.info(
        "   Batch \(index + 1)/\(batches.count): \(batch.count) article(s)"
      )

      do {
        let operations = batch.compactMap { article -> RecordOperation? in
          guard let recordName = article.recordName else {
            return nil
          }

          return RecordOperation.update(
            recordType: "Article",
            recordName: recordName,
            fields: article.toFieldsDict(),
            recordChangeTag: nil
          )
        }

        let recordInfos = try await recordOperator.modifyRecords(operations)

        result.appendSuccesses(recordInfos)
        CelestraLogger.cloudkit.info(
          "   Batch \(index + 1) complete: \(recordInfos.count) updated"
        )
      } catch {
        CelestraLogger.errors.error("   Batch \(index + 1) failed: \(error.localizedDescription)")

        for article in batch {
          result.appendFailure(article: article, error: error)
        }
      }
    }

    let updateRateFormatted = String(format: "%.1f", result.successRate)
    let updateSummary = "\(result.successCount)/\(result.totalProcessed) succeeded"
    CelestraLogger.cloudkit.info("Update complete: \(updateSummary) (\(updateRateFormatted)%)")

    return result
  }

  // MARK: - Delete Operations

  /// Delete all Article records (paginated)
  public func deleteAllArticles() async throws(CloudKitError) {
    var totalDeleted = 0

    while true {
      let articles = try await recordOperator.queryRecords(
        recordType: "Article",
        filters: nil,
        sortBy: nil,
        limit: 200,
        desiredKeys: ["___recordID"]
      )

      guard !articles.isEmpty else {
        break
      }

      let operations = articles.map { record in
        RecordOperation.delete(
          recordType: "Article",
          recordName: record.recordName,
          recordChangeTag: record.recordChangeTag
        )
      }

      _ = try await recordOperator.modifyRecords(operations)
      totalDeleted += articles.count

      CelestraLogger.operations.info("Deleted \(articles.count) articles (total: \(totalDeleted))")

      if articles.count < 200 {
        break
      }
    }

    CelestraLogger.cloudkit.info("Deleted \(totalDeleted) total articles")
  }
}
