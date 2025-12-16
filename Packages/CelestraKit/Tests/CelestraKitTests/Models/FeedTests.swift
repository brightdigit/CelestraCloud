import Foundation
import Testing

@testable import CelestraKit

/// Comprehensive tests for Feed model
@Suite("Feed Model Tests")
struct FeedTests {
  // MARK: - Initialization Tests

  @Test("Initialize with minimal parameters")
  func initializeMinimal() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Example Feed"
    )

    #expect(feed.feedURL == "https://example.com/feed.xml")
    #expect(feed.title == "Example Feed")
    #expect(feed.description == nil)
    #expect(feed.category == nil)
    #expect(feed.isFeatured == false)
    #expect(feed.isVerified == false)
    #expect(feed.qualityScore == 50)
    #expect(feed.subscriberCount == 0)
    #expect(feed.tags.isEmpty)
    #expect(feed.totalAttempts == 0)
    #expect(feed.successfulAttempts == 0)
    #expect(feed.isActive == true)
  }

  @Test("Initialize with all parameters")
  func initializeComplete() async throws {
    let now = Date()
    let feed = Feed(
      recordName: "record123",
      recordChangeTag: "tag456",
      feedURL: "https://example.com/feed.xml",
      title: "Complete Feed",
      description: "A fully featured feed",
      category: "technology",
      imageURL: "https://example.com/image.png",
      siteURL: "https://example.com",
      language: "en",
      isFeatured: true,
      isVerified: true,
      qualityScore: 95,
      subscriberCount: 1_000,
      addedAt: now,
      lastVerified: now,
      updateFrequency: 3_600,
      tags: ["swift", "ios", "programming"],
      totalAttempts: 100,
      successfulAttempts: 95,
      lastAttempted: now,
      isActive: true,
      etag: "etag123",
      lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
      failureCount: 5,
      lastFailureReason: "Timeout",
      minUpdateInterval: 1_800
    )

    #expect(feed.recordName == "record123")
    #expect(feed.recordChangeTag == "tag456")
    #expect(feed.description == "A fully featured feed")
    #expect(feed.category == "technology")
    #expect(feed.isFeatured == true)
    #expect(feed.isVerified == true)
    #expect(feed.qualityScore == 95)
    #expect(feed.subscriberCount == 1_000)
    #expect(feed.tags.count == 3)
    #expect(feed.totalAttempts == 100)
    #expect(feed.successfulAttempts == 95)
  }

  @Test("Initialize with nil optional fields")
  func initializeWithNils() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Feed with Nils",
      description: nil,
      category: nil,
      imageURL: nil,
      siteURL: nil,
      language: nil,
      lastVerified: nil,
      updateFrequency: nil,
      lastAttempted: nil,
      etag: nil,
      lastModified: nil,
      lastFailureReason: nil,
      minUpdateInterval: nil
    )

    #expect(feed.description == nil)
    #expect(feed.category == nil)
    #expect(feed.lastVerified == nil)
    #expect(feed.etag == nil)
    #expect(feed.lastModified == nil)
  }

  @Test("Initialize with empty arrays and strings")
  func initializeWithEmptyValues() async throws {
    let feed = Feed(
      feedURL: "",
      title: "",
      tags: []
    )

    #expect(feed.feedURL.isEmpty)
    #expect(feed.title.isEmpty)
    #expect(feed.tags.isEmpty)
  }

  @Test("Initialize with boundary quality score values")
  func initializeBoundaryValues() async throws {
    let feed1 = Feed(
      feedURL: "https://example.com/feed1.xml",
      title: "Feed 1",
      qualityScore: 0
    )
    #expect(feed1.qualityScore == 0)

    let feed2 = Feed(
      feedURL: "https://example.com/feed2.xml",
      title: "Feed 2",
      qualityScore: 100
    )
    #expect(feed2.qualityScore == 100)
  }

  // MARK: - Computed Properties Tests

  @Test("ID returns recordName when available")
  func idReturnsRecordName() async throws {
    let feed = Feed(
      recordName: "record123",
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed"
    )

    #expect(feed.id == "record123")
  }

  @Test("ID returns feedURL when recordName is nil")
  func idReturnsFeedURL() async throws {
    let feed = Feed(
      recordName: nil,
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed"
    )

    #expect(feed.id == "https://example.com/feed.xml")
  }

  @Test("Success rate with zero attempts returns 0.0")
  func successRateZeroAttempts() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      totalAttempts: 0,
      successfulAttempts: 0
    )

    #expect(feed.successRate == 0.0)
  }

  @Test("Success rate with all successful attempts returns 1.0")
  func successRateAllSuccessful() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      totalAttempts: 50,
      successfulAttempts: 50
    )

    #expect(feed.successRate == 1.0)
  }

  @Test("Success rate with partial success returns correct ratio")
  func successRatePartialSuccess() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      totalAttempts: 100,
      successfulAttempts: 75
    )

    #expect(feed.successRate == 0.75)
  }

  @Test("isHealthy returns true when qualityScore >= 70")
  func isHealthyHighQuality() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Healthy Feed",
      qualityScore: 85,
      totalAttempts: 100,
      successfulAttempts: 90,
      failureCount: 2
    )

    #expect(feed.isHealthy == true)
  }

  @Test("isHealthy returns false when successRate is low")
  func isHealthyLowSuccessRate() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Unhealthy Feed",
      qualityScore: 85,
      totalAttempts: 100,
      successfulAttempts: 50,  // 50% success rate (< 0.8)
      failureCount: 2
    )

    #expect(feed.isHealthy == false)
  }

  @Test("isHealthy returns false when failureCount is high")
  func isHealthyHighFailures() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Failing Feed",
      qualityScore: 85,
      totalAttempts: 100,
      successfulAttempts: 90,
      failureCount: 5  // >= 3
    )

    #expect(feed.isHealthy == false)
  }

  // MARK: - Codable Tests

  @Test("Encode and decode round-trip preserves all data")
  func codableRoundTrip() async throws {
    let now = Date()
    let original = Feed(
      recordName: "record123",
      recordChangeTag: "tag456",
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      description: "A test feed",
      category: "tech",
      imageURL: "https://example.com/image.png",
      siteURL: "https://example.com",
      language: "en",
      isFeatured: true,
      isVerified: true,
      qualityScore: 90,
      subscriberCount: 500,
      addedAt: now,
      lastVerified: now,
      updateFrequency: 3_600,
      tags: ["swift", "ios"],
      totalAttempts: 50,
      successfulAttempts: 45,
      lastAttempted: now,
      isActive: true,
      etag: "etag123",
      lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
      failureCount: 2,
      lastFailureReason: "Timeout",
      minUpdateInterval: 1_800
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Feed.self, from: data)

    #expect(decoded.recordName == original.recordName)
    #expect(decoded.feedURL == original.feedURL)
    #expect(decoded.title == original.title)
    #expect(decoded.qualityScore == original.qualityScore)
    #expect(decoded.tags == original.tags)
  }

  @Test("Decode with missing optional fields succeeds")
  func decodeMissingOptionals() async throws {
    let json = """
      {
        "feedURL": "https://example.com/feed.xml",
        "title": "Minimal Feed",
        "isFeatured": false,
        "isVerified": false,
        "qualityScore": 50,
        "subscriberCount": 0,
        "addedAt": \(Date().timeIntervalSinceReferenceDate),
        "tags": [],
        "totalAttempts": 0,
        "successfulAttempts": 0,
        "isActive": true,
        "failureCount": 0
      }
      """

    let data = Data(json.utf8)
    let decoder = JSONDecoder()
    let feed = try decoder.decode(Feed.self, from: data)

    #expect(feed.feedURL == "https://example.com/feed.xml")
    #expect(feed.title == "Minimal Feed")
    #expect(feed.recordName == nil)
    #expect(feed.description == nil)
  }

  @Test("Encode includes all required fields")
  func encodeIncludesRequiredFields() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed"
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(feed)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(json?["feedURL"] as? String == "https://example.com/feed.xml")
    #expect(json?["title"] as? String == "Test Feed")
    #expect(json?["qualityScore"] as? Int == 50)
    #expect(json?["isActive"] as? Bool == true)
  }

  @Test("Date fields encode and decode correctly")
  func dateFieldsEncodeDecodeCorrectly() async throws {
    let now = Date()
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      addedAt: now,
      lastVerified: now,
      lastAttempted: now
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970

    let data = try encoder.encode(feed)
    let decoded = try decoder.decode(Feed.self, from: data)

    let tolerance: TimeInterval = 0.001
    #expect(abs(decoded.addedAt.timeIntervalSince1970 - now.timeIntervalSince1970) < tolerance)
  }

  // MARK: - Hashable/Equatable Tests

  @Test("Equal feeds have same hash")
  func equalFeedsSameHash() async throws {
    let now = Date()
    let feed1 = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      addedAt: now
    )

    let feed2 = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      addedAt: now
    )

    #expect(feed1.hashValue == feed2.hashValue)
  }

  @Test("Different feeds have different hash values")
  func differentFeedsDifferentHash() async throws {
    let feed1 = Feed(
      feedURL: "https://example.com/feed1.xml",
      title: "Feed 1"
    )

    let feed2 = Feed(
      feedURL: "https://example.com/feed2.xml",
      title: "Feed 2"
    )

    #expect(feed1.hashValue != feed2.hashValue)
  }

  @Test("Feeds with same feedURL but different data are not equal")
  func sameFeedURLDifferentData() async throws {
    let feed1 = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Feed 1"
    )

    let feed2 = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Feed 2"
    )

    #expect(feed1 != feed2)
  }

  // MARK: - Edge Cases

  @Test("Very large attempt counts")
  func veryLargeAttemptCounts() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "High Volume Feed",
      totalAttempts: Int64.max,
      successfulAttempts: Int64.max - 100
    )

    #expect(feed.totalAttempts == Int64.max)
    #expect(feed.successfulAttempts == Int64.max - 100)
    #expect(feed.successRate > 0.99)
  }

  @Test("Success rate calculation precision")
  func successRatePrecision() async throws {
    let feed = Feed(
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      totalAttempts: 3,
      successfulAttempts: 1
    )

    let expectedRate = 1.0 / 3.0
    #expect(abs(feed.successRate - expectedRate) < 0.0001)
  }
}
