# Anonymous Feed Popularity Tracking in CloudKit

This document describes how to implement anonymous subscriber counting for feeds in Celestra using CloudKit's public database.

## Goals

- Track how many users are subscribed to each feed (popularity metric)
- Ensure each user counts only once per feed, regardless of how many devices they use
- Preserve user anonymity—no way to correlate subscriptions across feeds or identify users

## Approach: Hashed Subscription Records

Create a `FeedSubscription` record type in the public database. The record ID is a SHA256 hash of the user's record ID combined with the feed ID.

### Why This Works

- **Same user + same feed = same record ID** → prevents duplicates across devices
- **Hash includes feed ID** → can't correlate subscriptions across different feeds
- **One-way hash** → can't reverse to get the original user record ID

## Implementation

### Generate the Subscription Record ID

```swift
import CryptoKit
import CloudKit

func subscriptionRecordID(for feedRecordName: String) async throws -> CKRecord.ID {
    let userRecordID = try await CKContainer.default().userRecordID()

    // Combine feed + user so the hash is unique per feed
    let input = "\(feedRecordName)-\(userRecordID.recordName)"
    let hash = SHA256.hash(data: Data(input.utf8))
    let recordName = hash.compactMap { String(format: "%02x", $0) }.joined()

    return CKRecord.ID(recordName: recordName)
}
```

### Subscribe to a Feed

```swift
func subscribe(to feedRecordName: String) async throws {
    let recordID = try await subscriptionRecordID(for: feedRecordName)
    let record = CKRecord(recordType: "FeedSubscription", recordID: recordID)
    record["feedRecordName"] = feedRecordName

    try await CKContainer.default().publicCloudDatabase.save(record)
    // If already subscribed, this overwrites the same record (idempotent)
}
```

### Unsubscribe from a Feed

```swift
func unsubscribe(from feedRecordName: String) async throws {
    let recordID = try await subscriptionRecordID(for: feedRecordName)
    try await CKContainer.default().publicCloudDatabase.deleteRecord(withID: recordID)
}
```

### Count Subscribers for a Feed

```swift
func subscriberCount(for feedRecordName: String) async throws -> Int {
    let predicate = NSPredicate(format: "feedRecordName == %@", feedRecordName)
    let query = CKQuery(recordType: "FeedSubscription", predicate: predicate)

    let (results, _) = try await CKContainer.default().publicCloudDatabase
        .records(matching: query)

    return results.count
}
```

> **Note:** For feeds with many subscribers, consider caching the count on the `Feed` record and updating it periodically via a scheduled job rather than counting on every request.

## CloudKit Schema

### FeedSubscription Record Type

| Field           | Type   | Description                       |
|-----------------|--------|-----------------------------------|
| feedRecordName  | String | References Feed recordName        |

The record ID itself is the hashed user+feed identifier—no need to store it as a separate field.

### Indexes

- Add a queryable index on `feedRecordName` to support the count query

## Important Considerations

### iCloud Sign-In Required

`CKContainer.default().userRecordID()` throws if the user is not signed into iCloud. Handle this gracefully:

```swift
func subscribeIfPossible(to feedRecordName: String) async {
    do {
        try await subscribe(to: feedRecordName)
    } catch let error as CKError where error.code == .notAuthenticated {
        // User not signed into iCloud—skip popularity tracking
        // The subscription still works locally, just doesn't count toward popularity
    }
}
```

### What to Avoid

- **Don't use `identifierForVendor`** — This is device-specific, so users with multiple devices would count multiple times.
- **Don't expose `CKRecord.creatorUserRecordID`** — This is the unhashed user ID and would compromise anonymity.
- **Don't store the raw user record ID** — Always hash it before using in record IDs or fields.

## Optional: Aggregate Counts via Scheduled Job

For better performance with popular feeds:

1. Clients create/delete `FeedSubscription` records as described above
2. A scheduled job (e.g., GitHub Action) periodically queries and counts subscriptions
3. The job updates a `subscriberCount` field on each `Feed` record
4. Clients read the cached count from the `Feed` record

This provides eventual consistency without requiring clients to count on every request.
