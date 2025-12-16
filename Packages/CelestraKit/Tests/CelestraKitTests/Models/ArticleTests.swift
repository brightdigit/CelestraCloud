import Foundation
import Testing

@testable import CelestraKit

/// Comprehensive tests for Article model
@Suite("Article Model Tests")
struct ArticleTests {
  // MARK: - Initialization Tests

  @Test("Initialize with default TTL (30 days)")
  func initializeDefaultTTL() async throws {
    let now = Date()
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1"
    )

    let expectedExpiration = now.addingTimeInterval(TimeInterval(30 * 24 * 60 * 60))
    let tolerance: TimeInterval = 60  // 1 minute tolerance

    #expect(abs(article.expiresAt.timeIntervalSince(expectedExpiration)) < tolerance)
  }

  @Test("Initialize with custom TTL")
  func initializeCustomTTL() async throws {
    let now = Date()
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1",
      fetchedAt: now,
      ttlDays: 7
    )

    let expectedExpiration = now.addingTimeInterval(TimeInterval(7 * 24 * 60 * 60))
    let tolerance: TimeInterval = 60

    #expect(abs(article.expiresAt.timeIntervalSince(expectedExpiration)) < tolerance)
  }

  @Test("Initialize with automatic contentText extraction")
  func initializeContentTextExtraction() async throws {
    let htmlContent = "<p>This is <strong>HTML</strong> content</p>"
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      content: htmlContent,
      url: "https://example.com/article1"
    )

    #expect(article.contentText != nil)
    #expect(article.contentText?.contains("<") == false)
    #expect(article.contentText?.contains("HTML") == true)
  }

  @Test("Initialize with automatic wordCount calculation")
  func initializeWordCount() async throws {
    let content = "This is a test article with nine words here"
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      contentText: content,
      url: "https://example.com/article1"
    )

    #expect(article.wordCount == 9)
  }

  @Test("Initialize with automatic estimatedReadingTime")
  func initializeReadingTime() async throws {
    // 400 words at 200 wpm = 2 minutes
    let words = Array(repeating: "word", count: 400).joined(separator: " ")
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      contentText: words,
      url: "https://example.com/article1"
    )

    #expect(article.wordCount == 400)
    #expect(article.estimatedReadingTime == 2)
  }

  @Test("Initialize with nil optional fields")
  func initializeWithNils() async throws {
    let article = Article(
      recordName: nil,
      recordChangeTag: nil,
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      excerpt: nil,
      content: nil,
      contentText: nil,
      author: nil,
      url: "https://example.com/article1",
      imageURL: nil,
      publishedDate: nil,
      wordCount: nil,
      estimatedReadingTime: nil,
      language: nil,
      tags: []
    )

    #expect(article.recordName == nil)
    #expect(article.excerpt == nil)
    #expect(article.content == nil)
    #expect(article.author == nil)
    #expect(article.imageURL == nil)
  }

  // MARK: - Static Helper Method Tests

  @Test("calculateContentHash produces consistent hash for same inputs")
  func contentHashConsistency() async throws {
    let hash1 = Article.calculateContentHash(
      title: "Test Article",
      url: "https://example.com/article1",
      guid: "guid123"
    )

    let hash2 = Article.calculateContentHash(
      title: "Test Article",
      url: "https://example.com/article1",
      guid: "guid123"
    )

    #expect(hash1 == hash2)
  }

  @Test("calculateContentHash produces different hash for different inputs")
  func contentHashDifferentInputs() async throws {
    let hash1 = Article.calculateContentHash(
      title: "Test Article 1",
      url: "https://example.com/article1",
      guid: "guid123"
    )

    let hash2 = Article.calculateContentHash(
      title: "Test Article 2",
      url: "https://example.com/article2",
      guid: "guid456"
    )

    #expect(hash1 != hash2)
  }

  @Test("calculateContentHash handles empty strings")
  func contentHashEmptyStrings() async throws {
    let hash = Article.calculateContentHash(
      title: "",
      url: "",
      guid: ""
    )

    #expect(!hash.isEmpty)
    #expect(hash == "||")  // Composite key with empty components
  }

  @Test("extractPlainText removes HTML tags")
  func extractPlainTextRemoveTags() async throws {
    let html = "<div><p>This is <strong>bold</strong> and <em>italic</em> text</p></div>"
    let plainText = Article.extractPlainText(from: html)

    #expect(plainText?.contains("<") == false)
    #expect(plainText?.contains(">") == false)
    #expect(plainText?.contains("bold") == true)
    #expect(plainText?.contains("italic") == true)
  }

  @Test("extractPlainText decodes HTML entities")
  func extractPlainTextDecodeEntities() async throws {
    let html = "Test&nbsp;&amp;&lt;&gt;&quot;"
    let plainText = Article.extractPlainText(from: html)

    #expect(plainText?.contains("&") == true)
    #expect(plainText?.contains("<") == true)
    #expect(plainText?.contains(">") == true)
    #expect(plainText?.contains("\"") == true)
    #expect(plainText?.contains("&nbsp;") == false)
    #expect(plainText?.contains("&amp;") == false)
  }

  @Test("extractPlainText handles nested HTML")
  func extractPlainTextNestedHTML() async throws {
    let html = "<div><article><h1>Title</h1><p>Paragraph</p></article></div>"
    let plainText = Article.extractPlainText(from: html)

    #expect(plainText?.contains("<") == false)
    #expect(plainText?.contains("Title") == true)
    #expect(plainText?.contains("Paragraph") == true)
  }

  @Test("extractPlainText returns nil for nil input")
  func extractPlainTextNilInput() async throws {
    let plainText = Article.extractPlainText(from: nil)
    #expect(plainText == nil)
  }

  @Test("calculateWordCount accurate for normal text")
  func calculateWordCountNormalText() async throws {
    let text = "This is a simple test with seven words"
    let count = Article.calculateWordCount(from: text)

    #expect(count == 8)  // 8 words
  }

  @Test("calculateWordCount handles multiple spaces")
  func calculateWordCountMultipleSpaces() async throws {
    let text = "Words   with    multiple     spaces"
    let count = Article.calculateWordCount(from: text)

    #expect(count == 4)
  }

  @Test("calculateWordCount returns nil for nil input")
  func calculateWordCountNilInput() async throws {
    let count = Article.calculateWordCount(from: nil)
    #expect(count == nil)
  }

  @Test("estimateReadingTime assumes 200 words per minute")
  func estimateReadingTime200WPM() async throws {
    let time = Article.estimateReadingTime(wordCount: 200)
    #expect(time == 1)

    let time2 = Article.estimateReadingTime(wordCount: 400)
    #expect(time2 == 2)

    let time3 = Article.estimateReadingTime(wordCount: 1_000)
    #expect(time3 == 5)
  }

  @Test("estimateReadingTime returns minimum 1 minute")
  func estimateReadingTimeMinimum() async throws {
    let time = Article.estimateReadingTime(wordCount: 50)
    #expect(time == 1)  // Less than 200 words still returns 1 minute
  }

  @Test("estimateReadingTime returns nil for nil or zero input")
  func estimateReadingTimeNilZero() async throws {
    #expect(Article.estimateReadingTime(wordCount: nil) == nil)
    #expect(Article.estimateReadingTime(wordCount: 0) == nil)
  }

  // MARK: - Computed Properties Tests

  @Test("ID composition from recordName and guid when recordName exists")
  func idWithRecordName() async throws {
    let article = Article(
      recordName: "record123",
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1"
    )

    #expect(article.id == "record123")
  }

  @Test("ID composition from feedRecordName and guid when recordName is nil")
  func idWithoutRecordName() async throws {
    let article = Article(
      recordName: nil,
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1"
    )

    #expect(article.id == "feed123:article-guid-1")
  }

  @Test("isExpired returns true for past expiresAt")
  func isExpiredPastDate() async throws {
    let pastDate = Date().addingTimeInterval(-3_600)  // 1 hour ago
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1",
      fetchedAt: pastDate,
      ttlDays: 0
    )

    #expect(article.isExpired == true)
  }

  @Test("isExpired returns false for future expiresAt")
  func isExpiredFutureDate() async throws {
    let now = Date()
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1",
      fetchedAt: now,
      ttlDays: 30
    )

    #expect(article.isExpired == false)
  }

  @Test("isExpired boundary test")
  func isExpiredBoundary() async throws {
    let now = Date()
    // Set expiration to exactly now (technically expired)
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1",
      fetchedAt: now.addingTimeInterval(-TimeInterval(30 * 24 * 60 * 60)),
      ttlDays: 30
    )

    // Should be expired or very close to expiration
    let tolerance: TimeInterval = 60
    let timeUntilExpiration = article.expiresAt.timeIntervalSince(Date())
    #expect(abs(timeUntilExpiration) < tolerance)
  }

  // MARK: - Deduplication Tests

  @Test("isDuplicate returns true for same contentHash")
  func isDuplicateSameHash() async throws {
    let article1 = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Same Article",
      url: "https://example.com/article1"
    )

    let article2 = Article(
      feedRecordName: "feed456",
      guid: "article-guid-1",
      title: "Same Article",
      url: "https://example.com/article1"
    )

    #expect(article1.isDuplicate(of: article2) == true)
  }

  @Test("isDuplicate returns false for different contentHash")
  func isDuplicateDifferentHash() async throws {
    let article1 = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Article 1",
      url: "https://example.com/article1"
    )

    let article2 = Article(
      feedRecordName: "feed123",
      guid: "article-guid-2",
      title: "Article 2",
      url: "https://example.com/article2"
    )

    #expect(article1.isDuplicate(of: article2) == false)
  }

  @Test("isDuplicate with same title but different URLs")
  func isDuplicateSameTitleDifferentURL() async throws {
    let article1 = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Same Title",
      url: "https://example.com/article1"
    )

    let article2 = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Same Title",
      url: "https://example.com/article2"
    )

    #expect(article1.isDuplicate(of: article2) == false)
  }

  // MARK: - Codable Tests

  @Test("Round-trip encoding and decoding preserves all data")
  func codableRoundTrip() async throws {
    let now = Date()
    let original = Article(
      recordName: "record123",
      recordChangeTag: "tag456",
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      excerpt: "This is an excerpt",
      content: "<p>This is content</p>",
      contentText: "This is content",
      author: "John Doe",
      url: "https://example.com/article1",
      imageURL: "https://example.com/image.png",
      publishedDate: now,
      fetchedAt: now,
      ttlDays: 30,
      wordCount: 10,
      estimatedReadingTime: 1,
      language: "en",
      tags: ["swift", "ios"]
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Article.self, from: data)

    #expect(decoded.recordName == original.recordName)
    #expect(decoded.feedRecordName == original.feedRecordName)
    #expect(decoded.guid == original.guid)
    #expect(decoded.title == original.title)
    #expect(decoded.author == original.author)
    #expect(decoded.tags == original.tags)
  }

  @Test("Date and TimeInterval fields encode correctly")
  func dateFieldsEncode() async throws {
    let now = Date()
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1",
      publishedDate: now,
      fetchedAt: now
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    let data = try encoder.encode(article)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    let decoded = try decoder.decode(Article.self, from: data)

    let tolerance: TimeInterval = 0.001
    #expect(abs(decoded.fetchedAt.timeIntervalSince1970 - now.timeIntervalSince1970) < tolerance)
  }

  @Test("Optional fields handled correctly in encoding")
  func optionalFieldsEncoding() async throws {
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      excerpt: nil,
      content: nil,
      author: nil,
      url: "https://example.com/article1",
      imageURL: nil
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(article)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Article.self, from: data)

    #expect(decoded.excerpt == nil)
    #expect(decoded.content == nil)
    #expect(decoded.author == nil)
    #expect(decoded.imageURL == nil)
  }

  @Test("contentHash preserved through encoding")
  func contentHashPreserved() async throws {
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      url: "https://example.com/article1"
    )

    let originalHash = article.contentHash

    let encoder = JSONEncoder()
    let data = try encoder.encode(article)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Article.self, from: data)

    #expect(decoded.contentHash == originalHash)
  }

  // MARK: - Edge Cases

  @Test("Very long content handling")
  func veryLongContent() async throws {
    let longContent = String(repeating: "word ", count: 10_000)
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Long Article",
      contentText: longContent,
      url: "https://example.com/article1"
    )

    #expect(article.wordCount == 10_000)
    #expect(article.estimatedReadingTime == 50)  // 10000 / 200 = 50 minutes
  }

  @Test("Special characters in content hash")
  func specialCharactersInHash() async throws {
    let hash = Article.calculateContentHash(
      title: "Title with émojis 🚀 and ñ",
      url: "https://example.com/article?param=value&other=test",
      guid: "guid-with-special-chars-123!@#"
    )

    #expect(!hash.isEmpty)
    #expect(hash.contains("|"))  // Contains separator
    #expect(hash.contains("🚀"))  // Preserves emojis
  }

  @Test("Empty content text extraction")
  func emptyContentExtraction() async throws {
    let article = Article(
      feedRecordName: "feed123",
      guid: "article-guid-1",
      title: "Test Article",
      content: "",
      url: "https://example.com/article1"
    )

    #expect(article.contentText?.isEmpty == true || article.contentText == nil)
  }
}
