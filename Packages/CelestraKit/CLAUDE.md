# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CelestraKit is a shared Swift package that provides CloudKit models and utilities for the Celestra RSS reader ecosystem. It contains shared data models for CloudKit's public database, designed to work across:
- **CelestraApp**: iOS client application
- **CelestraCloud**: Server-side CLI tool for feed processing

The package is designed for cross-platform compatibility, with CloudKit-specific code available on Apple platforms and platform-agnostic DTOs for Linux/server environments.

## Build & Test Commands

### Building
```bash
swift build
```

### Testing
```bash
# Run all tests
swift test

# Run specific test
swift test --filter CelestraKitTests.testVersion
```

### Package Management
```bash
# Update dependencies
swift package update

# Resolve dependencies
swift package resolve

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

## Architecture

### Package Structure
- **Sources/CelestraKit/**: Main library code
  - **Models/PublicDatabase/**: CloudKit public database models
    - `Feed.swift`: RSS feed metadata and server-side metrics
    - `Article.swift`: RSS article content with caching and deduplication
  - **Services/**: Reusable web etiquette services
    - `RateLimiter.swift`: Per-domain and global rate limiting
    - `RobotsTxtService.swift`: robots.txt parsing and caching

### Key Dependencies
- **SyndiKit** (v0.6.1): RSS/Atom feed parsing

### Swift Language Configuration

This project uses **Swift 6.2** with strict concurrency checking and many experimental features enabled:

**Upcoming Features Enabled:**
- `ExistentialAny` (SE-0335)
- `InternalImportsByDefault` (SE-0409)
- `MemberImportVisibility` (SE-0444)
- `FullTypedThrows` (SE-0413)

**Experimental Features Enabled:**
- `BitwiseCopyable`, `BorrowingSwitch`, `ExtensionMacros`, `FreestandingExpressionMacros`
- `InitAccessors`, `IsolatedAny`, `MoveOnlyClasses`, `MoveOnlyEnumDeinits`
- `MoveOnlyPartialConsumption`, `MoveOnlyResilientTypes`, `MoveOnlyTuples`
- `NoncopyableGenerics` (SE-0427), `OneWayClosureParameters`
- `RawLayout`, `ReferenceBindings`
- `SendingArgsAndResults` (SE-0430), `TransferringArgsAndResults`
- `SymbolLinkageMarkers`, `VariadicGenerics` (SE-0393)
- `WarnUnsafeReflection`

**Compiler Flags:**
- `-warn-concurrency`: Enable concurrency warnings
- `-enable-actor-data-race-checks`: Enable actor data race checks
- `-strict-concurrency=complete`: Complete strict concurrency checking
- `-enable-testing`: Enable testing support
- `-warn-long-function-bodies=100`: Warn about functions >100 lines
- `-warn-long-expression-type-checking=100`: Warn about slow type checking

**All new code must:**
- Use `Sendable` for types that cross concurrency boundaries
- Use `public import` instead of `import` for re-exported dependencies
- Follow strict concurrency checking (no implicit Sendable conformances)
- Avoid long functions (>100 lines) and complex type checking expressions

### Data Models

#### Feed (CloudKit Public Database)
Represents RSS feeds shared across all users. Key features:
- **Unique identifier**: `feedURL`
- **CloudKit fields**: `recordName`, `recordChangeTag` for optimistic locking
- **Metadata**: title, description, category, image, language, tags
- **Server metrics**: fetch attempts, success rate, failure tracking, HTTP caching headers (ETag, Last-Modified)
- **Quality indicators**: `qualityScore` (0-100), `isVerified`, `isFeatured`
- **Computed properties**: `successRate`, `isHealthy`

#### Article (CloudKit Public Database)
Represents RSS articles in the public content cache. Key features:
- **Unique identifier**: Combination of `feedRecordName` + `guid`
- **Content**: title, excerpt, content (HTML), contentText (plain), author, URL, image
- **Metadata**: publishedDate, language, tags, wordCount, estimatedReadingTime
- **Caching**: `fetchedAt`, `expiresAt` (TTL-based), `contentHash` (composite key deduplication)
- **Computed properties**: `isExpired` for cache invalidation
- **Static helpers**:
  - `calculateContentHash()`: Composite key of title|URL|guid for deduplication
  - `extractPlainText()`: Basic HTML tag removal (use proper parser in production)
  - `calculateWordCount()`: Word count for reading time estimation
  - `estimateReadingTime()`: Assumes 200 words/minute

### Platform Support
- iOS 26.0+
- macOS 26.0+
- visionOS 26.0+
- watchOS 26.0+
- tvOS 26.0+
- macCatalyst 26.0+

### Design Patterns

**CloudKit Integration:**
- Models store `recordName` and `recordChangeTag` for CloudKit optimistic locking
- All models are `Sendable`, `Codable`, `Hashable`, and `Identifiable`
- Designed for both CloudKit record mapping (Apple platforms) and JSON DTOs (Linux/server)

**Caching Strategy:**
- Articles use TTL-based expiration (`expiresAt`)
- Content deduplication via composite key (title|URL|guid)
- Server-side metrics track feed health and update frequency

**Concurrency:**
- All public types are `Sendable` for safe concurrent access
- Strict concurrency checking enforced via compiler flags

## Development Workflow

### Branching
- Main branch: `main`
- Development happens on feature branches
- Current work is on `v0.0.1` branch

### Related Projects
This package is part of the Celestra ecosystem:
- **CelestraKit** (this package): Shared CloudKit models
- **Celestra**: Main iOS application (at `../Celestra`)
- **SyndiKit**: RSS/Atom parsing library (at `../Syndikit`)
- **MistKit**: Related package (at `../MistKit`)

### Recent Development
Recent commits show focus on:
- Phase 2 modularization with MistKit integration
- CloudKit public database integration
- Background parsing queue with resilience patterns
- Feed discovery and auto-detection services
