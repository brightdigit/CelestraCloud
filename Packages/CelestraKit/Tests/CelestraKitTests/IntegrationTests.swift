import Foundation
import Testing

@testable import CelestraKit

/// Integration tests for CelestraKit models and package functionality
@Suite("Integration Tests")
struct IntegrationTests {
  // MARK: - Feed-Article Relationship Tests

  @Test("Feed and Article relationship via feedRecordName linkage")
  func feedArticleLinkage() async throws {
    let feed = Feed(
      recordName: "feed-record-123",
      feedURL: "https://example.com/feed.xml",
      title: "Example Feed"
    )

    let article = Article(
      feedRecordName: "feed-record-123",
      guid: "article-1",
      title: "Example Article",
      url: "https://example.com/article1"
    )

    #expect(article.feedRecordName == feed.recordName)
    #expect(feed.id == "feed-record-123")
    #expect(article.id.contains("feed-record-123"))
  }

  @Test("Multiple articles from same feed scenario")
  func multipleArticlesFromSameFeed() async throws {
    let feedRecordName = "feed-record-123"

    let article1 = Article(
      feedRecordName: feedRecordName,
      guid: "article-1",
      title: "Article 1",
      url: "https://example.com/article1"
    )

    let article2 = Article(
      feedRecordName: feedRecordName,
      guid: "article-2",
      title: "Article 2",
      url: "https://example.com/article2"
    )

    let article3 = Article(
      feedRecordName: feedRecordName,
      guid: "article-3",
      title: "Article 3",
      url: "https://example.com/article3"
    )

    #expect(article1.feedRecordName == feedRecordName)
    #expect(article2.feedRecordName == feedRecordName)
    #expect(article3.feedRecordName == feedRecordName)

    // All articles should have different content hashes
    #expect(article1.contentHash != article2.contentHash)
    #expect(article2.contentHash != article3.contentHash)
    #expect(article1.contentHash != article3.contentHash)

    // All articles should NOT be duplicates of each other
    #expect(article1.isDuplicate(of: article2) == false)
    #expect(article2.isDuplicate(of: article3) == false)
    #expect(article1.isDuplicate(of: article3) == false)
  }

  // MARK: - Cache Expiration Tests

  @Test("Cache expiration workflow with TTL boundary testing")
  func cacheExpirationWorkflow() async throws {
    let now = Date()

    // Fresh article (just fetched, 30 day TTL)
    let freshArticle = Article(
      feedRecordName: "feed123",
      guid: "fresh-article",
      title: "Fresh Article",
      url: "https://example.com/fresh",
      fetchedAt: now,
      ttlDays: 30
    )

    // Expiring soon article (fetched 29 days ago, 30 day TTL)
    let expiringSoonArticle = Article(
      feedRecordName: "feed123",
      guid: "expiring-soon",
      title: "Expiring Soon",
      url: "https://example.com/expiring",
      fetchedAt: now.addingTimeInterval(-TimeInterval(29 * 24 * 60 * 60)),
      ttlDays: 30
    )

    // Expired article (fetched 31 days ago, 30 day TTL)
    let expiredArticle = Article(
      feedRecordName: "feed123",
      guid: "expired",
      title: "Expired Article",
      url: "https://example.com/expired",
      fetchedAt: now.addingTimeInterval(-TimeInterval(31 * 24 * 60 * 60)),
      ttlDays: 30
    )

    #expect(freshArticle.isExpired == false)
    #expect(expiringSoonArticle.isExpired == false)
    #expect(expiredArticle.isExpired == true)
  }

