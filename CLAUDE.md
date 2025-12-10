# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Celestra is a command-line RSS reader that demonstrates MistKit's CloudKit integration capabilities. It fetches RSS feeds, stores them in CloudKit's public database, and implements comprehensive web etiquette best practices including rate limiting, robots.txt checking, and conditional HTTP requests.

**Tech Stack**: Swift 6.2, MistKit (CloudKit wrapper), SyndiKit (RSS parsing), ArgumentParser (CLI)

## Common Commands

### Build and Run

```bash
# Build the project
swift build

# Run with environment variables
source .env
swift run celestra <command>

# Add a feed
swift run celestra add-feed https://example.com/feed.xml

# Update feeds with filters
swift run celestra update
swift run celestra update --last-attempted-before 2025-01-01T00:00:00Z
swift run celestra update --min-popularity 10 --delay 3.0

# Clear all data
swift run celestra clear --confirm
```

### Environment Setup

Required environment variables (see `.env.example`):
- `CLOUDKIT_CONTAINER_ID` - CloudKit container identifier
- `CLOUDKIT_KEY_ID` - Server-to-Server key ID from Apple Developer Console
- `CLOUDKIT_PRIVATE_KEY_PATH` - Path to `.pem` private key file
- `CLOUDKIT_ENVIRONMENT` - Either `development` or `production`

### CloudKit Schema Management

```bash
# Automated schema deployment (requires cktool)
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Celestra"
export CLOUDKIT_TEAM_ID="YOUR_TEAM_ID"
export CLOUDKIT_ENVIRONMENT="development"
./Scripts/setup-cloudkit-schema.sh
```

Schema is defined in `schema.ckdb` using CloudKit's text-based schema language.

## Architecture

### High-Level Structure

```
Sources/Celestra/
├── Celestra.swift              # CLI entry point with ArgumentParser
├── CelestraConfig.swift        # CloudKit service factory
├── Commands/                   # CLI subcommands
│   ├── AddFeedCommand.swift    # Parse and add RSS feeds
│   ├── UpdateCommand.swift     # Fetch/update feeds (shows MistKit QueryFilter)
│   └── ClearCommand.swift      # Delete all records
├── Services/
│   ├── CloudKitService+Celestra.swift  # MistKit operations
│   ├── RSSFetcherService.swift         # SyndiKit wrapper
│   ├── RobotsTxtService.swift          # Robots.txt parser
│   ├── RateLimiter.swift               # Per-domain rate limiting
│   └── CelestraLogger.swift            # Structured logging
├── Models/
│   └── BatchOperationResult.swift      # Batch operation tracking
└── Extensions/
    ├── Feed+MistKit.swift      # Feed ↔ CloudKit conversion
    └── Article+MistKit.swift   # Article ↔ CloudKit conversion
```

**Shared Models**: The `Feed` and `Article` models live in `../CelestraKit` package (peer dependency) for potential reuse across CLI and other clients.

### Key Architectural Patterns

**1. MistKit Integration**

CloudKitService is configured in `CelestraConfig.createCloudKitService()`:
- Server-to-Server authentication using PEM keys
- Public database access for shared feeds
- Environment-based configuration (dev/prod)

All CloudKit operations are in `CloudKitService+Celestra.swift` extension:
- `queryFeeds()` - Demonstrates QueryFilter and QuerySort APIs
- `createArticles()` / `updateArticles()` - Batch operations with chunking
- `queryArticlesByGUIDs()` - Duplicate detection queries

**2. Field Mapping Pattern**

Models use direct field mapping (not protocol-based) for simplicity:

```swift
// To CloudKit
func toFieldsDict() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
        "title": .string(title),
        "isActive": .int64(isActive ? 1 : 0)  // Booleans as INT64
    ]
    // Optional fields only added if present
    if let description = description {
        fields["description"] = .string(description)
    }
    return fields
}

// From CloudKit
init(from record: RecordInfo) {
    if case .string(let value) = record.fields["title"] {
        self.title = value
    }
    // Boolean extraction
    if case .int64(let value) = record.fields["isActive"] {
        self.isActive = value != 0
    } else {
        self.isActive = true  // Default
    }
}
```

**3. Duplicate Detection Strategy**

UpdateCommand implements GUID-based duplicate detection:
1. Extract GUIDs from fetched articles
2. Query CloudKit for existing articles with those GUIDs (`queryArticlesByGUIDs`)
3. Separate into new vs modified articles (using `contentHash` comparison)
4. Create new articles, update modified ones, skip unchanged

This minimizes CloudKit writes and prevents duplicate content.

**4. Batch Operations**

Articles are processed in batches of 10 (conservative to keep payload size manageable with full content):
- Non-atomic operations allow partial success
- Each batch tracked in `BatchOperationResult`
- Provides success rate, failure count, and detailed error tracking
- See `createArticles()` / `updateArticles()` in CloudKitService+Celestra.swift

