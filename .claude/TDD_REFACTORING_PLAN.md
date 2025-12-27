# Fix SwiftLint Issues and Add Unit Tests

## Overview
Fix all strict mode SwiftLint violations using TDD principles. Create testable types with dependency injection via initializers.

---

## Phase 1: Source File Refactoring (TDD Approach)

### 1.1 Create Testable Service Types from `CloudKitService+Celestra.swift`

**Current file:** `Sources/CelestraCloudKit/Services/CloudKitService+Celestra.swift` (360 lines)

Instead of just splitting extensions, create **new testable service types** with protocol-based dependencies:

#### New Protocol: `CloudKitRecordOperating`
```swift
// Sources/CelestraCloudKit/Protocols/CloudKitRecordOperating.swift
public protocol CloudKitRecordOperating: Sendable {
  func queryRecords(recordType: String, filters: [QueryFilter]?, sortBy: [QuerySort]?, limit: Int, desiredKeys: [String]?) async throws -> [RecordInfo]
  func modifyRecords(_ operations: [RecordOperation]) async throws -> [RecordInfo]
}

extension CloudKitService: CloudKitRecordOperating {}
```

#### New Type: `FeedCloudKitService`
```swift
// Sources/CelestraCloudKit/Services/FeedCloudKitService.swift (~100 lines)
public struct FeedCloudKitService: Sendable {
  private let recordOperator: any CloudKitRecordOperating

  public init(recordOperator: any CloudKitRecordOperating) {
    self.recordOperator = recordOperator
  }

  public func createFeed(_ feed: Feed) async throws -> RecordInfo { ... }
  public func updateFeed(recordName: String, feed: Feed) async throws -> RecordInfo { ... }
  public func queryFeeds(lastAttemptedBefore: Date?, minPopularity: Int?, limit: Int) async throws -> [Feed] { ... }
  public func deleteAllFeeds() async throws { ... }
}
```

#### New Type: `ArticleCloudKitService`
```swift
// Sources/CelestraCloudKit/Services/ArticleCloudKitService.swift (~180 lines)
public struct ArticleCloudKitService: Sendable {
  private let recordOperator: any CloudKitRecordOperating

  public init(recordOperator: any CloudKitRecordOperating) {
    self.recordOperator = recordOperator
  }

  public func queryArticlesByGUIDs(_ guids: [String], feedRecordName: String?) async throws -> [Article] { ... }
  public func createArticles(_ articles: [Article]) async throws -> BatchOperationResult { ... }
  public func updateArticles(_ articles: [Article]) async throws -> BatchOperationResult { ... }
  public func deleteAllArticles() async throws { ... }
}
```

#### Convenience Extension (Thin Wrapper)
```swift
// Sources/CelestraCloudKit/Services/CloudKitService+Celestra.swift (~40 lines)
// Keep as thin facade delegating to new service types
extension CloudKitService {
  public var feeds: FeedCloudKitService { FeedCloudKitService(recordOperator: self) }
  public var articles: ArticleCloudKitService { ArticleCloudKitService(recordOperator: self) }
}
```

**TDD Benefits:**
- `FeedCloudKitService` and `ArticleCloudKitService` can be tested with mock `CloudKitRecordOperating`
- No need for real CloudKit connection in tests

---

### 1.2 Refactor `FeedUpdateProcessor.swift` with Testable Types

**Current file:** `Sources/CelestraCloud/Services/FeedUpdateProcessor.swift` (248 lines)

Create testable value types for the complex logic:

#### New Type: `ArticleCategorizer`
```swift
// Sources/CelestraCloud/Services/ArticleCategorizer.swift (~50 lines)
internal struct ArticleCategorizer {
  internal struct Result {
    let new: [Article]
    let modified: [Article]
  }

  internal init() {}

  internal func categorize(
    items: [FeedItem],
    existingArticles: [Article],
    feedRecordName: String
  ) -> Result {
    // Pure function - easy to test
  }
}
```

