// PublicFeedService.swift
// CelestraCloud
//
// Service for public CloudKit database operations using CelestraKit models
// Created for Celestra on 2025-12-08.
//

import Foundation
import Logging
import MistKit
import CelestraKit

/// Service for managing feeds and articles in CloudKit public database
/// Internal for now - not exposed in public API
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
actor PublicFeedService {
  private let cloudKitService: CloudKitService
  private let logger: Logger

  init(cloudKitService: CloudKitService, logger: Logger = Logger(label: "com.celestra.publicfeed")) {
    self.cloudKitService = cloudKitService
    self.logger = logger
  }

  // MARK: - Feed Operations

  /// Fetch all active feeds from public database
  func fetchActiveFeeds(limit: Int = 100) async throws -> [Feed] {
    logger.info("📥 Fetching active feeds (limit: \(limit))")

    let filters: [QueryFilter] = [
      .equals("isActive", .int64(1))
    ]

    let records = try await cloudKitService.queryRecords(
      recordType: "Feed",
      filters: filters,
      sortBy: [.descending("subscriberCount")],
      limit: limit
    )

    let feeds = records.map { Feed(from: $0) }
    logger.info("✅ Fetched \(feeds.count) active feeds")
    return feeds
  }

  /// Fetch featured feeds
  func fetchFeaturedFeeds(category: String? = nil, limit: Int = 50) async throws -> [Feed] {
    logger.info("📥 Fetching featured feeds (category: \(category ?? "all"), limit: \(limit))")

    var filters: [QueryFilter] = [
      .equals("isFeatured", .int64(1)),
      .equals("isActive", .int64(1))
    ]

    if let category = category {
      filters.append(.equals("category", .string(category)))
    }

    let records = try await cloudKitService.queryRecords(
      recordType: "Feed",
      filters: filters,
      sortBy: [.descending("qualityScore")],
      limit: limit
    )

    let feeds = records.map { Feed(from: $0) }
    logger.info("✅ Fetched \(feeds.count) featured feeds")
    return feeds
  }

  /// Search feeds by URL
  func searchFeeds(byURL urlPattern: String) async throws -> [Feed] {
    logger.info("🔍 Searching feeds by URL: \(urlPattern)")

    let filters: [QueryFilter] = [
      .beginsWith("feedURL", urlPattern)
    ]

    let records = try await cloudKitService.queryRecords(
      recordType: "Feed",
      filters: filters,
      sortBy: [.ascending("feedURL")],
      limit: 100
    )

    let feeds = records.map { Feed(from: $0) }
    logger.info("✅ Found \(feeds.count) feeds matching URL pattern")
    return feeds
  }

  /// Create a new feed record
  func createFeed(_ feed: Feed) async throws -> Feed {
    logger.info("📝 Creating feed: \(feed.feedURL)")

    let operation = RecordOperation.create(
      recordType: "Feed",
      recordName: UUID().uuidString,
      fields: feed.toFieldsDict()
    )

    let results = try await cloudKitService.modifyRecords([operation])
    guard let record = results.first else {
      throw CelestraError.cloudKitOperationFailed("No record returned from create operation")
    }

    let createdFeed = Feed(from: record)
    logger.info("✅ Created feed with recordName: \(record.recordName)")
    return createdFeed
  }

  /// Update an existing feed record
  func updateFeed(_ feed: Feed) async throws -> Feed {
    guard let recordName = feed.recordName else {
      throw CelestraError.invalidRecordName("Feed must have recordName to update")
    }

    logger.info("🔄 Updating feed: \(feed.feedURL)")

    let operation = RecordOperation.update(
      recordType: "Feed",
      recordName: recordName,
      fields: feed.toFieldsDict(),
      recordChangeTag: feed.recordChangeTag
    )

    let results = try await cloudKitService.modifyRecords([operation])
    guard let record = results.first else {
      throw CelestraError.cloudKitOperationFailed("No record returned from update operation")
    }

    let updatedFeed = Feed(from: record)
    logger.info("✅ Updated feed: \(feed.feedURL)")
    return updatedFeed
  }

  // MARK: - Article Operations

  /// Fetch articles for a specific feed
  func fetchArticles(forFeed feedRecordName: String, limit: Int = 50) async throws -> [Article] {
    logger.info("📥 Fetching articles for feed: \(feedRecordName) (limit: \(limit))")

    let filters: [QueryFilter] = [
      .equals("feedRecordName", .string(feedRecordName))
    ]

    let records = try await cloudKitService.queryRecords(
      recordType: "Article",
      filters: filters,
      sortBy: [.descending("publishedDate")],
      limit: limit
    )

    let articles = records.map { Article(from: $0) }
    logger.info("✅ Fetched \(articles.count) articles")
    return articles
  }

  /// Check if article exists by GUID and feed
  func articleExists(guid: String, feedRecordName: String) async throws -> Bool {
    logger.info("🔍 Checking if article exists: \(guid)")

    let filters: [QueryFilter] = [
      .equals("guid", .string(guid)),
      .equals("feedRecordName", .string(feedRecordName))
    ]

    let records = try await cloudKitService.queryRecords(
      recordType: "Article",
      filters: filters,
      sortBy: nil,
      limit: 1
    )

    let exists = !records.isEmpty
    logger.info("\(exists ? "✅" : "❌") Article \(exists ? "exists" : "does not exist")")
    return exists
  }

  /// Query existing articles by GUIDs for duplicate detection
  func queryArticlesByGUIDs(
    _ guids: [String],
    feedRecordName: String? = nil
  ) async throws -> [Article] {
    guard !guids.isEmpty else { return [] }

    logger.info("🔍 Querying \(guids.count) article GUIDs")

    // MistKit doesn't have an IN filter, so we need to query each GUID separately
    // For now, we'll use a simple approach with contains filter if available
    // Otherwise, we'd need to do multiple queries

    var filters: [QueryFilter] = []

    // Add feed filter if provided
    if let feedRecordName = feedRecordName {
      filters.append(.equals("feedRecordName", .string(feedRecordName)))
    }

    // For simplicity, we'll do a broader query and filter in-memory
    // In production, you might want to batch multiple queries
    let records = try await cloudKitService.queryRecords(
      recordType: "Article",
      filters: filters.isEmpty ? nil : filters,
      sortBy: nil,
      limit: min(guids.count * 2, 200)
    )

    let articles = records.map { Article(from: $0) }.filter { guids.contains($0.guid) }
    logger.info("✅ Found \(articles.count) existing articles")
    return articles
  }

  /// Create a new article record
  func createArticle(_ article: Article) async throws -> Article {
    logger.info("📝 Creating article: \(article.title)")

    let operation = RecordOperation.create(
      recordType: "Article",
      recordName: UUID().uuidString,
      fields: article.toFieldsDict()
    )

    let results = try await cloudKitService.modifyRecords([operation])
    guard let record = results.first else {
      throw CelestraError.cloudKitOperationFailed("No record returned from create operation")
    }

    let createdArticle = Article(from: record)
    logger.info("✅ Created article with recordName: \(record.recordName)")
    return createdArticle
  }

  /// Batch create multiple articles
  func createArticles(_ articles: [Article]) async throws -> [Article] {
    guard !articles.isEmpty else { return [] }

    logger.info("📝 Creating \(articles.count) articles")

    let operations = articles.map { article in
      RecordOperation.create(
        recordType: "Article",
        recordName: UUID().uuidString,
        fields: article.toFieldsDict()
      )
    }

    let results = try await cloudKitService.modifyRecords(operations)
    let createdArticles = results.map { Article(from: $0) }

    logger.info("✅ Created \(createdArticles.count) articles")
    return createdArticles
  }

  /// Delete expired articles
  func deleteExpiredArticles(before date: Date = Date()) async throws -> Int {
    logger.info("🗑️ Deleting articles expired before: \(date)")

    let filters: [QueryFilter] = [
      .lessThan("expiresAt", .date(date))
    ]

    let records = try await cloudKitService.queryRecords(
      recordType: "Article",
      filters: filters,
      sortBy: nil,
      limit: 500
    )

    guard !records.isEmpty else {
      logger.info("ℹ️ No expired articles found")
      return 0
    }

    let operations = records.map { record in
      RecordOperation.delete(recordType: "Article", recordName: record.recordName)
    }

    _ = try await cloudKitService.modifyRecords(operations)

    logger.info("✅ Deleted \(records.count) expired articles")
    return records.count
  }

  // MARK: - Statistics

  /// Get feed statistics
  func getFeedStatistics() async throws -> (totalFeeds: Int, activeFeeds: Int, featuredFeeds: Int) {
    logger.info("📊 Fetching feed statistics")

    // Query total feeds
    let allRecords = try await cloudKitService.queryRecords(
      recordType: "Feed",
      filters: nil,
      sortBy: nil,
      limit: 1000
    )

    let allFeeds = allRecords.map { Feed(from: $0) }
    let totalFeeds = allFeeds.count
    let activeFeeds = allFeeds.filter { $0.isActive }.count
    let featuredFeeds = allFeeds.filter { $0.isFeatured }.count

    logger.info("✅ Statistics - Total: \(totalFeeds), Active: \(activeFeeds), Featured: \(featuredFeeds)")
    return (totalFeeds, activeFeeds, featuredFeeds)
  }
}
