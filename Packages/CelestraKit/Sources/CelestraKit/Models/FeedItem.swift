//
//  FeedItem.swift
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

/// Represents a single RSS/Atom feed entry/item
public struct FeedItem: Sendable, Codable, Hashable {
  /// Item title
  public let title: String

  /// Item link/URL
  public let link: String

  /// Item summary or excerpt
  public let description: String?

  /// Full HTML content
  public let content: String?

  /// Author name
  public let author: String?

  /// Publication date
  public let pubDate: Date?

  /// Globally unique identifier
  public let guid: String

  /// Initialize a FeedItem instance
  /// - Parameters:
  ///   - title: Item title
  ///   - link: Item link/URL
  ///   - description: Item summary or excerpt (optional)
  ///   - content: Full HTML content (optional)
  ///   - author: Author name (optional)
  ///   - pubDate: Publication date (optional)
  ///   - guid: Globally unique identifier
  public init(
    title: String,
    link: String,
    description: String? = nil,
    content: String? = nil,
    author: String? = nil,
    pubDate: Date? = nil,
    guid: String
  ) {
    self.title = title
    self.link = link
    self.description = description
    self.content = content
    self.author = author
    self.pubDate = pubDate
    self.guid = guid
  }
}
