//
//  FeedUpdateProcessor.swift
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
import MistKit

/// Processes individual feed updates
@available(macOS 13.0, *)
internal struct FeedUpdateProcessor {
  internal let service: CloudKitService
  private let fetcher: RSSFetcherService
  private let robotsService: RobotsTxtService
  private let rateLimiter: RateLimiter
  private let skipRobotsCheck: Bool
  private let categorizer: ArticleCategorizer
  private let metadataBuilder: FeedMetadataBuilder

  internal init(
    service: CloudKitService,
    fetcher: RSSFetcherService,
    robotsService: RobotsTxtService,
    rateLimiter: RateLimiter,
    skipRobotsCheck: Bool,
    categorizer: ArticleCategorizer = ArticleCategorizer(),
    metadataBuilder: FeedMetadataBuilder = FeedMetadataBuilder()
  ) {
    self.service = service
    self.fetcher = fetcher
    self.robotsService = robotsService
    self.rateLimiter = rateLimiter
    self.skipRobotsCheck = skipRobotsCheck
    self.categorizer = categorizer
    self.metadataBuilder = metadataBuilder
  }

  /// Process a single feed update
  internal func processFeed(_ feed: Feed, url: URL) async -> FeedUpdateResult {
    guard let recordName = feed.recordName else {
      print("   ❌ Feed missing recordName")
      return .error
    }

    if !skipRobotsCheck {
      do {
        let isAllowed = try await robotsService.isAllowed(url)
        if !isAllowed {
          print("   ⏭️  Skipped: robots.txt disallows")
          return .skipped
        }
      } catch {
        print("   ⚠️  Could not check robots.txt: \(error.localizedDescription)")
      }
    }

    await rateLimiter.waitIfNeeded(for: url)
    return await fetchAndProcess(feed: feed, url: url, recordName: recordName)
  }

  private func fetchAndProcess(
    feed: Feed,
    url: URL,
    recordName: String
  ) async -> FeedUpdateResult {
    let totalAttempts = feed.totalAttempts + 1

    do {
      let response = try await fetcher.fetchFeed(
        from: url,
        lastModified: feed.lastModified,
        etag: feed.etag
      )

      guard let feedData = response.feedData else {
        print("   ℹ️  Not modified (304)")
        let metadata = metadataBuilder.buildNotModifiedMetadata(
          feed: feed,
          response: response,
          totalAttempts: totalAttempts
        )
        return await updateFeedMetadata(feed: feed, recordName: recordName, metadata: metadata)
      }

      print("   ✅ Fetched: \(feedData.items.count) articles")

      let existingArticles = try await service.queryArticlesByGUIDs(
        feedData.items.map(\.guid),
        feedRecordName: recordName
      )

      let categorization = categorizer.categorize(
        items: feedData.items,
        existingArticles: existingArticles,
        feedRecordName: recordName
      )

      print("   📝 New: \(categorization.new.count), Modified: \(categorization.modified.count)")
      if !categorization.new.isEmpty {
        let result = try await service.createArticles(categorization.new)
        print("   ✅ Created \(result.successCount) articles")
        if result.failureCount > 0 {
          print("   ⚠️  Failed to create \(result.failureCount) articles")
        }
      }
      if !categorization.modified.isEmpty {
        let result = try await service.updateArticles(categorization.modified)
        print("   ✅ Updated \(result.successCount) articles")
        if result.failureCount > 0 {
          print("   ⚠️  Failed to update \(result.failureCount) articles")
        }
      }

      let metadata = metadataBuilder.buildSuccessMetadata(
        feedData: feedData,
        response: response,
        feed: feed,
        totalAttempts: totalAttempts
      )
      return await updateFeedMetadata(feed: feed, recordName: recordName, metadata: metadata)
    } catch {
      print("   ❌ Error: \(error.localizedDescription)")
      let metadata = metadataBuilder.buildErrorMetadata(
        feed: feed,
        totalAttempts: totalAttempts
      )
      _ = await updateFeedMetadata(feed: feed, recordName: recordName, metadata: metadata)
      return .error
    }
  }

  private func updateFeedMetadata(
    feed: Feed,
    recordName: String,
    metadata: FeedMetadataUpdate
  ) async -> FeedUpdateResult {
    let updatedFeed = Feed(
      recordName: feed.recordName,
      feedURL: feed.feedURL,
      title: metadata.title,
      description: metadata.description,
      isFeatured: feed.isFeatured,
      isVerified: feed.isVerified,
      subscriberCount: feed.subscriberCount,
      totalAttempts: metadata.totalAttempts,
      successfulAttempts: metadata.successfulAttempts,
      lastAttempted: Date(),
      isActive: feed.isActive,
      etag: metadata.etag,
      lastModified: metadata.lastModified,
      failureCount: metadata.failureCount,
      minUpdateInterval: metadata.minUpdateInterval
    )
    do {
      _ = try await service.updateFeed(recordName: recordName, feed: updatedFeed)
      return metadata.failureCount == 0 ? .success : .error
    } catch {
      print("   ⚠️  Failed to update feed metadata: \(error.localizedDescription)")
      return .error
    }
  }
}
