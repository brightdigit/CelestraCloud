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

  public init(cliOverrides: [String: Any] = [:]) {
    var providers: [any ConfigProvider] = []

    // Priority 1: CLI overrides (highest)
    if !cliOverrides.isEmpty {
      let configValues = Self.convertToConfigValues(cliOverrides)
      providers.append(InMemoryProvider(name: "CLI", values: configValues))
    }

    // Priority 2: Environment variables
    providers.append(EnvironmentVariablesProvider())

    self.configReader = ConfigReader(providers: providers)
  }

  /// Convert [String: Any] to [AbsoluteConfigKey: ConfigValue]
  private static func convertToConfigValues(_ dict: [String: Any]) -> [AbsoluteConfigKey: ConfigValue] {
    var result: [AbsoluteConfigKey: ConfigValue] = [:]

    for (key, value) in dict {
      // AbsoluteConfigKey initializer takes components array without label
      let configKey = AbsoluteConfigKey(key.split(separator: ".").map(String.init), context: [:])

      let configValue: ConfigValue
      switch value {
      case let stringValue as String:
        configValue = ConfigValue(.string(stringValue), isSecret: false)
      case let intValue as Int:
        configValue = ConfigValue(.int(intValue), isSecret: false)
      case let int64Value as Int64:
        // ConfigContent only supports Int, convert Int64 to Int
        configValue = ConfigValue(.int(Int(int64Value)), isSecret: false)
      case let doubleValue as Double:
        configValue = ConfigValue(.double(doubleValue), isSecret: false)
      case let boolValue as Bool:
        configValue = ConfigValue(.bool(boolValue), isSecret: false)
      case let dateValue as Date:
        // ConfigContent doesn't have a date type, convert to ISO8601 string
        let formatter = ISO8601DateFormatter()
        configValue = ConfigValue(.string(formatter.string(from: dateValue)), isSecret: false)
      default:
        // Skip unsupported types
        continue
      }

      result[configKey] = configValue
    }

    return result
  }

  /// Load complete configuration with all defaults applied
  public func loadConfiguration() async throws -> CelestraConfiguration {
    // CloudKit configuration
    let cloudkit = CloudKitConfiguration(
      containerID: readString(forKey: "cloudkit.container_id") ??
        readString(forKey: "CLOUDKIT_CONTAINER_ID"),
      keyID: readString(forKey: "cloudkit.key_id") ??
        readString(forKey: "CLOUDKIT_KEY_ID"),
      privateKeyPath: readString(forKey: "cloudkit.private_key_path") ??
        readString(forKey: "CLOUDKIT_PRIVATE_KEY_PATH"),
      environment: parseEnvironment(
        readString(forKey: "cloudkit.environment") ??
        readString(forKey: "CLOUDKIT_ENVIRONMENT")
      )
    )

    // Update command configuration
    let update = UpdateCommandConfiguration(
      delay: readDouble(forKey: "update.delay") ??
        readDouble(forKey: "UPDATE_DELAY") ?? 2.0,
      skipRobotsCheck: readBool(forKey: "update.skip_robots_check") ??
        readBool(forKey: "UPDATE_SKIP_ROBOTS_CHECK") ?? false,
      maxFailures: readInt64(forKey: "update.max_failures") ??
        readInt64(forKey: "UPDATE_MAX_FAILURES"),
      minPopularity: readInt64(forKey: "update.min_popularity") ??
        readInt64(forKey: "UPDATE_MIN_POPULARITY"),
      lastAttemptedBefore: parseDateString(
        readString(forKey: "update.last_attempted_before") ??
        readString(forKey: "UPDATE_LAST_ATTEMPTED_BEFORE")
      )
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

  private func parseDateString(_ value: String?) -> Date? {
    guard let value = value else { return nil }
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: value)
  }
}
