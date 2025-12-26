//
//  ConfigurationKeys.swift
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

/// Configuration keys for reading from providers
internal enum ConfigurationKeys {
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
