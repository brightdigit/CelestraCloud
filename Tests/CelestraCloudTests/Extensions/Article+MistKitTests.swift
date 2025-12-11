import Testing
import Foundation
import MistKit
@testable import Celestra
import CelestraKit

@Suite("Article+MistKit Tests")
struct ArticleMistKitTests {

    @Test("toFieldsDict converts required fields correctly")
    func testToFieldsDictRequiredFields() {
        let article = Article(
            feedRecordName: "feed-123",
            guid: "article-guid-456",
            title: "Test Article",
            url: "https://example.com/article",
            fetchedAt: Date(timeIntervalSince1970: 1000000),
            ttlDays: 30
        )

        let fields = article.toFieldsDict()

        // Check required fields
        #expect(fields["feedRecordName"] == .string("feed-123"))
        #expect(fields["guid"] == .string("article-guid-456"))
        #expect(fields["title"] == .string("Test Article"))
        #expect(fields["url"] == .string("https://example.com/article"))
        #expect(fields["fetchedAt"] == .date(Date(timeIntervalSince1970: 1000000)))
        // expiresAt and contentHash are computed properties, check they exist
        #expect(fields["expiresAt"] != nil)
        #expect(fields["contentHash"] != nil)
    }

    @Test("toFieldsDict handles optional fields correctly")
    func testToFieldsDictOptionalFields() {
        let article = Article(
            feedRecordName: "feed-123",
            guid: "article-guid-456",
            title: "Full Article",
            excerpt: "This is an excerpt",
            content: "<p>Full HTML content</p>",
            contentText: "Full text content",
            author: "John Doe",
            url: "https://example.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedDate: Date(timeIntervalSince1970: 500000),
            fetchedAt: Date(timeIntervalSince1970: 1000000),
            ttlDays: 60,
            wordCount: 500,
            estimatedReadingTime: 3,
            language: "en",
            tags: ["tech", "swift"]
        )

        let fields = article.toFieldsDict()

        // Check optional string fields
        #expect(fields["excerpt"] == .string("This is an excerpt"))
        #expect(fields["content"] == .string("<p>Full HTML content</p>"))
        #expect(fields["contentText"] == .string("Full text content"))
        #expect(fields["author"] == .string("John Doe"))
        #expect(fields["imageURL"] == .string("https://example.com/image.jpg"))
        #expect(fields["language"] == .string("en"))

        // Check optional date field
        #expect(fields["publishedDate"] == .date(Date(timeIntervalSince1970: 500000)))

        // Check optional numeric fields
        #expect(fields["wordCount"] == .int64(500))
        #expect(fields["estimatedReadingTime"] == .int64(3))

        // Check array field
        if case .list(let tagValues) = fields["tags"] {
            #expect(tagValues.count == 2)
            #expect(tagValues[0] == .string("tech"))
            #expect(tagValues[1] == .string("swift"))
        } else {
            Issue.record("tags field should be a list")
        }
    }

    @Test("toFieldsDict omits nil optional fields")
    func testToFieldsDictOmitsNilFields() {
        let article = Article(
            feedRecordName: "feed-123",
            guid: "guid-789",
            title: "Minimal Article",
            url: "https://example.com/minimal",
            fetchedAt: Date(),
            ttlDays: 30
        )

        let fields = article.toFieldsDict()

        // Verify optional fields are not present when nil
        #expect(fields["publishedDate"] == nil)
        #expect(fields["excerpt"] == nil)
        #expect(fields["content"] == nil)
        #expect(fields["contentText"] == nil)
        #expect(fields["author"] == nil)
        #expect(fields["imageURL"] == nil)
        #expect(fields["language"] == nil)
        #expect(fields["wordCount"] == nil)
        #expect(fields["estimatedReadingTime"] == nil)
        #expect(fields["tags"] == nil)
    }

    @Test("init(from:) parses all fields correctly")
    func testInitFromRecordAllFields() {
        let fetchedDate = Date(timeIntervalSince1970: 1000000)
        let expiresDate = Date(timeIntervalSince1970: 3000000)
        
        let fields: [String: FieldValue] = [
            "feedRecordName": .string("feed-123"),
            "guid": .string("guid-456"),
            "title": .string("Complete Article"),
            "url": .string("https://example.com/complete"),
            "publishedDate": .date(Date(timeIntervalSince1970: 500000)),
            "excerpt": .string("Excerpt text"),
            "content": .string("<p>HTML content</p>"),
            "contentText": .string("Plain text"),
            "author": .string("Jane Smith"),
            "imageURL": .string("https://example.com/img.jpg"),
            "language": .string("en-US"),
            "tags": .list([.string("news"), .string("tech")]),
            "wordCount": .int64(750),
            "estimatedReadingTime": .int64(4),
            "fetchedAt": .date(fetchedDate),
            "expiresAt": .date(expiresDate),
            "contentHash": .string("complete-hash")
        ]

        let record = RecordInfo(
            recordName: "complete-article-record",
            recordType: "Article",
            recordChangeTag: "tag-123",
            fields: fields
        )

        let article = Article(from: record)

        #expect(article.recordName == "complete-article-record")
        #expect(article.feedRecordName == "feed-123")
        #expect(article.guid == "guid-456")
        #expect(article.title == "Complete Article")
        #expect(article.url == "https://example.com/complete")
        #expect(article.publishedDate == Date(timeIntervalSince1970: 500000))
        #expect(article.excerpt == "Excerpt text")
        #expect(article.content == "<p>HTML content</p>")
        #expect(article.contentText == "Plain text")
        #expect(article.author == "Jane Smith")
        #expect(article.imageURL == "https://example.com/img.jpg")
        #expect(article.language == "en-US")
        #expect(article.tags == ["news", "tech"])
        #expect(article.wordCount == 750)
        #expect(article.estimatedReadingTime == 4)
        #expect(article.fetchedAt == fetchedDate)
    }