#### New Type: `FeedMetadataBuilder`
```swift
// Sources/CelestraCloud/Services/FeedMetadataBuilder.swift (~60 lines)
internal struct FeedMetadataBuilder {
  internal init() {}

  internal func buildSuccessMetadata(
    feedData: FeedData,
    response: RSSFetchResponse,
    feed: Feed,
    totalAttempts: Int64
  ) -> FeedMetadataUpdate { ... }

  internal func buildNotModifiedMetadata(
    feed: Feed,
    response: RSSFetchResponse,
    totalAttempts: Int64
  ) -> FeedMetadataUpdate { ... }

  internal func buildErrorMetadata(
    feed: Feed,
    totalAttempts: Int64
  ) -> FeedMetadataUpdate { ... }
}
```

#### Separate Files for Existing Types
```swift
// Sources/CelestraCloud/Services/FeedUpdateResult.swift (~15 lines)
internal enum FeedUpdateResult { case success, notModified, skipped, error }

// Sources/CelestraCloud/Services/FeedMetadataUpdate.swift (~25 lines)
internal struct FeedMetadataUpdate { ... }
```

#### Refactored `FeedUpdateProcessor.swift` (~120 lines)
```swift
internal struct FeedUpdateProcessor {
  private let service: CloudKitService
  private let fetcher: RSSFetcherService
  private let robotsService: RobotsTxtService
  private let rateLimiter: RateLimiter
  private let skipRobotsCheck: Bool
  private let categorizer: ArticleCategorizer
  private let metadataBuilder: FeedMetadataBuilder

  internal init(
    service: CloudKitService,
    fetcher: RSSFetcherService,
    robotsService: RobotsTxtService,
    rateLimiter: RateLimiter,
    skipRobotsCheck: Bool,
    categorizer: ArticleCategorizer = ArticleCategorizer(),
    metadataBuilder: FeedMetadataBuilder = FeedMetadataBuilder()
  ) { ... }

  // fetchAndProcess now delegates to injected types - under 50 lines
}
```

**TDD Benefits:**
- `ArticleCategorizer` is a pure function - test all edge cases without mocking
- `FeedMetadataBuilder` is a pure function - test metadata construction in isolation
- `FeedUpdateProcessor` can be tested with mock dependencies

---

### 1.3 Split `UpdateCommand.swift`

**Current file:** `Sources/CelestraCloud/Commands/UpdateCommand.swift`

| New File | Content |
|----------|---------|
| `UpdateSummary.swift` | `UpdateSummary` struct (change `private` to `internal`) |

---

## Phase 2: Simple Fixes

| File | Line | Fix |
|------|------|-----|
| `Celestra.swift` | 30 | Remove unused `import CelestraCloudKit` |

---

## Phase 3: Test File Restructuring

### 3.1 Rename `Article+MistKitTests.swift`

**Current:** `Tests/CelestraCloudTests/Extensions/Article+MistKitTests.swift`
**New:** `Tests/CelestraCloudTests/Extensions/ArticleMistKitTests.swift`

Fixes:
- Add `internal` keyword to struct and all 6 test methods
- Line 199: Change `tags == []` to `tags.isEmpty`

### 3.2 Split `Feed+MistKitTests.swift` (402 lines)

**Current:** `Tests/CelestraCloudTests/Extensions/Feed+MistKitTests.swift`

Split into 2 files:

| New File | Tests | ~Lines |
|----------|-------|--------|
| `FeedMistKitTests.swift` | `testToFieldsDictRequiredFields`, `testToFieldsDictOptionalFields`, `testToFieldsDictOmitsNilFields`, `testInitFromRecordMissingFields`, `testBooleanFieldConversion` | ~200 |
| `FeedMistKitRoundTripTests.swift` | `testInitFromRecordAllFields`, `testRoundTripConversion` + helper methods | ~180 |

**All test files:**
- Add `internal` keyword to structs and all test methods
- Fix `tags == []` to `tags.isEmpty`
- Refactor long functions (>50 lines) by extracting helper methods

---

## Phase 4: New Unit Tests (TDD - Write Tests First)

### 4.1 Tests for New CloudKit Service Types

| Test File | Tests For |
|-----------|-----------|
| `Tests/CelestraCloudTests/Services/FeedCloudKitServiceTests.swift` | `FeedCloudKitService` with mock `CloudKitRecordOperating` |
| `Tests/CelestraCloudTests/Services/ArticleCloudKitServiceTests.swift` | `ArticleCloudKitService` with mock `CloudKitRecordOperating` |
| `Tests/CelestraCloudTests/Mocks/MockCloudKitRecordOperator.swift` | Mock implementation for testing |

