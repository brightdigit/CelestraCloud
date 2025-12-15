//
//  Article+MistKit.swift
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

public extension Article {
  /// Convert to CloudKit record fields dictionary using MistKit's FieldValue
  func toFieldsDict() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "feedRecordName": .string(feedRecordName),
      "guid": .string(guid),
      "title": .string(title),
      "url": .string(url),
      "fetchedAt": .date(fetchedAt),
      "expiresAt": .date(expiresAt),
      "contentHash": .string(contentHash),
    ]

    // Optional string fields
    if let excerpt = excerpt {
      fields["excerpt"] = .string(excerpt)
    }
    if let content = content {
      fields["content"] = .string(content)
    }
    if let contentText = contentText {
      fields["contentText"] = .string(contentText)
    }
    if let author = author {
      fields["author"] = .string(author)
    }
    if let imageURL = imageURL {
      fields["imageURL"] = .string(imageURL)
    }
    if let language = language {
      fields["language"] = .string(language)
    }

    // Optional date field
    if let publishedDate = publishedDate {
      fields["publishedDate"] = .date(publishedDate)
    }

    // Optional int fields
    if let wordCount = wordCount {
      fields["wordCount"] = .int64(wordCount)
    }
    if let estimatedReadingTime = estimatedReadingTime {
      fields["estimatedReadingTime"] = .int64(estimatedReadingTime)
    }

    // Array fields
    if !tags.isEmpty {
      fields["tags"] = .list(tags.map { .string($0) })
    }

    return fields
  }

  /// Create Article from MistKit RecordInfo
  init(from record: RecordInfo) {
    // Required string fields
    let feedRecordName: String
    if case .string(let value) = record.fields["feedRecordName"] {
      feedRecordName = value
    } else {
      feedRecordName = ""
    }

    let guid: String
    if case .string(let value) = record.fields["guid"] {
      guid = value
    } else {
      guid = ""
    }

    let title: String
    if case .string(let value) = record.fields["title"] {
      title = value
    } else {
      title = ""
    }

    let url: String
    if case .string(let value) = record.fields["url"] {
      url = value
    } else {
      url = ""
    }

    // Optional string fields
    let excerpt: String?
    if case .string(let value) = record.fields["excerpt"] {
      excerpt = value
    } else {
      excerpt = nil
    }

    let content: String?
    if case .string(let value) = record.fields["content"] {
      content = value
    } else {
      content = nil
    }

    let contentText: String?
    if case .string(let value) = record.fields["contentText"] {
      contentText = value
    } else {
      contentText = nil
    }

    let author: String?
    if case .string(let value) = record.fields["author"] {
      author = value
    } else {
      author = nil
    }

    let imageURL: String?
    if case .string(let value) = record.fields["imageURL"] {
      imageURL = value
    } else {
      imageURL = nil
    }

    let language: String?
    if case .string(let value) = record.fields["language"] {
      language = value
    } else {
      language = nil
    }

    // Date fields
    let publishedDate: Date?
    if case .date(let value) = record.fields["publishedDate"] {
      publishedDate = value
    } else {
      publishedDate = nil
    }

    let fetchedAt: Date
    if case .date(let value) = record.fields["fetchedAt"] {
      fetchedAt = value
    } else {
      fetchedAt = Date()
    }

    let expiresAt: Date?
    if case .date(let value) = record.fields["expiresAt"] {
      expiresAt = value
    } else {
      expiresAt = nil
    }

    // Calculate ttlDays from fetchedAt and expiresAt if available
    let ttlDays: Int
    if let expiresAt = expiresAt {
      let interval = expiresAt.timeIntervalSince(fetchedAt)
      ttlDays = max(1, Int(interval / (24 * 60 * 60)))
    } else {
      ttlDays = 30  // Default TTL
    }

    // Optional int fields
    let wordCount: Int?
    if case .int64(let value) = record.fields["wordCount"] {
      wordCount = Int(value)
    } else {
      wordCount = nil
    }

    let estimatedReadingTime: Int?
    if case .int64(let value) = record.fields["estimatedReadingTime"] {
      estimatedReadingTime = Int(value)
    } else {
      estimatedReadingTime = nil
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
      feedRecordName: feedRecordName,
      guid: guid,
      title: title,
      excerpt: excerpt,
      content: content,
      contentText: contentText,
      author: author,
      url: url,
      imageURL: imageURL,
      publishedDate: publishedDate,
      fetchedAt: fetchedAt,
      ttlDays: ttlDays,
      wordCount: wordCount,
      estimatedReadingTime: estimatedReadingTime,
      language: language,
      tags: tags
    )
  }
}