**5. Web Etiquette Implementation**

Celestra is a respectful RSS client:
- **Rate Limiting** (RateLimiter): Configurable delays between feeds (default 2s), per-domain tracking
- **Robots.txt** (RobotsTxtService): Parses and respects robots.txt rules
- **Conditional Requests**: Uses If-Modified-Since/ETag headers, handles 304 Not Modified
- **Failure Tracking**: Tracks consecutive failures per feed, can filter by max failures
- **Update Intervals**: Respects feed's `minUpdateInterval` to avoid over-fetching
- **User-Agent**: Identifies as "Celestra/1.0 (MistKit RSS Reader; +https://github.com/brightdigit/MistKit)"

All web etiquette features are demonstrated in UpdateCommand.swift.

## CloudKit Schema

Two record types in public database:

**Feed**: RSS feed metadata
- Key fields: `feedURL` (QUERYABLE SORTABLE), `title` (SEARCHABLE)
- Metrics: `totalAttempts`, `successfulAttempts`, `subscriberCount`
- Web etiquette: `etag`, `lastModified`, `failureCount`, `minUpdateInterval`
- Booleans stored as INT64: `isActive`, `isFeatured`, `isVerified`

**Article**: RSS article content
- Key fields: `guid` (QUERYABLE SORTABLE), `feedRecordName` (STRING)
- Content: `title`, `excerpt`, `content`, `contentText` (all SEARCHABLE)
- Deduplication: `contentHash` (SHA256), `guid`
- TTL: `expiresAt` (QUERYABLE SORTABLE) for cleanup

**Relationship Design**: Uses string-based `feedRecordName` instead of CKReference for simplicity and clearer querying patterns. Trade-off: Manual cascade delete vs automatic with CKReference.

## Swift 6.2 Features

Package.swift enables extensive Swift 6.2 upcoming and experimental features:
- Strict concurrency checking (`-strict-concurrency=complete`)
- Existential `any` keyword
- Typed throws
- Noncopyable generics
- Move-only types
- Variadic generics

Code must be concurrency-safe with proper actor isolation.

## Development Guidelines

**When Adding Features:**
- MistKit operations go in `CloudKitService+Celestra.swift` extension
- New commands inherit from `AsyncParsableCommand` in Commands/ directory
- All CloudKit field types: Use FieldValue enum (.string, .int64, .date, .double, etc.)
- Booleans: Always store as INT64 (0/1) in CloudKit schema
- Batch operations: Chunk into batches of 10 for large payloads, use non-atomic for partial success
- Logging: Use CelestraLogger categories (cloudkit, rss, operations, errors)

**Testing CloudKit Operations:**
- Use development environment first
- Schema changes require redeployment via `./Scripts/setup-cloudkit-schema.sh`
- Clear data with `celestra clear --confirm` between tests

**Key Documentation:**
- `IMPLEMENTATION_NOTES.md` - Design decisions, patterns, and comparisons with Bushel example
- `BUSHEL_PATTERNS.md` - Protocol-oriented CloudKit patterns (alternative to direct mapping)
- `AI_SCHEMA_WORKFLOW.md` - CloudKit schema design guide for AI agents
- `CLOUDKIT_SCHEMA_SETUP.md` - Schema deployment instructions

## Important Patterns

**QueryFilter Examples** (see CloudKitService+Celestra.swift:44-68):
```swift
var filters: [QueryFilter] = []
filters.append(.lessThan("lastAttempted", .date(cutoffDate)))
filters.append(.greaterThanOrEquals("subscriberCount", .int64(minPopularity)))

let records = try await queryRecords(
    recordType: "Feed",
    filters: filters.isEmpty ? nil : filters,
    sortBy: [.ascending("feedURL")],
    limit: limit
)
```

**Duplicate Detection** (see UpdateCommand.swift:192-236):
```swift
let guids = articles.map { $0.guid }
let existingArticles = try await service.queryArticlesByGUIDs(guids, feedRecordName: recordName)
let existingMap = Dictionary(uniqueKeysWithValues: existingArticles.map { ($0.guid, $0) })

for article in articles {
    if let existing = existingMap[article.guid] {
        if existing.contentHash != article.contentHash {
            modifiedArticles.append(article.withRecordName(existing.recordName))
        }
    } else {
        newArticles.append(article)
    }
}
```

**Server-to-Server Auth** (see CelestraConfig.swift):
```swift
let privateKeyPEM = try String(contentsOfFile: privateKeyPath, encoding: .utf8)
let tokenManager = try ServerToServerAuthManager(keyID: keyID, pemString: privateKeyPEM)
let service = try CloudKitService(
    containerIdentifier: containerID,
    tokenManager: tokenManager,
    environment: environment,
    database: .public
)
```
