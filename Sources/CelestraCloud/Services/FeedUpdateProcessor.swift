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

/// Result of processing a single feed update
internal enum FeedUpdateResult {
  case success
  case notModified
  case skipped
  case error
}

/// Metadata for updating a feed record
private struct FeedMetadataUpdate {
  let title: String
  let description: String?
  let etag: String?
  let lastModified: String?
  let minUpdateInterval: TimeInterval?
  let totalAttempts: Int64
  let successfulAttempts: Int64
  let failureCount: Int64
}

/// Processes individual feed updates
@available(macOS 13.0, *)
internal struct FeedUpdateProcessor {
  internal let service: CloudKitService
  private let fetcher: RSSFetcherService
  private let robotsService: RobotsTxtService
  private let rateLimiter: RateLimiter
  private let skipRobotsCheck: Bool

  internal init(
    service: CloudKitService,
    fetcher: RSSFetcherService,
    robotsService: RobotsTxtService,
    rateLimiter: RateLimiter,
    skipRobotsCheck: Bool
  ) {
    self.service = service
    self.fetcher = fetcher
    self.robotsService = robotsService
    self.rateLimiter = rateLimiter
    self.skipRobotsCheck = skipRobotsCheck
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
        let metadata = FeedMetadataUpdate(
          title: feed.title,
          description: feed.description,
          etag: response.etag ?? feed.etag,
          lastModified: response.lastModified ?? feed.lastModified,
          minUpdateInterval: feed.minUpdateInterval,
          totalAttempts: totalAttempts,
          successfulAttempts: feed.successfulAttempts + 1,
          failureCount: 0
        )
        return await updateFeedMetadata(feed: feed, recordName: recordName, metadata: metadata)
      }

      print("   ✅ Fetched: \(feedData.items.count) articles")
      let guids = feedData.items.map { $0.guid }
      let existingArticles = try await service.queryArticlesByGUIDs(
        guids,
        feedRecordName: recordName
      )
      let existingMap = Dictionary(uniqueKeysWithValues: existingArticles.map { ($0.guid, $0) })

      var newArticles: [Article] = []
      var modifiedArticles: [Article] = []

      for item in feedData.items {
        let article = Article(
          feedRecordName: recordName,
          guid: item.guid,
          title: item.title,
          excerpt: item.description,
          content: item.content,
          author: item.author,
          url: item.link,
          publishedDate: item.pubDate
        )
        if let existing = existingMap[article.guid] {
          if existing.contentHash != article.contentHash {
            modifiedArticles.append(
              Article(
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
            )
          }
        } else {
          newArticles.append(article)
        }
      }

      print("   📝 New: \(newArticles.count), Modified: \(modifiedArticles.count)")
      if !newArticles.isEmpty {
        let result = try await service.createArticles(newArticles)
        print("   ✅ Created \(result.successCount) articles")
        if result.failureCount > 0 {
          print("   ⚠️  Failed to create \(result.failureCount) articles")
        }
      }
      if !modifiedArticles.isEmpty {
        let result = try await service.updateArticles(modifiedArticles)
        print("   ✅ Updated \(result.successCount) articles")
        if result.failureCount > 0 {
          print("   ⚠️  Failed to update \(result.failureCount) articles")
        }
      }

      let metadata = FeedMetadataUpdate(
        title: feedData.title,
        description: feedData.description,
        etag: response.etag,
        lastModified: response.lastModified,
        minUpdateInterval: feedData.minUpdateInterval,
        totalAttempts: totalAttempts,
        successfulAttempts: feed.successfulAttempts + 1,
        failureCount: 0
      )
      return await updateFeedMetadata(feed: feed, recordName: recordName, metadata: metadata)
    } catch {
      print("   ❌ Error: \(error.localizedDescription)")
      let metadata = FeedMetadataUpdate(
        title: feed.title,
        description: feed.description,
        etag: feed.etag,
        lastModified: feed.lastModified,
        minUpdateInterval: feed.minUpdateInterval,
        totalAttempts: totalAttempts,
        successfulAttempts: feed.successfulAttempts,
        failureCount: feed.failureCount + 1
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
