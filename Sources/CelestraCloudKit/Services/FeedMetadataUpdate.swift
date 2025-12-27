//
//  FeedMetadataUpdate.swift
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

public import Foundation

/// Metadata for updating a feed record
public struct FeedMetadataUpdate: Sendable, Equatable {
  public let title: String
  public let description: String?
  public let etag: String?
  public let lastModified: String?
  public let minUpdateInterval: TimeInterval?
  public let totalAttempts: Int64
  public let successfulAttempts: Int64
  public let failureCount: Int64

  public init(
    title: String,
    description: String?,
    etag: String?,
    lastModified: String?,
    minUpdateInterval: TimeInterval?,
    totalAttempts: Int64,
    successfulAttempts: Int64,
    failureCount: Int64
  ) {
    self.title = title
    self.description = description
    self.etag = etag
    self.lastModified = lastModified
    self.minUpdateInterval = minUpdateInterval
    self.totalAttempts = totalAttempts
    self.successfulAttempts = successfulAttempts
    self.failureCount = failureCount
  }
}
