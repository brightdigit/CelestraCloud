//
//  CloudKitConversionErrorTests.swift
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
import Testing

@testable import CelestraKit

@Suite("CloudKitConversionError Tests")
struct CloudKitConversionErrorTests {
  @Test("missingRequiredField error has correct description")
  func testMissingRequiredFieldDescription() async throws {
    let error = CloudKitConversionError.missingRequiredField(
      fieldName: "title",
      recordType: "Feed"
    )
    let description = error.errorDescription!

    #expect(description.contains("title"))
    #expect(description.contains("Feed"))
    #expect(description.contains("Required field"))
  }

  @Test("invalidFieldType error has correct description")
  func testInvalidFieldTypeDescription() async throws {
    let error = CloudKitConversionError.invalidFieldType(
      fieldName: "qualityScore",
      expected: "Int",
      actual: "String"
    )
    let description = error.errorDescription!

    #expect(description.contains("qualityScore"))
    #expect(description.contains("Int"))
    #expect(description.contains("String"))
  }

  @Test("invalidFieldValue error has correct description")
  func testInvalidFieldValueDescription() async throws {
    let error = CloudKitConversionError.invalidFieldValue(
      fieldName: "feedURL",
      reason: "Not a valid URL"
    )
    let description = error.errorDescription!

    #expect(description.contains("feedURL"))
    #expect(description.contains("Not a valid URL"))
  }

  @Test("Errors conform to LocalizedError")
  func testLocalizedErrorConformance() async throws {
    let error = CloudKitConversionError.missingRequiredField(
      fieldName: "test",
      recordType: "Test"
    )
    let _: any LocalizedError = error  // Compile-time check
    #expect(error.errorDescription != nil)
  }
}