    @Test("init(from:) handles missing optional fields with defaults")
    func testInitFromRecordMissingFields() {
        let fetchedDate = Date(timeIntervalSince1970: 1000000)
        let expiresDate = Date(timeIntervalSince1970: 2000000)
        
        let fields: [String: FieldValue] = [
            "feedRecordName": .string("feed-123"),
            "guid": .string("guid-789"),
            "title": .string("Minimal Article"),
            "url": .string("https://example.com/minimal"),
            "fetchedAt": .date(fetchedDate),
            "expiresAt": .date(expiresDate),
            "contentHash": .string("hash-minimal")
        ]

        let record = RecordInfo(
            recordName: "minimal-article-record",
            recordType: "Article",
            recordChangeTag: nil,
            fields: fields
        )

        let article = Article(from: record)

        // Required fields should be set
        #expect(article.feedRecordName == "feed-123")
        #expect(article.guid == "guid-789")
        #expect(article.title == "Minimal Article")
        #expect(article.url == "https://example.com/minimal")
        #expect(article.fetchedAt == fetchedDate)

        // Optional fields should be nil or empty
        #expect(article.publishedDate == nil)
        #expect(article.excerpt == nil)
        #expect(article.content == nil)
        #expect(article.contentText == nil)
        #expect(article.author == nil)
        #expect(article.imageURL == nil)
        #expect(article.language == nil)
        #expect(article.tags == [])
        #expect(article.wordCount == nil)
        #expect(article.estimatedReadingTime == nil)
    }

    @Test("Round-trip conversion preserves data")
    func testRoundTripConversion() {
        let originalArticle = Article(
            recordName: "roundtrip-article",
            recordChangeTag: "rt-tag",
            feedRecordName: "feed-rt",
            guid: "guid-rt-123",
            title: "Round Trip Article",
            excerpt: "Round trip excerpt",
            content: "<p>Round trip content</p>",
            contentText: "Round trip text",
            author: "Round Trip Author",
            url: "https://example.com/roundtrip",
            imageURL: "https://example.com/rt.jpg",
            publishedDate: Date(timeIntervalSince1970: 700000),
            fetchedAt: Date(timeIntervalSince1970: 1000000),
            ttlDays: 45,
            wordCount: 600,
            estimatedReadingTime: 3,
            language: "en",
            tags: ["roundtrip", "test"]
        )

        // Convert to fields
        let fields = originalArticle.toFieldsDict()

        // Create a record
        let record = RecordInfo(
            recordName: originalArticle.recordName ?? "roundtrip-article",
            recordType: "Article",
            recordChangeTag: originalArticle.recordChangeTag,
            fields: fields
        )

        // Convert back to Article
        let reconstructedArticle = Article(from: record)

        // Verify all fields match
        #expect(reconstructedArticle.feedRecordName == originalArticle.feedRecordName)
        #expect(reconstructedArticle.guid == originalArticle.guid)
        #expect(reconstructedArticle.title == originalArticle.title)
        #expect(reconstructedArticle.url == originalArticle.url)
        #expect(reconstructedArticle.publishedDate == originalArticle.publishedDate)
        #expect(reconstructedArticle.excerpt == originalArticle.excerpt)
        #expect(reconstructedArticle.content == originalArticle.content)
        #expect(reconstructedArticle.contentText == originalArticle.contentText)
        #expect(reconstructedArticle.author == originalArticle.author)
        #expect(reconstructedArticle.imageURL == originalArticle.imageURL)
        #expect(reconstructedArticle.language == originalArticle.language)
        #expect(reconstructedArticle.tags == originalArticle.tags)
        #expect(reconstructedArticle.wordCount == originalArticle.wordCount)
        #expect(reconstructedArticle.estimatedReadingTime == originalArticle.estimatedReadingTime)
        #expect(reconstructedArticle.fetchedAt == originalArticle.fetchedAt)
    }
}
