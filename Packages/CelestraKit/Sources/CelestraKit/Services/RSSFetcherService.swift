//
//  RSSFetcherService.swift
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
import Logging
import SyndiKit

#if canImport(FoundationNetworking)
  public import FoundationNetworking
#endif

/// Service for fetching and parsing RSS feeds using SyndiKit with web etiquette
public struct RSSFetcherService {
  private let urlSession: URLSession
  private let userAgent: UserAgent

  public init(
    userAgent: UserAgent,
    configuration: URLSessionConfiguration = .default
  ) {
    self.userAgent = userAgent

    // Create a copy to avoid mutating shared .default singleton
    guard
      let config = createURLSessionConfiguration(
        from: configuration,
        headers: [
          "User-Agent": userAgent.string,
          "Accept":
            "application/rss+xml, application/atom+xml, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.7",
        ]
      )
    else {
      preconditionFailure("Failed to copy URLSessionConfiguration")
    }

    self.urlSession = URLSession(configuration: config)
  }

  // Internal initializer for testing with custom URLSession
  internal init(urlSession: URLSession, userAgent: UserAgent) {
    self.urlSession = urlSession
    self.userAgent = userAgent
  }

  /// Fetch and parse RSS feed from URL with conditional request support
  /// - Parameters:
  ///   - url: Feed URL to fetch
  ///   - lastModified: Optional Last-Modified header from previous fetch
  ///   - etag: Optional ETag header from previous fetch
  /// - Returns: Fetch response with feed data and HTTP metadata
  public func fetchFeed(
    from url: URL,
    lastModified: String? = nil,
    etag: String? = nil
  ) async throws -> FetchResponse {
    CelestraLogger.rss.info("📡 Fetching RSS feed from \(url.absoluteString)")

    // Build request with conditional headers
    var request = URLRequest(url: url)
    if let lastModified = lastModified {
      request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
    }
    if let etag = etag {
      request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }

    do {
      // 1. Fetch RSS XML from URL
      let (data, response) = try await urlSession.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw RSSFetcherError.invalidFeedData("Non-HTTP response")
      }

      // Extract response headers
      let responseLastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified")
      let responseEtag = httpResponse.value(forHTTPHeaderField: "ETag")

      // Handle 304 Not Modified
      if httpResponse.statusCode == 304 {
        CelestraLogger.rss.info("✅ Feed not modified (304)")
        return FetchResponse(
          feedData: nil,
          lastModified: responseLastModified ?? lastModified,
          etag: responseEtag ?? etag,
          wasModified: false
        )
      }

      // Check for error status codes
      guard (200...299).contains(httpResponse.statusCode) else {
        throw RSSFetcherError.rssFetchFailed(url, underlying: URLError(.badServerResponse))
      }

      // 2. Parse feed using SyndiKit
      let decoder = SynDecoder()
      let feed = try decoder.decode(data)

      // 3. Parse RSS metadata for update intervals
      let minUpdateInterval = parseUpdateInterval(from: feed)

      // 4. Convert Feedable to our FeedData structure
      let items = feed.children.compactMap { entry -> FeedItem? in
        // Get link from url property or use id's description as fallback
        let link: String
        if let url = entry.url {
          link = url.absoluteString
        } else if case .url(let url) = entry.id {
          link = url.absoluteString
        } else {
          // Use id's string representation as fallback
          link = entry.id.description
        }

        // Skip if link is empty
        guard !link.isEmpty else {
          CelestraLogger.rss.warning(
            "⚠️ Dropping feed item with empty link: title='\(entry.title)', id='\(entry.id.description)'"
          )
          return nil
        }

        return FeedItem(
          title: entry.title,
          link: link,
          description: entry.summary,
          content: entry.contentHtml,
          author: entry.authors.first?.name,
          pubDate: entry.published,
          // GUID Strategy: Use SyndiKit's EntryID.description which provides:
          // - RSS: <guid> element value, or <link> as fallback
          // - Atom: <id> element value (required by spec)
          // This ensures globally unique identifiers for deduplication
          guid: entry.id.description
        )
      }

      let feedData = FeedData(
        title: feed.title,
        description: feed.summary,
        items: items,
        minUpdateInterval: minUpdateInterval
      )

      CelestraLogger.rss.info("✅ Successfully fetched feed: \(feed.title) (\(items.count) items)")
      if let interval = minUpdateInterval {
        CelestraLogger.rss.info("   📅 Feed requests updates every \(Int(interval / 60)) minutes")
      }

      return FetchResponse(
        feedData: feedData,
        lastModified: responseLastModified,
        etag: responseEtag,
        wasModified: true
      )
    } catch let error as DecodingError {
      CelestraLogger.errors.error("❌ Failed to parse feed: \(error.localizedDescription)")
      throw RSSFetcherError.invalidFeedData(error.localizedDescription)
    } catch {
      CelestraLogger.errors.error("❌ Failed to fetch feed: \(error.localizedDescription)")
      throw RSSFetcherError.rssFetchFailed(url, underlying: error)
    }
  }

  /// Parse minimum update interval from RSS feed metadata
  /// - Parameter feed: Parsed feed from SyndiKit
  /// - Returns: Minimum update interval in seconds, or nil if not specified
  private func parseUpdateInterval(from feed: any Feedable) -> TimeInterval? {
    // Only RSS feeds support TTL and Syndication module
    // Atom and JSON feeds don't have equivalent metadata
    guard let rssFeed = feed as? RSSFeed else {
      return nil
    }

    // Priority 1: Use <ttl> if present (in minutes)
    if let ttl = rssFeed.channel.ttl, ttl > 0 {
      return TimeInterval(ttl * 60)  // Convert minutes to seconds
    }

    // Priority 2: Use Syndication module (<sy:updatePeriod> and <sy:updateFrequency>)
    if let syndication = rssFeed.channel.syndication {
      let baseInterval: TimeInterval
      switch syndication.period {
      case .hourly:
        baseInterval = 3_600  // 1 hour
      case .daily:
        baseInterval = 86_400  // 1 day
      case .weekly:
        baseInterval = 604_800  // 1 week
      case .monthly:
        baseInterval = 2_592_000  // 30 days (approximation)
      case .yearly:
        baseInterval = 31_536_000  // 365 days
      }

      // frequency = how many times per period
      // Calculate minimum interval between updates
      guard syndication.frequency > 0 else {
        CelestraLogger.rss.warning("⚠️ Invalid syndication frequency (0), using period as interval")
        return baseInterval
      }
      return baseInterval / TimeInterval(syndication.frequency)
    }

    return nil  // No TTL or syndication info found
  }
}
