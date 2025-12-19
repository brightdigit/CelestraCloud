import CelestraKit
import Foundation
import MistKit
import Testing

@testable import CelestraCloudKit

@Suite("Feed+MistKit Tests")
struct FeedMistKitTests {
  @Test("toFieldsDict converts required fields correctly")
  func testToFieldsDictRequiredFields() {
    let feed = Feed(
      recordName: "test-feed",
      recordChangeTag: nil,
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      description: nil,
      category: nil,
      imageURL: nil,
      siteURL: nil,
      language: nil,
      isFeatured: false,
      isVerified: true,
      qualityScore: 75,
      subscriberCount: 100,
      addedAt: Date(timeIntervalSince1970: 1_000_000),
      lastVerified: nil,
      updateFrequency: nil,
      tags: [],
      totalAttempts: 5,
      successfulAttempts: 4,
      lastAttempted: nil,
      isActive: true,
      etag: nil,
      lastModified: nil,
      failureCount: 1,
      lastFailureReason: nil,
      minUpdateInterval: nil
    )

    let fields = feed.toFieldsDict()

    // Check required string fields
    #expect(fields["feedURL"] == .string("https://example.com/feed.xml"))
    #expect(fields["title"] == .string("Test Feed"))

    // Check boolean fields stored as Int64
    #expect(fields["isFeatured"] == .int64(0))
    #expect(fields["isVerified"] == .int64(1))
    #expect(fields["isActive"] == .int64(1))

    // Check numeric fields
    #expect(fields["qualityScore"] == .int64(75))
    #expect(fields["subscriberCount"] == .int64(100))
    #expect(fields["totalAttempts"] == .int64(5))
    #expect(fields["successfulAttempts"] == .int64(4))
    #expect(fields["failureCount"] == .int64(1))

    // Note: addedAt uses CloudKit's built-in createdTimestamp system field, not in dictionary
  }

  @Test("toFieldsDict handles optional fields correctly")
  func testToFieldsDictOptionalFields() {
    let feed = Feed(
      recordName: "test-feed",
      recordChangeTag: nil,
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      description: "A test description",
      category: "Technology",
      imageURL: "https://example.com/image.png",
      siteURL: "https://example.com",
      language: "en",
      isFeatured: true,
      isVerified: false,
      qualityScore: 50,
      subscriberCount: 0,
      addedAt: Date(),
      lastVerified: Date(timeIntervalSince1970: 2_000_000),
      updateFrequency: 3_600.0,
      tags: ["tech", "news"],
      totalAttempts: 0,
      successfulAttempts: 0,
      lastAttempted: Date(timeIntervalSince1970: 3_000_000),
      isActive: true,
      etag: "abc123",
      lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
      failureCount: 0,
      lastFailureReason: "Network error",
      minUpdateInterval: 1_800.0
    )

    let fields = feed.toFieldsDict()

    // Check optional string fields are present
    #expect(fields["description"] == .string("A test description"))
    #expect(fields["category"] == .string("Technology"))
    #expect(fields["imageURL"] == .string("https://example.com/image.png"))
    #expect(fields["siteURL"] == .string("https://example.com"))
    #expect(fields["language"] == .string("en"))
    #expect(fields["etag"] == .string("abc123"))
    #expect(fields["lastModified"] == .string("Mon, 01 Jan 2024 00:00:00 GMT"))
    #expect(fields["lastFailureReason"] == .string("Network error"))

    // Check optional date fields
    #expect(fields["verifiedTimestamp"] == .date(Date(timeIntervalSince1970: 2_000_000)))
    #expect(fields["attemptedTimestamp"] == .date(Date(timeIntervalSince1970: 3_000_000)))

    // Check optional numeric fields
    #expect(fields["updateFrequency"] == .double(3_600.0))
    #expect(fields["minUpdateInterval"] == .double(1_800.0))

    // Check array field
    if case .list(let tagValues) = fields["tags"] {
      #expect(tagValues.count == 2)
      #expect(tagValues[0] == .string("tech"))
      #expect(tagValues[1] == .string("news"))
    } else {
      Issue.record("tags field should be a list")
    }
  }

  @Test("toFieldsDict omits nil optional fields")
  func testToFieldsDictOmitsNilFields() {
    let feed = Feed(
      recordName: "test-feed",
      recordChangeTag: nil,
      feedURL: "https://example.com/feed.xml",
      title: "Test Feed",
      description: nil,
      category: nil,
      imageURL: nil,
      siteURL: nil,
      language: nil,
      isFeatured: false,
      isVerified: false,
      qualityScore: 50,
      subscriberCount: 0,
      addedAt: Date(),
      lastVerified: nil,
      updateFrequency: nil,
      tags: [],
      totalAttempts: 0,
      successfulAttempts: 0,
      lastAttempted: nil,
      isActive: true,
      etag: nil,
      lastModified: nil,
      failureCount: 0,
      lastFailureReason: nil,
      minUpdateInterval: nil
    )

    let fields = feed.toFieldsDict()

    // Verify optional fields are not present when nil
    #expect(fields["description"] == nil)
    #expect(fields["category"] == nil)
    #expect(fields["imageURL"] == nil)
    #expect(fields["siteURL"] == nil)
    #expect(fields["language"] == nil)
    #expect(fields["verifiedTimestamp"] == nil)
    #expect(fields["updateFrequency"] == nil)
    #expect(fields["attemptedTimestamp"] == nil)
    #expect(fields["etag"] == nil)
    #expect(fields["lastModified"] == nil)
    #expect(fields["lastFailureReason"] == nil)
    #expect(fields["minUpdateInterval"] == nil)
    #expect(fields["tags"] == nil)
  }

