//
//  ClearCommand.swift
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

import ArgumentParser
import CelestraCloudKit
import CelestraKit
import Foundation
import MistKit

struct ClearCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "clear",
    abstract: "Delete all feeds and articles from CloudKit",
    discussion: """
      Removes all Feed and Article records from the CloudKit public database. \
      Use with caution as this operation cannot be undone.
      """
  )

  @Flag(name: .long, help: "Skip confirmation prompt")
  var confirm: Bool = false

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func run() async throws {
    // Require confirmation
    if !confirm {
      print("⚠️  This will DELETE ALL feeds and articles from CloudKit!")
      print("   Run with --confirm to proceed")
      print("")
      print("   Example: celestra-cloud clear --confirm")
      return
    }

    print("🗑️  Clearing all data from CloudKit...")

    let service = try CelestraConfig.createCloudKitService()

    // Delete articles first (to avoid orphans)
    print("📋 Deleting articles...")
    try await service.deleteAllArticles()
    print("✅ Articles deleted")

    // Delete feeds
    print("📋 Deleting feeds...")
    try await service.deleteAllFeeds()
    print("✅ Feeds deleted")

    print("\n✅ All data cleared!")
  }
}
