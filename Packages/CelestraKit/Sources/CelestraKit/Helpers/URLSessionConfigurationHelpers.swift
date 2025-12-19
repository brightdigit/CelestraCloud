//
//  URLSessionConfigurationHelpers.swift
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

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Creates a copy of a URLSessionConfiguration with additional HTTP headers.
///
/// This function safely copies the configuration to avoid mutating shared singletons
/// like `.default` or `.ephemeral`.
///
/// - Parameters:
///   - configuration: The source configuration to copy
///   - headers: HTTP headers to add to the configuration
/// - Returns: A new configuration with the headers set, or nil if copy fails
internal func createURLSessionConfiguration(
  from configuration: URLSessionConfiguration,
  headers: [String: String]
) -> URLSessionConfiguration? {
  guard let config = configuration.copy() as? URLSessionConfiguration else {
    return nil
  }
  config.httpAdditionalHeaders = headers
  return config
}
