//
//  FixtureLoader.swift
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

internal enum FixtureLoader {
  internal enum FixtureError: Error {
    case fileNotFound(String)
    case invalidData
  }

  /// Load fixture data from Tests/CelestraKitTests/Fixtures/
  internal static func load(_ filename: String) throws -> Data {
    // Get the test bundle
    #if SWIFT_PACKAGE
      let bundle = Bundle.module
    #else
      let bundle = Bundle(for: TestBundleClass.self)
    #endif

    guard
      let url = bundle.url(
        forResource: filename,
        withExtension: nil,
        subdirectory: "Fixtures"
      )
    else {
      throw FixtureError.fileNotFound(filename)
    }

    return try Data(contentsOf: url)
  }
}

// Helper class for getting test bundle in non-SPM contexts
private class TestBundleClass {}
