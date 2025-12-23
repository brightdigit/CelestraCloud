//
//  CloudKitConfiguration.swift
//  CelestraCloud
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
public import MistKit

/// CloudKit credentials and environment settings
public struct CloudKitConfiguration: Sendable {
  public var containerID: String?
  public var keyID: String?
  public var privateKeyPath: String?
  public var environment: MistKit.Environment

  public init(
    containerID: String? = nil,
    keyID: String? = nil,
    privateKeyPath: String? = nil,
    environment: MistKit.Environment = .development
  ) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
    self.environment = environment
  }

  /// Validate that all required fields are present
  public func validated() throws -> ValidatedCloudKitConfiguration {
    guard let containerID = containerID, !containerID.isEmpty else {
      throw EnhancedConfigurationError(
        "CloudKit container ID required",
        key: "cloudkit.container_id"
      )
    }
    guard let keyID = keyID, !keyID.isEmpty else {
      throw EnhancedConfigurationError(
        "CloudKit key ID required",
        key: "cloudkit.key_id"
      )
    }
    guard let privateKeyPath = privateKeyPath, !privateKeyPath.isEmpty else {
      throw EnhancedConfigurationError(
        "CloudKit private key path required",
        key: "cloudkit.private_key_path"
      )
    }
    return ValidatedCloudKitConfiguration(
      containerID: containerID,
      keyID: keyID,
      privateKeyPath: privateKeyPath,
      environment: environment
    )
  }
}

/// Validated CloudKit configuration with all required fields
public struct ValidatedCloudKitConfiguration: Sendable {
  public let containerID: String
  public let keyID: String
  public let privateKeyPath: String
  public let environment: MistKit.Environment

  public init(
    containerID: String,
    keyID: String,
    privateKeyPath: String,
    environment: MistKit.Environment
  ) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
    self.environment = environment
  }
}
