//
//  UpdateCommand.swift
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

import CelestraCloudKit
import CelestraKit
import Foundation

/// Tracks update operation statistics
private struct UpdateSummary {
  var successCount = 0
  var errorCount = 0
  var skippedCount = 0
  var notModifiedCount = 0
  var articlesCreated = 0
  var articlesUpdated = 0

  mutating func record(_ result: FeedUpdateResult) {
    switch result {
    case .success(let created, let updated):
      successCount += 1
      articlesCreated += created
      articlesUpdated += updated
    case .notModified:
      notModifiedCount += 1
    case .skipped:
      skippedCount += 1
    case .error:
      errorCount += 1
    }
  }
}

internal enum UpdateCommand {
  @available(macOS 13.0, *)
  internal static func run() async throws {
    let loader = ConfigurationLoader()
    let config = try await loader.loadConfiguration()

    printStartupInfo(config: config)

    let processor = try createProcessor(config: config)
    let feeds = try await queryFeeds(config: config, processor: processor)

    print("✅ Found \(feeds.count) feed(s) to update")

    let summary = await processFeeds(feeds, processor: processor)
    printSummary(feeds: feeds, summary: summary)

    // Fail if any errors occurred
    if summary.errorCount > 0 {
      throw UpdateCommandError(errorCount: summary.errorCount)
    }
  }

  private static func printStartupInfo(config: CelestraConfiguration) {
    print("🔄 Starting feed update...")
    print("   ⏱️  Rate limit: \(config.update.delay) seconds between feeds")
    if config.update.skipRobotsCheck {
      print("   ⚠️  Skipping robots.txt checks")
    }

    if let date = config.update.lastAttemptedBefore {
      let formatter = ISO8601DateFormatter()
      print("   Filter: last attempted before \(formatter.string(from: date))")
    }
    if let minPop = config.update.minPopularity {
      print("   Filter: minimum popularity \(minPop)")
    }
    if let maxFail = config.update.maxFailures {
      print("   Filter: maximum failures \(maxFail)")
    }
    if let limit = config.update.limit {
      print("   Limit: maximum \(limit) feeds")
    }
  }

  @available(macOS 13.0, *)
  private static func createProcessor(
    config: CelestraConfiguration
  ) throws -> FeedUpdateProcessor {
    let validatedCloudKit = try config.cloudkit.validated()
    let service = try CelestraConfig.createCloudKitService(from: validatedCloudKit)
    let fetcher = RSSFetcherService(userAgent: .cloud(build: 1))
    let robotsService = RobotsTxtService(userAgent: .cloud(build: 1))
    let rateLimiter = RateLimiter(defaultDelay: config.update.delay)

    // Create ArticleSyncService
    let articleService = ArticleCloudKitService(recordOperator: service)
    let articleSync = ArticleSyncService(articleService: articleService)

    return FeedUpdateProcessor(
      service: service,
      fetcher: fetcher,
      robotsService: robotsService,
      rateLimiter: rateLimiter,
      skipRobotsCheck: config.update.skipRobotsCheck,
      articleSync: articleSync
    )
  }

  @available(macOS 13.0, *)
  private static func queryFeeds(
    config: CelestraConfiguration,
    processor: FeedUpdateProcessor
  ) async throws -> [Feed] {
    print("📋 Querying feeds...")

    var feeds = try await processor.service.queryFeeds(
      lastAttemptedBefore: config.update.lastAttemptedBefore,
      minPopularity: config.update.minPopularity
    )

    if let maxFail = config.update.maxFailures {
      feeds = feeds.filter { $0.failureCount <= maxFail }
    }

    if let limit = config.update.limit {
      feeds = Array(feeds.prefix(limit))
    }

    return feeds
  }

  @available(macOS 13.0, *)
  private static func processFeeds(
    _ feeds: [Feed],
    processor: FeedUpdateProcessor
  ) async -> UpdateSummary {
    var summary = UpdateSummary()

    for (index, feed) in feeds.enumerated() {
      print("\n[\(index + 1)/\(feeds.count)] Updating: \(feed.title)")
      print("   URL: \(feed.feedURL)")

      guard let url = URL(string: feed.feedURL) else {
        print("   ❌ Invalid URL")
        summary.errorCount += 1
        continue
      }

      let result = await processor.processFeed(feed, url: url)
      summary.record(result)
    }

    return summary
  }

  private static func printSummary(feeds: [Feed], summary: UpdateSummary) {
    print("\n" + String(repeating: "─", count: 50))
    print("📊 Update Summary")
    print("   Total feeds: \(feeds.count)")
    print("   ✅ Successful: \(summary.successCount)")
    print("   ❌ Errors: \(summary.errorCount)")
    print("   ⏭️  Skipped (robots.txt): \(summary.skippedCount)")
    print("   ℹ️  Not modified (304): \(summary.notModifiedCount)")
    if summary.articlesCreated > 0 || summary.articlesUpdated > 0 {
      print("   📝 Articles created: \(summary.articlesCreated)")
      print("   📝 Articles updated: \(summary.articlesUpdated)")
    }
  }
}
