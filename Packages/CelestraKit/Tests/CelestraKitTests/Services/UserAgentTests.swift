//
//  UserAgentTests.swift
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

import Testing

@testable import CelestraKit

@Suite("UserAgent Tests")
struct UserAgentTests {
  // MARK: - Factory Method Tests

  @Test("Cloud factory method creates UserAgent instance")
  func cloudFactoryCreatesInstance() {
    let userAgent = UserAgent.cloud(build: 1)

    #expect(userAgent.name == "CelestraCloud")
  }

  @Test("App factory method creates UserAgent instance")
  func appFactoryCreatesInstance() {
    let userAgent = UserAgent.app(build: 1)

    #expect(userAgent.name == "Celestra")
  }

  @Test("Cloud factory sets correct name")
  func cloudFactorySetsCorrectName() {
    let userAgent = UserAgent.cloud(build: 42)

    #expect(userAgent.name == "CelestraCloud")
  }

  @Test("App factory sets correct name")
  func appFactorySetsCorrectName() {
    let userAgent = UserAgent.app(build: 42)

    #expect(userAgent.name == "Celestra")
  }

  // MARK: - Property Tests

  @Test("Cloud user-agent has CelestraCloud name")
  func cloudUserAgentHasCorrectName() {
    let userAgent = UserAgent.cloud(build: 1)

    #expect(userAgent.name == "CelestraCloud")
  }

  @Test("App user-agent has Celestra name")
  func appUserAgentHasCorrectName() {
    let userAgent = UserAgent.app(build: 1)

    #expect(userAgent.name == "Celestra")
  }

  @Test("Cloud user-agent has correct URL")
  func cloudUserAgentHasCorrectURL() {
    let userAgent = UserAgent.cloud(build: 1)

    #expect(userAgent.string.contains("https://github.com/brightdigit/CelestraCloud"))
  }

  @Test("App user-agent has correct URL")
  func appUserAgentHasCorrectURL() {
    let userAgent = UserAgent.app(build: 1)

    #expect(userAgent.string.contains("https://celestr.app"))
  }

  // MARK: - String Generation Tests

  @Test("Cloud user-agent string format is correct")
  func cloudUserAgentStringFormat() {
    let userAgent = UserAgent.cloud(build: 1)

    #expect(userAgent.string == "CelestraCloud/1 (https://github.com/brightdigit/CelestraCloud)")
  }

  @Test("App user-agent string format is correct")
  func appUserAgentStringFormat() {
    let userAgent = UserAgent.app(build: 1)

    #expect(userAgent.string == "Celestra/1 (https://celestr.app)")
  }

  @Test("User-agent string includes name component")
  func userAgentStringIncludesName() {
    let cloudAgent = UserAgent.cloud(build: 5)
    let appAgent = UserAgent.app(build: 5)

    #expect(cloudAgent.string.contains("CelestraCloud"))
    #expect(appAgent.string.contains("Celestra"))
  }

  @Test("User-agent string includes build number")
  func userAgentStringIncludesBuildNumber() {
    let userAgent = UserAgent.cloud(build: 42)

    #expect(userAgent.string.contains("/42"))
  }

  @Test("User-agent string format is consistent across multiple calls")
  func userAgentStringFormatConsistency() {
    let userAgent = UserAgent.cloud(build: 1)

    let firstCall = userAgent.string
    let secondCall = userAgent.string
    let thirdCall = userAgent.string

    #expect(firstCall == secondCall)
    #expect(secondCall == thirdCall)
  }

  // MARK: - Edge Case Tests

  @Test("User-agent handles large build numbers")
  func userAgentHandlesLargeBuildNumbers() {
    let userAgent = UserAgent.cloud(build: 999_999)

    #expect(
      userAgent.string == "CelestraCloud/999999 (https://github.com/brightdigit/CelestraCloud)")
  }

  @Test("User-agent handles build number zero")
  func userAgentHandlesBuildNumberZero() {
    let userAgent = UserAgent.app(build: 0)

    #expect(userAgent.string == "Celestra/0 (https://celestr.app)")
  }

  @Test("User-agent string interpolation does not fail")
  func userAgentStringInterpolationDoesNotFail() {
    let cloudAgent = UserAgent.cloud(build: 100)
    let appAgent = UserAgent.app(build: 200)

    // These should not crash
    let cloudString = cloudAgent.string
    let appString = appAgent.string

    #expect(!cloudString.isEmpty)
    #expect(!appString.isEmpty)
  }
}
