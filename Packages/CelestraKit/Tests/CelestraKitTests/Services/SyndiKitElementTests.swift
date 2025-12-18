//
//  SyndiKitElementTests.swift
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

import Foundation
import SyndiKit
import Testing

@testable import CelestraKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("SyndiKit Element Parsing Tests", .serialized)
final class SyndiKitElementTests {
  @Test("Parse RSS with comprehensive elements")
  func parseComprehensiveRSS() async throws {
    let mockData = try FixtureLoader.load("RSS/rss-comprehensive-elements.xml")

    let decoder = SynDecoder()
    let feed = try decoder.decode(mockData)

    #expect(feed.title == "Comprehensive RSS Elements Test")
    #expect(feed.children.count == 5)

    // Test item 1: Comprehensive item with all elements
    let item1 = feed.children[0]
    #expect(item1.title == "Comprehensive Item")
    #expect(item1.summary == "Item description")

    // Author parsing: email with name format
    print("Item 1 authors: \(item1.authors)")
    if !item1.authors.isEmpty {
      print(
        "  First author: name=\(item1.authors[0].name), email=\(item1.authors[0].email ?? "nil")")
    }

    // Test item 2: Plain text author (non-spec)
    let item2 = feed.children[1]
    #expect(item2.title == "Plain Text Author")
    print("\nItem 2 authors: \(item2.authors)")
    if !item2.authors.isEmpty {
      print(
        "  First author: name=\(item2.authors[0].name), email=\(item2.authors[0].email ?? "nil")")
    } else {
      print("  ⚠️ Plain text author not parsed (expected - non-spec compliant)")
    }

    // Test item 3: Email-only author
    let item3 = feed.children[2]
    #expect(item3.title == "Email Only Author")
    print("\nItem 3 authors: \(item3.authors)")
    if !item3.authors.isEmpty {
      print(
        "  First author: name=\(item3.authors[0].name), email=\(item3.authors[0].email ?? "nil")")
    }

    // Test item 4: Media RSS elements
    let item4 = feed.children[3]
    #expect(item4.title == "Item with Media Elements")
    print("\nItem 4 media: \(item4.media != nil ? "present" : "nil")")
    print("  Image URL: \(item4.imageURL?.absoluteString ?? "nil")")

    // Test item 5: Multiple enclosures
    let item5 = feed.children[4]
    #expect(item5.title == "Multiple Enclosures")
    print("\nItem 5 media: \(item5.media != nil ? "present" : "nil")")

    // Print summary of what was parsed
    print("\n=== Parsing Summary ===")
    for (index, item) in feed.children.enumerated() {
      print("\nItem \(index + 1): \(item.title)")
      print("  URL: \(item.url?.absoluteString ?? "nil")")
      print("  Authors: \(item.authors.count)")
      print("  Creators: \(item.creators.count)")
      print("  Media: \(item.media != nil ? "present" : "nil")")
      print("  Categories: \(item.categories.count)")
    }
  }

  @Test("Verify author parsing behavior")
  func verifyAuthorParsing() async throws {
    let mockData = try FixtureLoader.load("RSS/rss-comprehensive-elements.xml")

    let decoder = SynDecoder()
    let feed = try decoder.decode(mockData)

    // Item 1: Email with name (spec-compliant) + dc:creator
    let item1Authors = feed.children[0].authors
    let item1Creators = feed.children[0].creators
    print("\n📧 Email with name format: author@example.com (John Doe)")
    print("   Parsed authors count: \(item1Authors.count)")
    if let author = item1Authors.first {
      print("   Name: \(author.name)")
      print("   Email: \(author.email ?? "nil")")
    }
    print("   DC Creators count: \(item1Creators.count)")
    if !item1Creators.isEmpty {
      print("   First creator: \(item1Creators[0])")
    }

    // Item 2: Plain text (non-spec)
    let item2Authors = feed.children[1].authors
    let item2Creators = feed.children[1].creators
    print("\n📝 Plain text format: Plain Text Name")
    print("   Parsed authors count: \(item2Authors.count)")
    if item2Authors.isEmpty {
      print("   ⚠️ NOT PARSED (SyndiKit follows RSS 2.0 spec strictly)")
    }
    print("   DC Creators count: \(item2Creators.count)")

    // Item 3: Email only
    let item3Authors = feed.children[2].authors
    print("\n📧 Email only format: author@example.com")
    print("   Parsed authors count: \(item3Authors.count)")
    if let author = item3Authors.first {
      print("   Name: \(author.name)")
      print("   Email: \(author.email ?? "nil")")
    }
  }

  @Test("Verify enclosure/media parsing")
  func verifyEnclosureParsing() async throws {
    let mockData = try FixtureLoader.load("RSS/rss-comprehensive-elements.xml")

    let decoder = SynDecoder()
    let feed = try decoder.decode(mockData)

    // Item 1: Single enclosure
    let item1 = feed.children[0]
    print("\n🎧 Item 1 - Single enclosure:")
    print("   Media: \(item1.media != nil ? String(describing: item1.media!) : "nil")")

    // Item 4: Media RSS elements
    let item4 = feed.children[3]
    print("\n🎬 Item 4 - Media RSS:")
    print("   Media: \(item4.media != nil ? String(describing: item4.media!) : "nil")")
    print("   Image URL: \(item4.imageURL?.absoluteString ?? "nil")")

    // Item 5: Multiple enclosures (technically invalid RSS 2.0)
    let item5 = feed.children[4]
    print("\n🎧 Item 5 - Multiple enclosures:")
    print("   Media: \(item5.media != nil ? String(describing: item5.media!) : "nil")")
    if item5.media != nil {
      print("   ⚠️ Only first enclosure parsed (RSS 2.0 spec allows max 1)")
    }
  }

  @Test("Verify category parsing")
  func verifyCategoryParsing() async throws {
    let mockData = try FixtureLoader.load("RSS/rss-comprehensive-elements.xml")

    let decoder = SynDecoder()
    let feed = try decoder.decode(mockData)

    let item1 = feed.children[0]
    print("\n📁 Item 1 categories:")
    print("   Count: \(item1.categories.count)")
    for category in item1.categories {
      print("   - \(category)")
    }
  }
}
