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
import Logging
import MistKit

enum UpdateCommand {
  @available(macOS 13.0, *)
  static func run(args: [String]) async throws {
    // CommandLineArgumentsProvider automatically parses all arguments
    let loader = ConfigurationLoader()
    let config = try await loader.loadConfiguration()

    print("🔄 Starting feed update...")
    print("   ⏱️  Rate limit: \(config.update.delay) seconds between feeds")
    if config.update.skipRobotsCheck {
      print("   ⚠️  Skipping robots.txt checks")
    }

    // Display filters
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

    // Create services
    let validatedCloudKit = try config.cloudkit.validated()
    let service = try CelestraConfig.createCloudKitService(from: validatedCloudKit)
    let fetcher = RSSFetcherService(userAgent: .cloud(build: 1))
    let robotsService = RobotsTxtService(userAgent: .cloud(build: 1))
    let rateLimiter = RateLimiter(defaultDelay: config.update.delay)

    // Query feeds with filters
    print("📋 Querying feeds...")
    var feeds = try await service.queryFeeds(
      lastAttemptedBefore: config.update.lastAttemptedBefore,
      minPopularity: config.update.minPopularity
    )

    // Filter by failure count if specified
    if let maxFail = config.update.maxFailures {
      feeds = feeds.filter { $0.failureCount <= maxFail }
    }

    print("✅ Found \(feeds.count) feed(s) to update")

    // Process each feed
    var successCount = 0
    var errorCount = 0
    var skippedCount = 0
    var notModifiedCount = 0

    for (index, feed) in feeds.enumerated() {
      print("\n[\(index + 1)/\(feeds.count)] Updating: \(feed.title)")
      print("   URL: \(feed.feedURL)")

      // Check rate limit for this domain
      guard let url = URL(string: feed.feedURL) else {
        print("   ❌ Invalid URL")
        errorCount += 1
        continue
      }

      // Check robots.txt unless skipped
      if !config.update.skipRobotsCheck {
        do {
          let isAllowed = try await robotsService.isAllowed(url)
          if !isAllowed {
            print("   ⏭️  Skipped: robots.txt disallows")
            skippedCount += 1
            continue
          }
        } catch {
          print("   ⚠️  Could not check robots.txt: \(error.localizedDescription)")
          // Continue anyway - failure to fetch robots.txt shouldn't block updates
        }
      }

      // Wait for rate limit
      await rateLimiter.waitIfNeeded(for: url)

      // Track attempt - start with existing values
      let totalAttempts = feed.totalAttempts + 1
      var successfulAttempts = feed.successfulAttempts
      var failureCount = feed.failureCount
      var newEtag = feed.etag
      var newLastModified = feed.lastModified

      do {
        // Fetch feed with conditional request headers
        let response = try await fetcher.fetchFeed(
          from: url,
          lastModified: feed.lastModified,
          etag: feed.etag
        )

        // Handle 304 Not Modified
        guard let feedData = response.feedData else {
          print("   ℹ️  Not modified (304)")
          notModifiedCount += 1
          // Update ETag and Last-Modified even for 304
          newEtag = response.etag ?? feed.etag
          newLastModified = response.lastModified ?? feed.lastModified

          // Update feed metadata
          let updatedFeed = Feed(
            recordName: feed.recordName,
            feedURL: feed.feedURL,
            title: feed.title,
            description: feed.description,
            isFeatured: feed.isFeatured,
            isVerified: feed.isVerified,
            subscriberCount: feed.subscriberCount,
            totalAttempts: totalAttempts,
            successfulAttempts: successfulAttempts + 1,  // 304 counts as success
            lastAttempted: Date(),
            isActive: feed.isActive,
            etag: newEtag,
            lastModified: newLastModified,
            failureCount: 0,  // Reset failure count on successful fetch
            minUpdateInterval: feed.minUpdateInterval
          )
          _ = try await service.updateFeed(recordName: feed.recordName!, feed: updatedFeed)

          successCount += 1
          continue
        }

        print("   ✅ Fetched: \(feedData.items.count) articles")

        // Update ETag and Last-Modified from response
        newEtag = response.etag
        newLastModified = response.lastModified

        // Process articles (create new, update modified)
        let guids = feedData.items.map { $0.guid }
        let existingArticles = try await service.queryArticlesByGUIDs(
          guids, feedRecordName: feed.recordName)
        let existingMap: [String: Article] = Dictionary(
          uniqueKeysWithValues: existingArticles.map { ($0.guid, $0) })

        var newArticles: [Article] = []
        var modifiedArticles: [Article] = []

        for item in feedData.items {
          let article = Article(
            feedRecordName: feed.recordName!,
            guid: item.guid,
            title: item.title,
            excerpt: item.description,
            content: item.content,
            author: item.author,
            url: item.link,
            publishedDate: item.pubDate
          )

          if let existing = existingMap[article.guid] {
            // Check if content changed
            if existing.contentHash != article.contentHash {
              let updated = Article(
                recordName: existing.recordName,
                recordChangeTag: existing.recordChangeTag,
                feedRecordName: article.feedRecordName,
                guid: article.guid,
                title: article.title,
                excerpt: article.excerpt,
                content: article.content,
                author: article.author,
                url: article.url,
                publishedDate: article.publishedDate
              )
              modifiedArticles.append(updated)
            }
          } else {
            newArticles.append(article)
          }
        }

        print("   📝 New: \(newArticles.count), Modified: \(modifiedArticles.count)")

        // Create new articles
        if !newArticles.isEmpty {
          let createResult = try await service.createArticles(newArticles)
          print("   ✅ Created \(createResult.successCount) articles")
          if createResult.failureCount > 0 {
            print("   ⚠️  Failed to create \(createResult.failureCount) articles")
          }
        }

        // Update modified articles
        if !modifiedArticles.isEmpty {
          let updateResult = try await service.updateArticles(modifiedArticles)
          print("   ✅ Updated \(updateResult.successCount) articles")
          if updateResult.failureCount > 0 {
            print("   ⚠️  Failed to update \(updateResult.failureCount) articles")
          }
        }

        // Update feed metadata
        let updatedFeed = Feed(
          recordName: feed.recordName,
          feedURL: feed.feedURL,
          title: feedData.title,  // Update title from feed
          description: feedData.description,  // Update description
          isFeatured: feed.isFeatured,
          isVerified: feed.isVerified,
          subscriberCount: feed.subscriberCount,
          totalAttempts: totalAttempts,
          successfulAttempts: successfulAttempts + 1,
          lastAttempted: Date(),
          isActive: feed.isActive,
          etag: newEtag,
          lastModified: newLastModified,
          failureCount: 0,  // Reset on success
          minUpdateInterval: feedData.minUpdateInterval
        )
        _ = try await service.updateFeed(recordName: feed.recordName!, feed: updatedFeed)

        successCount += 1
      } catch {
        print("   ❌ Error: \(error.localizedDescription)")
        errorCount += 1
        failureCount += 1

        // Update feed with failure
        let updatedFeed = Feed(
          recordName: feed.recordName,
          feedURL: feed.feedURL,
          title: feed.title,
          description: feed.description,
          isFeatured: feed.isFeatured,
          isVerified: feed.isVerified,
          subscriberCount: feed.subscriberCount,
          totalAttempts: totalAttempts,
          successfulAttempts: successfulAttempts,
          lastAttempted: Date(),
          isActive: feed.isActive,
          etag: feed.etag,
          lastModified: feed.lastModified,
          failureCount: failureCount,
          minUpdateInterval: feed.minUpdateInterval
        )
        try? await service.updateFeed(recordName: feed.recordName!, feed: updatedFeed)
      }
    }

    // Summary
    print("\n" + String(repeating: "─", count: 50))
    print("📊 Update Summary")
    print("   Total feeds: \(feeds.count)")
    print("   ✅ Successful: \(successCount)")
    print("   ❌ Errors: \(errorCount)")
    print("   ⏭️  Skipped (robots.txt): \(skippedCount)")
    print("   ℹ️  Not modified (304): \(notModifiedCount)")
  }
}
