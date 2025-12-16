//
//  RateLimiter.swift
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

/// Actor-based rate limiter for RSS feed fetching
public actor RateLimiter {
  private var lastFetchTimes: [String: Date] = [:]
  private let defaultDelay: TimeInterval
  private let perDomainDelay: TimeInterval

  /// Initialize rate limiter with configurable delays
  /// - Parameters:
  ///   - defaultDelay: Default delay between any two feed fetches (seconds)
  ///   - perDomainDelay: Additional delay when fetching from the same domain (seconds)
  public init(defaultDelay: TimeInterval = 2.0, perDomainDelay: TimeInterval = 5.0) {
    self.defaultDelay = defaultDelay
    self.perDomainDelay = perDomainDelay
  }

  /// Wait if necessary before fetching a URL
  /// - Parameters:
  ///   - url: The URL to fetch
  ///   - minimumInterval: Optional minimum interval to respect (e.g., from RSS <ttl>)
  public func waitIfNeeded(for url: URL, minimumInterval: TimeInterval? = nil) async {
    guard let host = url.host else {
      return
    }

    let now = Date()
    let key = host

    // Determine the required delay
    var requiredDelay = defaultDelay

    // Use per-domain delay if we've fetched from this domain before
    if let lastFetch = lastFetchTimes[key] {
      requiredDelay = max(requiredDelay, perDomainDelay)

      // If feed specifies minimum interval, respect it
      if let minInterval = minimumInterval {
        requiredDelay = max(requiredDelay, minInterval)
      }

      let timeSinceLastFetch = now.timeIntervalSince(lastFetch)
      let remainingDelay = requiredDelay - timeSinceLastFetch

      if remainingDelay > 0 {
        let nanoseconds = UInt64(remainingDelay * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
      }
    }

    // Record this fetch time
    lastFetchTimes[key] = Date()
  }

  /// Wait with a global delay (between any two fetches, regardless of domain)
  public func waitGlobal() async {
    // Get the most recent fetch time across all domains
    if let mostRecent = lastFetchTimes.values.max() {
      let timeSinceLastFetch = Date().timeIntervalSince(mostRecent)
      let remainingDelay = defaultDelay - timeSinceLastFetch

      if remainingDelay > 0 {
        let nanoseconds = UInt64(remainingDelay * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
      }
    }
  }

  /// Clear all rate limiting history
  public func reset() {
    lastFetchTimes.removeAll()
  }

  /// Clear rate limiting history for a specific domain
  public func reset(for host: String) {
    lastFetchTimes.removeValue(forKey: host)
  }
}
