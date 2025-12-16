//
//  Article.swift
//  CelestraKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Represents an RSS article in CloudKit's public database
/// Shared across all users for efficient content distribution
public struct Article: Sendable, Codable, Hashable, Identifiable {
  /// CloudKit record name (unique identifier)
  public let recordName: String?

  /// CloudKit record change tag for optimistic locking
  public let recordChangeTag: String?

  /// Reference to parent PublicFeed record name
  public let feedRecordName: String

  /// Article GUID from RSS feed (unique per feed)
  public let guid: String

  /// Article title
  public let title: String

  /// Article excerpt/summary
  public let excerpt: String?

  /// Full article content (HTML)
  public let content: String?

  /// Plain text content for search indexing
  public let contentText: String?

  /// Article author
  public let author: String?

  /// Article URL
  public let url: String

  /// Article image URL
  public let imageURL: String?

  /// Publication date from RSS
  public let publishedDate: Date?

  /// When article was fetched from RSS
  public let fetchedAt: Date

  /// When article expires from cache (TTL)
  public let expiresAt: Date

  /// SHA-256 content hash for deduplication
  public let contentHash: String

  /// Word count for reading time estimation
  public let wordCount: Int?

  /// Estimated reading time in minutes
  public let estimatedReadingTime: Int?

  /// Language code (ISO 639-1)
  public let language: String?

  /// Tags/categories
  public let tags: [String]

  // MARK: - Computed

  public var id: String {
    recordName ?? "\(feedRecordName):\(guid)"
  }

  /// Whether the article has expired and should be refreshed
  public var isExpired: Bool {
    Date() > expiresAt
  }

  public init(
    recordName: String? = nil,
    recordChangeTag: String? = nil,
    feedRecordName: String,
    guid: String,
    title: String,
    excerpt: String? = nil,
    content: String? = nil,
    contentText: String? = nil,
    author: String? = nil,
    url: String,
    imageURL: String? = nil,
    publishedDate: Date? = nil,
    fetchedAt: Date = Date(),
    ttlDays: Int = 30,
    wordCount: Int? = nil,
    estimatedReadingTime: Int? = nil,
    language: String? = nil,
    tags: [String] = []
  ) {
    self.recordName = recordName
    self.recordChangeTag = recordChangeTag
    self.feedRecordName = feedRecordName
    self.guid = guid
    self.title = title
    self.excerpt = excerpt
    self.content = content
    self.contentText = contentText ?? Self.extractPlainText(from: content)
    self.author = author
    self.url = url
    self.imageURL = imageURL
    self.publishedDate = publishedDate
    self.fetchedAt = fetchedAt
    self.expiresAt = fetchedAt.addingTimeInterval(TimeInterval(ttlDays * 24 * 60 * 60))
    self.contentHash = Self.calculateContentHash(title: title, url: url, guid: guid)
    self.wordCount = wordCount ?? Self.calculateWordCount(from: contentText)
    self.estimatedReadingTime =
      estimatedReadingTime
      ?? Self.estimateReadingTime(
        wordCount: self.wordCount)
    self.language = language
    self.tags = tags
  }

  // MARK: - Helpers

  /// Calculate content hash for deduplication using composite key
  public static func calculateContentHash(title: String, url: String, guid: String) -> String {
    "\(title)|\(url)|\(guid)"
  }

  /// Extract plain text from HTML content
  public static func extractPlainText(from html: String?) -> String? {
    guard let html = html else { return nil }
    // Simple HTML tag removal (use proper HTML parser in production)
    let withoutTags = html.replacingOccurrences(
      of: "<[^>]+>", with: "", options: .regularExpression)
    let decoded =
      withoutTags
      .replacingOccurrences(of: "&nbsp;", with: " ")
      .replacingOccurrences(of: "&amp;", with: "&")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&quot;", with: "\"")
    return decoded.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Calculate word count from text
  public static func calculateWordCount(from text: String?) -> Int? {
    guard let text = text else { return nil }
    let words = text.components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
    return words.count
  }

  /// Estimate reading time in minutes (average 200 words/minute)
  public static func estimateReadingTime(wordCount: Int?) -> Int? {
    guard let count = wordCount, count > 0 else { return nil }
    return max(1, count / 200)  // Minimum 1 minute
  }
}

// MARK: - Deduplication

extension Article {
  /// Check if two articles are likely duplicates based on content hash
  public func isDuplicate(of other: Article) -> Bool {
    contentHash == other.contentHash
  }
}
