//
//  ConfigurationLoader.swift
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

internal import Configuration
internal import Foundation
internal import MistKit

/// Loads and merges configuration from multiple sources
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public actor ConfigurationLoader {
  private let configReader: ConfigReader

  public init() {
    var providers: [any ConfigProvider] = []

    // Priority 1: Command-line arguments (highest)
    providers.append(CommandLineArgumentsProvider(
      secretsSpecifier: .specific([
        "--cloudkit-key-id",
        "--cloudkit-private-key-path"
      ])
    ))

    // Priority 2: Environment variables
    providers.append(EnvironmentVariablesProvider())

    self.configReader = ConfigReader(providers: providers)
  }

  // MARK: - Configuration Keys

  private enum ConfigKeys {
    enum CloudKit {
      static let containerID = "cloudkit.container_id"
      static let containerIDEnv = "CLOUDKIT_CONTAINER_ID"
      static let keyID = "cloudkit.key_id"
      static let keyIDEnv = "CLOUDKIT_KEY_ID"
      static let privateKeyPath = "cloudkit.private_key_path"
      static let privateKeyPathEnv = "CLOUDKIT_PRIVATE_KEY_PATH"
      static let environment = "cloudkit.environment"
      static let environmentEnv = "CLOUDKIT_ENVIRONMENT"
    }

    enum Update {
      static let delay = "update.delay"
      static let delayEnv = "UPDATE_DELAY"
      static let skipRobotsCheck = "update.skip_robots_check"
      static let skipRobotsCheckEnv = "UPDATE_SKIP_ROBOTS_CHECK"
      static let maxFailures = "update.max_failures"
      static let maxFailuresEnv = "UPDATE_MAX_FAILURES"
      static let minPopularity = "update.min_popularity"
      static let minPopularityEnv = "UPDATE_MIN_POPULARITY"
      static let lastAttemptedBefore = "update.last_attempted_before"
      static let lastAttemptedBeforeEnv = "UPDATE_LAST_ATTEMPTED_BEFORE"
    }
  }

  /// Load complete configuration with all defaults applied
  public func loadConfiguration() async throws -> CelestraConfiguration {
    // CloudKit configuration
    let cloudkit = CloudKitConfiguration(
      containerID: readString(forKey: ConfigKeys.CloudKit.containerID) ??
        readString(forKey: ConfigKeys.CloudKit.containerIDEnv),
      keyID: readString(forKey: ConfigKeys.CloudKit.keyID) ??
        readString(forKey: ConfigKeys.CloudKit.keyIDEnv),
      privateKeyPath: readString(forKey: ConfigKeys.CloudKit.privateKeyPath) ??
        readString(forKey: ConfigKeys.CloudKit.privateKeyPathEnv),
      environment: parseEnvironment(
        readString(forKey: ConfigKeys.CloudKit.environment) ??
        readString(forKey: ConfigKeys.CloudKit.environmentEnv)
      )
    )

    // Update command configuration
    let update = UpdateCommandConfiguration(
      delay: readDouble(forKey: ConfigKeys.Update.delay) ??
        readDouble(forKey: ConfigKeys.Update.delayEnv) ?? 2.0,
      skipRobotsCheck: readBool(forKey: ConfigKeys.Update.skipRobotsCheck) ??
        readBool(forKey: ConfigKeys.Update.skipRobotsCheckEnv) ?? false,
      maxFailures: readInt64(forKey: ConfigKeys.Update.maxFailures) ??
        readInt64(forKey: ConfigKeys.Update.maxFailuresEnv),
      minPopularity: readInt64(forKey: ConfigKeys.Update.minPopularity) ??
        readInt64(forKey: ConfigKeys.Update.minPopularityEnv),
      lastAttemptedBefore: readDate(forKey: ConfigKeys.Update.lastAttemptedBefore) ??
        readDate(forKey: ConfigKeys.Update.lastAttemptedBeforeEnv)
    )

    return CelestraConfiguration(
      cloudkit: cloudkit,
      update: update
    )
  }

  // MARK: - Private Helpers

  private func readString(forKey key: String) -> String? {
    configReader.string(forKey: ConfigKey(key))
  }

  private func readDouble(forKey key: String) -> Double? {
    configReader.double(forKey: ConfigKey(key))
  }

  private func readBool(forKey key: String) -> Bool? {
    configReader.bool(forKey: ConfigKey(key))
  }

  private func readInt64(forKey key: String) -> Int64? {
    if let intValue = configReader.int(forKey: ConfigKey(key)) {
      return Int64(intValue)
    }
    return nil
  }

  private func parseEnvironment(_ value: String?) -> MistKit.Environment {
    guard let value = value?.lowercased() else { return .development }
    return value == "production" ? .production : .development
  }

  private func readDate(forKey key: String) -> Date? {
    // Swift Configuration automatically converts ISO8601 strings to Date
    configReader.string(forKey: ConfigKey(key), as: Date.self)
  }
}
