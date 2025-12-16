# CelestraKit

[![SwiftPM](https://img.shields.io/badge/SPM-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS-success?logo=swift)](https://swift.org)
[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange?logo=swift)](https://swift.org)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/github/license/brightdigit/CelestraKit)](LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/brightdigit/CelestraKit/CelestraKit.yml?label=actions&logo=github&?branch=main)](https://github.com/brightdigit/CelestraKit/actions)
[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/CelestraKit)](https://codecov.io/gh/brightdigit/CelestraKit)

**Shared CloudKit models and utilities for the Celestra RSS reader ecosystem**

## Table of Contents

- [Overview](#overview)
  - [Key Features](#key-features)
- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Requirements](#requirements)
  - [Platform Support](#platform-support)
- [Usage](#usage)
  - [Quick Start](#quick-start)
  - [Feed Model](#feed-model)
  - [Article Model](#article-model)
- [Architecture](#architecture)
- [Documentation](#documentation)
- [License](#license)

## Overview

CelestraKit is a Swift package that provides shared CloudKit data models for the Celestra RSS reader ecosystem. It defines the public database schema used by both the iOS application and server-side feed processing tools, enabling seamless data synchronization and sharing across the Celestra platform.

### Key Features

- **📱 CloudKit Public Database Models**: Shared data structures for feeds and articles
- **🔄 Cross-Platform Compatibility**: Works on all Apple platforms with CloudKit support
- **🔐 Server-Side Metrics**: Track feed health, success rates, and fetch statistics
- **🔍 Content Deduplication**: SHA-256 hashing for intelligent article deduplication
- **⏱️ TTL-Based Caching**: Automatic expiration tracking for article freshness
- **📊 Quality Indicators**: Feed quality scoring and health monitoring
- **🧮 Reading Time Estimation**: Automatic word count and reading time calculation
- **⚡ Modern Swift**: Built with Swift 6.2, strict concurrency, and modern language features
- **🧪 Comprehensive Testing**: 67+ test cases covering all models and edge cases

## Getting Started

### Installation

#### Swift Package Manager

Add CelestraKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/brightdigit/CelestraKit.git", from: "0.0.1")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/brightdigit/CelestraKit.git`
3. Select version and add to your target

### Requirements

- **Swift**: 6.2+
- **Xcode**: 16.3+ (for iOS/macOS development)
- **CloudKit**: All models designed for CloudKit public database

### Platform Support

| Platform | Minimum Version |
|----------|----------------|
| iOS | 26.0+ |
| macOS | 26.0+ |
| watchOS | 26.0+ |
| tvOS | 26.0+ |
| visionOS | 26.0+ |
| macCatalyst | 26.0+ |

> **Note**: Platform versions are set to 26.0+ to ensure full CloudKit compatibility and modern platform features.

## Usage

### Quick Start

```swift
import CelestraKit

// Create a feed in the public database
let feed = Feed(
    recordName: "feed-example",
    feedURL: "https://example.com/feed.xml",
    title: "Example RSS Feed",
    description: "A sample RSS feed",
    category: "Technology",
    language: "en"
)

// Access computed properties
print("Feed health: \(feed.isHealthy ? "✓" : "✗")")
print("Success rate: \(feed.successRate * 100)%")

// Create an article linked to the feed
let article = Article(
    feedRecordName: feed.recordName ?? feed.feedURL,
    guid: "article-123",
    title: "Example Article",
    excerpt: "This is a sample article",
    content: "<p>Full article content here</p>",
    author: "John Doe",
    url: "https://example.com/article",
    publishedDate: Date()
)

// Check article status
if article.isExpired {
    print("Article has expired and should be refreshed")
}

print("Reading time: \(article.estimatedReadingTime ?? 0) minutes")
```

### Feed Model

The `Feed` model represents RSS feeds in CloudKit's public database:

```swift
let feed = Feed(
    recordName: "unique-feed-id",
    feedURL: "https://example.com/feed.xml",
    title: "Tech Blog",
    description: "Latest technology news",
    category: "Technology",
    imageURL: "https://example.com/image.png",
    language: "en",
    tags: ["tech", "programming"],
    qualityScore: 85,
    isVerified: true,
    isFeatured: false
)

// Server-side metrics (updated by feed processor)
feed.lastFetchedAt = Date()
feed.fetchAttempts = 100
feed.successfulFetches = 95
feed.failureCount = 5

// Check feed health
if feed.isHealthy {
    print("✓ Feed is healthy (quality: \(feed.qualityScore), success rate: \(feed.successRate))")
}
```

**Key Properties:**
- `feedURL`: Unique feed identifier
- `qualityScore`: 0-100 quality indicator
- `successRate`: Computed from fetch statistics
- `isHealthy`: Health status based on quality and reliability

### Article Model

The `Article` model represents cached RSS articles:

```swift
let article = Article(
    feedRecordName: "feed-id",
    guid: "article-guid",
    title: "Article Title",
    excerpt: "Brief summary",
    content: "<p>Full HTML content</p>",
    author: "Author Name",
    url: "https://example.com/article",
    publishedDate: Date(),
    imageURL: "https://example.com/image.jpg",
    language: "en",
    tags: ["swift", "ios"],
    ttlDays: 30  // Cache for 30 days
)

// Automatic content processing
print("Word count: \(article.wordCount ?? 0)")
print("Plain text: \(article.contentText ?? "")")
print("Content hash: \(article.contentHash)")  // SHA-256 for deduplication

// Check if article needs refresh
if article.isExpired {
    // Re-fetch article from source
}
```

**Key Features:**
- **Content Hash**: SHA-256 hash of title + URL + guid for deduplication
- **Plain Text Extraction**: Automatic HTML → plain text conversion
- **Reading Time**: Estimated based on 200 words per minute
- **TTL Management**: Automatic expiration tracking
- **Duplicate Detection**: Compare `contentHash` across articles

## Architecture

### Data Model Design

CelestraKit uses CloudKit's public database for content sharing:

```
┌─────────────────────┐
│   CloudKit Public   │
│      Database       │
└─────────────────────┘
          │
    ┌─────┴─────┐
    │           │
┌───▼────┐  ┌──▼──────┐
│  Feed  │  │ Article │
└────────┘  └─────────┘
```

**Feed → Article Relationship:**
- Articles reference feeds via `feedRecordName`
- One feed can have multiple articles
- Articles use `guid` for uniqueness within a feed

### Concurrency

All models are `Sendable` and designed for Swift 6 strict concurrency:

```swift
// Safe to use across actor boundaries
actor FeedProcessor {
    func process(_ feed: Feed) async {
        // Feed is Sendable - safe to pass to actors
    }
}
```

### Caching Strategy

Articles use TTL-based expiration:

```swift
// Default: 30 days
let article = Article(..., ttlDays: 30)

// Expiration calculated from fetchedAt + TTL
if article.isExpired {
    // Time to refresh
}
```

## Documentation

- **API Documentation**: [View on Swift Package Index](https://swiftpackageindex.com/brightdigit/CelestraKit/documentation)
- **PRD**: See [.claude/PRD.md](.claude/PRD.md) for development roadmap
- **Development Guide**: See [CLAUDE.md](CLAUDE.md) for AI-assisted development

## License

CelestraKit is available under the MIT license. See [LICENSE](LICENSE) for details.

---

**Part of the Celestra Ecosystem:**
- **CelestraKit** (this package): Shared CloudKit models
- **CelestraApp**: iOS RSS reader application
- **CelestraCloud**: Server-side feed processing

Built with ❤️ by [BrightDigit](https://github.com/brightdigit)