  @Test("init(from:) parses all fields correctly")
  func testInitFromRecordAllFields() throws {
    let fields: [String: FieldValue] = [
      "feedURL": .string("https://example.com/feed.xml"),
      "title": .string("Test Feed"),
      "description": .string("A description"),
      "category": .string("Tech"),
      "imageURL": .string("https://example.com/image.png"),
      "siteURL": .string("https://example.com"),
      "language": .string("en"),
      "isFeatured": .int64(1),
      "isVerified": .int64(0),
      "isActive": .int64(1),
      "qualityScore": .int64(80),
      "subscriberCount": .int64(200),
      "createdTimestamp": .date(Date(timeIntervalSince1970: 1_000_000)),
      "verifiedTimestamp": .date(Date(timeIntervalSince1970: 2_000_000)),
      "updateFrequency": .double(3_600.0),
      "tags": .list([.string("tech"), .string("news")]),
      "totalAttempts": .int64(10),
      "successfulAttempts": .int64(8),
      "attemptedTimestamp": .date(Date(timeIntervalSince1970: 3_000_000)),
      "etag": .string("etag123"),
      "lastModified": .string("Mon, 01 Jan 2024 00:00:00 GMT"),
      "failureCount": .int64(2),
      "lastFailureReason": .string("Timeout"),
      "minUpdateInterval": .double(1_800.0),
    ]

    let record = RecordInfo(
      recordName: "test-record",
      recordType: "Feed",
      recordChangeTag: "change-tag",
      fields: fields
    )

    let feed = try Feed(from: record)

    #expect(feed.recordName == "test-record")
    #expect(feed.feedURL == "https://example.com/feed.xml")
    #expect(feed.title == "Test Feed")
    #expect(feed.description == "A description")
    #expect(feed.category == "Tech")
    #expect(feed.imageURL == "https://example.com/image.png")
    #expect(feed.siteURL == "https://example.com")
    #expect(feed.language == "en")
    #expect(feed.isFeatured == true)
    #expect(feed.isVerified == false)
    #expect(feed.isActive == true)
    #expect(feed.qualityScore == 80)
    #expect(feed.subscriberCount == 200)
    #expect(feed.addedAt == Date(timeIntervalSince1970: 1_000_000))
    #expect(feed.lastVerified == Date(timeIntervalSince1970: 2_000_000))
    #expect(feed.updateFrequency == 3_600.0)
    #expect(feed.tags == ["tech", "news"])
    #expect(feed.totalAttempts == 10)
    #expect(feed.successfulAttempts == 8)
    #expect(feed.lastAttempted == Date(timeIntervalSince1970: 3_000_000))
    #expect(feed.etag == "etag123")
    #expect(feed.lastModified == "Mon, 01 Jan 2024 00:00:00 GMT")
    #expect(feed.failureCount == 2)
    #expect(feed.lastFailureReason == "Timeout")
    #expect(feed.minUpdateInterval == 1_800.0)
  }

  @Test("init(from:) handles missing optional fields with defaults")
  func testInitFromRecordMissingFields() throws {
    let fields: [String: FieldValue] = [
      "feedURL": .string("https://example.com/feed.xml"),
      "title": .string("Minimal Feed"),
    ]

    let record = RecordInfo(
      recordName: "minimal-record",
      recordType: "Feed",
      recordChangeTag: nil,
      fields: fields
    )

    let feed = try Feed(from: record)

    // Required fields should be set
    #expect(feed.feedURL == "https://example.com/feed.xml")
    #expect(feed.title == "Minimal Feed")

    // Optional fields should be nil or have defaults
    #expect(feed.description == nil)
    #expect(feed.category == nil)
    #expect(feed.imageURL == nil)
    #expect(feed.siteURL == nil)
    #expect(feed.language == nil)
    #expect(feed.isFeatured == false)
    #expect(feed.isVerified == false)
    #expect(feed.isActive == true)  // Default is true
    #expect(feed.qualityScore == 50)  // Default
    #expect(feed.subscriberCount == 0)
    #expect(feed.totalAttempts == 0)
    #expect(feed.successfulAttempts == 0)
    #expect(feed.failureCount == 0)
    #expect(feed.lastVerified == nil)
    #expect(feed.updateFrequency == nil)
    #expect(feed.tags == [])
    #expect(feed.lastAttempted == nil)
    #expect(feed.etag == nil)
    #expect(feed.lastModified == nil)
    #expect(feed.lastFailureReason == nil)
    #expect(feed.minUpdateInterval == nil)
  }