### 4.2 Tests for FeedUpdateProcessor Extracted Types

| Test File | Tests For |
|-----------|-----------|
| `Tests/CelestraCloudTests/Services/ArticleCategorizerTests.swift` | Pure function testing (no mocks needed) |
| `Tests/CelestraCloudTests/Services/FeedMetadataBuilderTests.swift` | Pure function testing (no mocks needed) |

### 4.3 Other Tests

| Test File | Tests For |
|-----------|-----------|
| `Tests/CelestraCloudTests/Errors/CloudKitConversionErrorTests.swift` | Error descriptions |

---

## Implementation Order (TDD)

### Step 1: Write Tests First
1. Create `MockCloudKitRecordOperator` for dependency injection
2. Write `FeedCloudKitServiceTests` (test cases for all methods)
3. Write `ArticleCloudKitServiceTests` (test cases for all methods)
4. Write `ArticleCategorizerTests` (pure function - no mocks)
5. Write `FeedMetadataBuilderTests` (pure function - no mocks)

### Step 2: Implement New Types
6. Create `CloudKitRecordOperating` protocol
7. Implement `FeedCloudKitService` to pass tests
8. Implement `ArticleCloudKitService` to pass tests
9. Implement `ArticleCategorizer` to pass tests
10. Implement `FeedMetadataBuilder` to pass tests

### Step 3: Refactor Existing Code
11. Refactor `CloudKitService+Celestra.swift` to use new service types
12. Refactor `FeedUpdateProcessor.swift` to use injected types
13. Extract `FeedUpdateResult.swift` and `FeedMetadataUpdate.swift`
14. Extract `UpdateSummary.swift`

### Step 4: Fix Remaining Issues
15. Fix simple lint issues (unused import)
16. Rename/split test files (ArticleMistKitTests, FeedMistKitTests)
17. Add `internal` ACL to all test declarations
18. Run `LINT_MODE=STRICT ./Scripts/lint.sh` to verify

---

## Files Summary

### Create - New Source Files (8 files)
- `Sources/CelestraCloudKit/Protocols/CloudKitRecordOperating.swift`
- `Sources/CelestraCloudKit/Services/FeedCloudKitService.swift`
- `Sources/CelestraCloudKit/Services/ArticleCloudKitService.swift`
- `Sources/CelestraCloud/Services/ArticleCategorizer.swift`
- `Sources/CelestraCloud/Services/FeedMetadataBuilder.swift`
- `Sources/CelestraCloud/Services/FeedUpdateResult.swift`
- `Sources/CelestraCloud/Services/FeedMetadataUpdate.swift`
- `Sources/CelestraCloud/Commands/UpdateSummary.swift`

### Create - New Test Files (9 files)
- `Tests/CelestraCloudTests/Mocks/MockCloudKitRecordOperator.swift`
- `Tests/CelestraCloudTests/Services/FeedCloudKitServiceTests.swift`
- `Tests/CelestraCloudTests/Services/ArticleCloudKitServiceTests.swift`
- `Tests/CelestraCloudTests/Services/ArticleCategorizerTests.swift`
- `Tests/CelestraCloudTests/Services/FeedMetadataBuilderTests.swift`
- `Tests/CelestraCloudTests/Extensions/ArticleMistKitTests.swift` (renamed)
- `Tests/CelestraCloudTests/Extensions/FeedMistKitTests.swift` (split)
- `Tests/CelestraCloudTests/Extensions/FeedMistKitRoundTripTests.swift` (split)
- `Tests/CelestraCloudTests/Errors/CloudKitConversionErrorTests.swift`

### Delete (3 files)
- `Tests/CelestraCloudTests/Extensions/Article+MistKitTests.swift`
- `Tests/CelestraCloudTests/Extensions/Feed+MistKitTests.swift`

### Modify (3 files)
- `Sources/CelestraCloudKit/Services/CloudKitService+Celestra.swift` - thin facade
- `Sources/CelestraCloud/Services/FeedUpdateProcessor.swift` - use injected types
- `Sources/CelestraCloud/Commands/UpdateCommand.swift` - remove UpdateSummary
- `Sources/CelestraCloud/Celestra.swift` - remove unused import