  @Test("Cache expiration with different TTL values")
  func cacheExpirationDifferentTTLs() async throws {
    let fetchTime = Date()

    // Short TTL (1 day)
    let shortTTL = Article(
      feedRecordName: "feed123",
      guid: "short-ttl",
      title: "Short TTL",
      url: "https://example.com/short",
      fetchedAt: fetchTime.addingTimeInterval(-TimeInterval(2 * 24 * 60 * 60)),
      ttlDays: 1
    )

    // Medium TTL (7 days)
    let mediumTTL = Article(
      feedRecordName: "feed123",
      guid: "medium-ttl",
      title: "Medium TTL",
      url: "https://example.com/medium",
      fetchedAt: fetchTime.addingTimeInterval(-TimeInterval(2 * 24 * 60 * 60)),
      ttlDays: 7
    )

    // Long TTL (90 days)
    let longTTL = Article(
      feedRecordName: "feed123",
      guid: "long-ttl",
      title: "Long TTL",
      url: "https://example.com/long",
      fetchedAt: fetchTime.addingTimeInterval(-TimeInterval(2 * 24 * 60 * 60)),
      ttlDays: 90
    )

    // All fetched 2 days ago
    #expect(shortTTL.isExpired == true)  // 1 day TTL, fetched 2 days ago
    #expect(mediumTTL.isExpired == false)  // 7 day TTL, fetched 2 days ago
    #expect(longTTL.isExpired == false)  // 90 day TTL, fetched 2 days ago
  }

  // MARK: - Deduplication Tests

  @Test("Content hash deduplication across different feeds")
  func deduplicationAcrossFeeds() async throws {
    // Same article published in two different feeds
    let article1 = Article(
      feedRecordName: "feed-tech",
      guid: "article-123",
      title: "Breaking News",
      url: "https://example.com/news/breaking"
    )

    let article2 = Article(
      feedRecordName: "feed-business",
      guid: "article-123",
      title: "Breaking News",
      url: "https://example.com/news/breaking"
    )

    // Same title, URL, and guid should produce same content hash
    #expect(article1.contentHash == article2.contentHash)
    #expect(article1.isDuplicate(of: article2) == true)
  }

  @Test("Deduplication distinguishes similar but different articles")
  func deduplicationDistinguishesArticles() async throws {
    // Very similar articles but with slight differences
    let article1 = Article(
      feedRecordName: "feed123",
      guid: "article-1",
      title: "Breaking News Today",
      url: "https://example.com/news/today"
    )

    let article2 = Article(
      feedRecordName: "feed123",
      guid: "article-1",
      title: "Breaking News Today",
      url: "https://example.com/news/tomorrow"  // Different URL
    )

    let article3 = Article(
      feedRecordName: "feed123",
      guid: "article-2",  // Different GUID
      title: "Breaking News Today",
      url: "https://example.com/news/today"
    )

    // Different URLs or GUIDs should produce different hashes
    #expect(article1.isDuplicate(of: article2) == false)
    #expect(article1.isDuplicate(of: article3) == false)
    #expect(article2.isDuplicate(of: article3) == false)
  }

  // MARK: - Feed Health and Article Expiration Combined

  @Test("Feed health correlates with article freshness scenario")
  func feedHealthAndArticleFreshness() async throws {
    let now = Date()

    // Healthy feed with high success rate
    let healthyFeed = Feed(
      recordName: "healthy-feed",
      feedURL: "https://example.com/healthy.xml",
      title: "Healthy Feed",
      qualityScore: 90,
      totalAttempts: 100,
      successfulAttempts: 95,
      failureCount: 1
    )

    // Unhealthy feed with low success rate
    let unhealthyFeed = Feed(
      recordName: "unhealthy-feed",
      feedURL: "https://example.com/unhealthy.xml",
      title: "Unhealthy Feed",
      qualityScore: 30,
      totalAttempts: 100,
      successfulAttempts: 60,
      failureCount: 10
    )

    // Fresh article from healthy feed
    let freshArticle = Article(
      feedRecordName: "healthy-feed",
      guid: "fresh-1",
      title: "Fresh Article",
      url: "https://example.com/fresh",
      fetchedAt: now,
      ttlDays: 30
    )

    // Stale article from unhealthy feed
    let staleArticle = Article(
      feedRecordName: "unhealthy-feed",
      guid: "stale-1",
      title: "Stale Article",
      url: "https://example.com/stale",
      fetchedAt: now.addingTimeInterval(-TimeInterval(35 * 24 * 60 * 60)),
      ttlDays: 30
    )

    #expect(healthyFeed.isHealthy == true)
    #expect(unhealthyFeed.isHealthy == false)
    #expect(freshArticle.isExpired == false)
    #expect(staleArticle.isExpired == true)

    // Verify relationships
    #expect(freshArticle.feedRecordName == healthyFeed.recordName)
    #expect(staleArticle.feedRecordName == unhealthyFeed.recordName)
  }
}