  @Test("Round-trip conversion preserves data")
  func testRoundTripConversion() throws {
    let originalFeed = Feed(
      recordName: "round-trip",
      recordChangeTag: "tag1",
      feedURL: "https://example.com/feed.xml",
      title: "Round Trip Feed",
      description: "Testing round-trip",
      category: "Test",
      imageURL: "https://example.com/img.png",
      siteURL: "https://example.com",
      language: "en",
      isFeatured: true,
      isVerified: true,
      qualityScore: 90,
      subscriberCount: 500,
      addedAt: Date(timeIntervalSince1970: 1_000_000),
      lastVerified: Date(timeIntervalSince1970: 2_000_000),
      updateFrequency: 7_200.0,
      tags: ["test", "roundtrip"],
      totalAttempts: 15,
      successfulAttempts: 14,
      lastAttempted: Date(timeIntervalSince1970: 3_000_000),
      isActive: true,
      etag: "round123",
      lastModified: "Thu, 01 Feb 2024 00:00:00 GMT",
      failureCount: 1,
      lastFailureReason: "Brief timeout",
      minUpdateInterval: 3_600.0
    )

    // Convert to fields
    let fields = originalFeed.toFieldsDict()

    // Create a record
    let record = RecordInfo(
      recordName: originalFeed.recordName ?? "round-trip",
      recordType: "Feed",
      recordChangeTag: originalFeed.recordChangeTag,
      fields: fields
    )

    // Convert back to Feed
    let reconstructedFeed = try Feed(from: record)

    // Verify all fields match
    #expect(reconstructedFeed.feedURL == originalFeed.feedURL)
    #expect(reconstructedFeed.title == originalFeed.title)
    #expect(reconstructedFeed.description == originalFeed.description)
    #expect(reconstructedFeed.category == originalFeed.category)
    #expect(reconstructedFeed.imageURL == originalFeed.imageURL)
    #expect(reconstructedFeed.siteURL == originalFeed.siteURL)
    #expect(reconstructedFeed.language == originalFeed.language)
    #expect(reconstructedFeed.isFeatured == originalFeed.isFeatured)
    #expect(reconstructedFeed.isVerified == originalFeed.isVerified)
    #expect(reconstructedFeed.isActive == originalFeed.isActive)
    #expect(reconstructedFeed.qualityScore == originalFeed.qualityScore)
    #expect(reconstructedFeed.subscriberCount == originalFeed.subscriberCount)
    #expect(reconstructedFeed.tags == originalFeed.tags)
    #expect(reconstructedFeed.totalAttempts == originalFeed.totalAttempts)
    #expect(reconstructedFeed.successfulAttempts == originalFeed.successfulAttempts)
    #expect(reconstructedFeed.failureCount == originalFeed.failureCount)
    #expect(reconstructedFeed.etag == originalFeed.etag)
    #expect(reconstructedFeed.lastModified == originalFeed.lastModified)
    #expect(reconstructedFeed.lastFailureReason == originalFeed.lastFailureReason)
    #expect(reconstructedFeed.updateFrequency == originalFeed.updateFrequency)
    #expect(reconstructedFeed.minUpdateInterval == originalFeed.minUpdateInterval)
  }

  @Test("Boolean fields correctly convert between Bool and Int64")
  func testBooleanFieldConversion() throws {
    let feed = Feed(
      recordName: "bool-test",
      recordChangeTag: nil,
      feedURL: "https://example.com/feed.xml",
      title: "Boolean Test",
      description: nil,
      category: nil,
      imageURL: nil,
      siteURL: nil,
      language: nil,
      isFeatured: true,  // Should be 1
      isVerified: false,  // Should be 0
      qualityScore: 50,
      subscriberCount: 0,
      addedAt: Date(),
      lastVerified: nil,
      updateFrequency: nil,
      tags: [],
      totalAttempts: 0,
      successfulAttempts: 0,
      lastAttempted: nil,
      isActive: false,  // Should be 0
      etag: nil,
      lastModified: nil,
      failureCount: 0,
      lastFailureReason: nil,
      minUpdateInterval: nil
    )

    let fields = feed.toFieldsDict()

    // Verify booleans are stored as Int64
    #expect(fields["isFeatured"] == .int64(1))
    #expect(fields["isVerified"] == .int64(0))
    #expect(fields["isActive"] == .int64(0))

    // Round-trip back
    let record = RecordInfo(
      recordName: "bool-test",
      recordType: "Feed",
      recordChangeTag: nil,
      fields: fields
    )

    let reconstructed = try Feed(from: record)

    #expect(reconstructed.isFeatured == true)
    #expect(reconstructed.isVerified == false)
    #expect(reconstructed.isActive == false)
  }
}
