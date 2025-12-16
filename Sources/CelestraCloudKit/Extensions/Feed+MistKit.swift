//
//  Feed+MistKit.swift
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

public import CelestraKit
public import Foundation
public import MistKit

extension Feed: CloudKitConvertible {
  /// Convert to CloudKit record fields dictionary using MistKit's FieldValue
  public func toFieldsDict() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "feedURL": .string(feedURL),
      "title": .string(title),
      "isFeatured": .int64(isFeatured ? 1 : 0),
      "isVerified": .int64(isVerified ? 1 : 0),
      "qualityScore": .int64(qualityScore),
      "subscriberCount": .int64(Int(subscriberCount)),
      // Note: addedAt removed - use CloudKit's built-in createdTimestamp
      "totalAttempts": .int64(Int(totalAttempts)),
      "successfulAttempts": .int64(Int(successfulAttempts)),
      "isActive": .int64(isActive ? 1 : 0),
      "failureCount": .int64(Int(failureCount)),
    ]

    // Optional string fields
    if let description = description {
      fields["description"] = .string(description)
    }
    if let category = category {
      fields["category"] = .string(category)
    }
    if let imageURL = imageURL {
      fields["imageURL"] = .string(imageURL)
    }
    if let siteURL = siteURL {
      fields["siteURL"] = .string(siteURL)
    }
    if let language = language {
      fields["language"] = .string(language)
    }
    if let etag = etag {
      fields["etag"] = .string(etag)
    }
    if let lastModified = lastModified {
      fields["lastModified"] = .string(lastModified)
    }
    if let lastFailureReason = lastFailureReason {
      fields["lastFailureReason"] = .string(lastFailureReason)
    }

    // Optional date fields
    if let lastVerified = lastVerified {
      fields["verifiedTimestamp"] = .date(lastVerified)
    }
    if let lastAttempted = lastAttempted {
      fields["attemptedTimestamp"] = .date(lastAttempted)
    }

    // Optional numeric fields
    if let updateFrequency = updateFrequency {
      fields["updateFrequency"] = .double(updateFrequency)
    }
    if let minUpdateInterval = minUpdateInterval {
      fields["minUpdateInterval"] = .double(minUpdateInterval)
    }

    // Array fields
    if !tags.isEmpty {
      fields["tags"] = .list(tags.map { .string($0) })
    }

    return fields
  }

  /// Create Feed from MistKit RecordInfo
  public init(from record: RecordInfo) {
    // Required string fields
    let feedURL: String
    if case .string(let value) = record.fields["feedURL"] {
      feedURL = value
    } else {
      feedURL = ""
    }

    let title: String
    if case .string(let value) = record.fields["title"] {
      title = value
    } else {
      title = ""
    }

    // Optional string fields
    let description: String?
    if case .string(let value) = record.fields["description"] {
      description = value
    } else {
      description = nil
    }

    let category: String?
    if case .string(let value) = record.fields["category"] {
      category = value
    } else {
      category = nil
    }

    let imageURL: String?
    if case .string(let value) = record.fields["imageURL"] {
      imageURL = value
    } else {
      imageURL = nil
    }

    let siteURL: String?
    if case .string(let value) = record.fields["siteURL"] {
      siteURL = value
    } else {
      siteURL = nil
    }

    let language: String?
    if case .string(let value) = record.fields["language"] {
      language = value
    } else {
      language = nil
    }

    let etag: String?
    if case .string(let value) = record.fields["etag"] {
      etag = value
    } else {
      etag = nil
    }

    let lastModified: String?
    if case .string(let value) = record.fields["lastModified"] {
      lastModified = value
    } else {
      lastModified = nil
    }

    let lastFailureReason: String?
    if case .string(let value) = record.fields["lastFailureReason"] {
      lastFailureReason = value
    } else {
      lastFailureReason = nil
    }

    // Boolean fields (stored as Int64)
    let isFeatured: Bool
    if case .int64(let value) = record.fields["isFeatured"] {
      isFeatured = value != 0
    } else {
      isFeatured = false
    }

    let isVerified: Bool
    if case .int64(let value) = record.fields["isVerified"] {
      isVerified = value != 0
    } else {
      isVerified = false
    }

    let isActive: Bool
    if case .int64(let value) = record.fields["isActive"] {
      isActive = value != 0
    } else {
      isActive = true
    }

    // Int64 fields
    let qualityScore: Int
    if case .int64(let value) = record.fields["qualityScore"] {
      qualityScore = Int(value)
    } else {
      qualityScore = 50
    }

    let subscriberCount: Int64
    if case .int64(let value) = record.fields["subscriberCount"] {
      subscriberCount = Int64(value)
    } else {
      subscriberCount = 0
    }

    let totalAttempts: Int64
    if case .int64(let value) = record.fields["totalAttempts"] {
      totalAttempts = Int64(value)
    } else {
      totalAttempts = 0
    }

    let successfulAttempts: Int64
    if case .int64(let value) = record.fields["successfulAttempts"] {
      successfulAttempts = Int64(value)
    } else {
      successfulAttempts = 0
    }

    let failureCount: Int64
    if case .int64(let value) = record.fields["failureCount"] {
      failureCount = Int64(value)
    } else {
      failureCount = 0
    }

    // Date fields
    // Note: addedAt now uses CloudKit's createdTimestamp system field
    let addedAt: Date
    if case .date(let value) = record.fields["createdTimestamp"] {
      addedAt = value
    } else {
      addedAt = Date()
    }

    let lastVerified: Date?
    if case .date(let value) = record.fields["verifiedTimestamp"] {
      lastVerified = value
    } else {
      lastVerified = nil
    }

    let lastAttempted: Date?
    if case .date(let value) = record.fields["attemptedTimestamp"] {
      lastAttempted = value
    } else {
      lastAttempted = nil
    }

    // TimeInterval fields
    let updateFrequency: TimeInterval?
    if case .double(let value) = record.fields["updateFrequency"] {
      updateFrequency = value
    } else {
      updateFrequency = nil
    }

    let minUpdateInterval: TimeInterval?
    if case .double(let value) = record.fields["minUpdateInterval"] {
      minUpdateInterval = value
    } else {
      minUpdateInterval = nil
    }

    // Array fields
    let tags: [String]
    if case .list(let values) = record.fields["tags"] {
      tags = values.compactMap {
        if case .string(let str) = $0 {
          return str
        }
        return nil
      }
    } else {
      tags = []
    }

    self.init(
      recordName: record.recordName,
      recordChangeTag: record.recordChangeTag,
      feedURL: feedURL,
      title: title,
      description: description,
      category: category,
      imageURL: imageURL,
      siteURL: siteURL,
      language: language,
      isFeatured: isFeatured,
      isVerified: isVerified,
      qualityScore: qualityScore,
      subscriberCount: subscriberCount,
      addedAt: addedAt,
      lastVerified: lastVerified,
      updateFrequency: updateFrequency,
      tags: tags,
      totalAttempts: totalAttempts,
      successfulAttempts: successfulAttempts,
      lastAttempted: lastAttempted,
      isActive: isActive,
      etag: etag,
      lastModified: lastModified,
      failureCount: failureCount,
      lastFailureReason: lastFailureReason,
      minUpdateInterval: minUpdateInterval
    )
  }
}
