//
//  Feed.swift
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

/// Represents an RSS feed in CloudKit's public database
/// Shared across all users for efficient content distribution
public struct Feed: Sendable, Codable, Hashable, Identifiable {
  /// CloudKit record name (unique identifier)
  public let recordName: String?

  /// CloudKit record change tag for optimistic locking
  public let recordChangeTag: String?

  /// RSS feed URL (unique per feed)
  public let feedURL: String

  /// Feed title from RSS metadata
  public let title: String

  /// Feed description/subtitle
  public let description: String?

  /// Feed category (technology, design, business, etc.)
  public let category: String?

  /// Feed image URL
  public let imageURL: String?

  /// Feed website URL
  public let siteURL: String?

  /// Language code (ISO 639-1)
  public let language: String?

  /// Whether this feed is featured
  public let isFeatured: Bool

  /// Whether this feed is verified/trusted
  public let isVerified: Bool

  /// Quality score (0-100)
  public let qualityScore: Int

  /// Number of subscribers
  public let subscriberCount: Int64

  /// When feed was added to public database
  public let addedAt: Date

  /// Last time feed was verified/checked
  public let lastVerified: Date?

  /// Average update frequency in seconds
  public let updateFrequency: TimeInterval?

  /// Tags for categorization and search
  public let tags: [String]

  // MARK: - Server-side metrics

  /// Total fetch attempts by server
  public let totalAttempts: Int64

  /// Successful fetch attempts
  public let successfulAttempts: Int64

  /// Last time server attempted to fetch
  public let lastAttempted: Date?

  /// Whether feed is actively being updated
  public let isActive: Bool

  /// HTTP ETag for conditional requests
  public let etag: String?

  /// HTTP Last-Modified header
  public let lastModified: String?

  /// Consecutive failure count
  public let failureCount: Int64

  /// Last failure error message
  public let lastFailureReason: String?

  /// Minimum update interval from RSS <ttl>
  public let minUpdateInterval: TimeInterval?

  // MARK: - Computed

  public var id: String {
    recordName ?? feedURL
  }

  public init(
    recordName: String? = nil,
    recordChangeTag: String? = nil,
    feedURL: String,
    title: String,
    description: String? = nil,
    category: String? = nil,
    imageURL: String? = nil,
    siteURL: String? = nil,
    language: String? = nil,
    isFeatured: Bool = false,
    isVerified: Bool = false,
    qualityScore: Int = 50,
    subscriberCount: Int64 = 0,
    addedAt: Date = Date(),
    lastVerified: Date? = nil,
    updateFrequency: TimeInterval? = nil,
    tags: [String] = [],
    totalAttempts: Int64 = 0,
    successfulAttempts: Int64 = 0,
    lastAttempted: Date? = nil,
    isActive: Bool = true,
    etag: String? = nil,
    lastModified: String? = nil,
    failureCount: Int64 = 0,
    lastFailureReason: String? = nil,
    minUpdateInterval: TimeInterval? = nil
  ) {
    self.recordName = recordName
    self.recordChangeTag = recordChangeTag
    self.feedURL = feedURL
    self.title = title
    self.description = description
    self.category = category
    self.imageURL = imageURL
    self.siteURL = siteURL
    self.language = language
    self.isFeatured = isFeatured
    self.isVerified = isVerified
    self.qualityScore = qualityScore
    self.subscriberCount = subscriberCount
    self.addedAt = addedAt
    self.lastVerified = lastVerified
    self.updateFrequency = updateFrequency
    self.tags = tags
    self.totalAttempts = totalAttempts
    self.successfulAttempts = successfulAttempts
    self.lastAttempted = lastAttempted
    self.isActive = isActive
    self.etag = etag
    self.lastModified = lastModified
    self.failureCount = failureCount
    self.lastFailureReason = lastFailureReason
    self.minUpdateInterval = minUpdateInterval
  }
}

// MARK: - Helpers

extension Feed {
  /// Success rate for feed fetching (0.0 - 1.0)
  public var successRate: Double {
    guard totalAttempts > 0 else { return 0.0 }
    return Double(successfulAttempts) / Double(totalAttempts)
  }

  /// Whether the feed is healthy (low failure rate)
  public var isHealthy: Bool {
    failureCount < 3 && successRate > 0.8
  }
}
