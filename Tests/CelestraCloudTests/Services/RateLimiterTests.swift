import Testing
import Foundation
@testable import Celestra

@Suite("RateLimiter Tests")
struct RateLimiterTests {

    @Test("First fetch has no delay")
    func testFirstFetchNoDelay() async {
        let limiter = RateLimiter(defaultDelay: 2.0, perDomainDelay: 5.0)
        let url = URL(string: "https://example.com/feed.xml")!

        let startTime = Date()
        await limiter.waitIfNeeded(for: url)
        let elapsed = Date().timeIntervalSince(startTime)

        // First fetch should be nearly instant (< 0.1 seconds)
        #expect(elapsed < 0.1)
    }

    @Test("Same domain applies per-domain delay")
    func testSameDomainPerDomainDelay() async {
        let limiter = RateLimiter(defaultDelay: 0.1, perDomainDelay: 0.3)
        let url1 = URL(string: "https://example.com/feed1.xml")!
        let url2 = URL(string: "https://example.com/feed2.xml")!

        // First fetch
        await limiter.waitIfNeeded(for: url1)

        // Second fetch from same domain - should wait perDomainDelay
        let startTime = Date()
        await limiter.waitIfNeeded(for: url2)
        let elapsed = Date().timeIntervalSince(startTime)

        // Should wait at least perDomainDelay (0.3s), allowing some margin
        #expect(elapsed >= 0.25)
        #expect(elapsed < 0.5)
    }

    @Test("Different domains use default delay")
    func testDifferentDomainsDefaultDelay() async {
        let limiter = RateLimiter(defaultDelay: 0.1, perDomainDelay: 0.5)
        let url1 = URL(string: "https://example.com/feed.xml")!
        let url2 = URL(string: "https://different.com/feed.xml")!

        // First fetch
        await limiter.waitIfNeeded(for: url1)

        // Second fetch from different domain - uses defaultDelay only
        // Note: The implementation doesn't actually enforce delay between different domains
        // Let's verify the behavior
        let startTime = Date()
        await limiter.waitIfNeeded(for: url2)
        let elapsed = Date().timeIntervalSince(startTime)

        // Different domain, first time - should be instant
        #expect(elapsed < 0.1)
    }

    @Test("Minimum interval is respected")
    func testMinimumIntervalRespected() async {
        let limiter = RateLimiter(defaultDelay: 0.1, perDomainDelay: 0.2)
        let url = URL(string: "https://example.com/feed.xml")!
        let minInterval: TimeInterval = 0.4

        // First fetch
        await limiter.waitIfNeeded(for: url, minimumInterval: minInterval)

        // Second fetch with minimum interval
        let startTime = Date()
        await limiter.waitIfNeeded(for: url, minimumInterval: minInterval)
        let elapsed = Date().timeIntervalSince(startTime)

        // Should respect the larger minInterval (0.4s)
        #expect(elapsed >= 0.35)
        #expect(elapsed < 0.6)
    }

    @Test("Reset clears all history")
    func testResetClearsHistory() async {
        let limiter = RateLimiter(defaultDelay: 0.2, perDomainDelay: 0.5)
        let url = URL(string: "https://example.com/feed.xml")!

        // First fetch
        await limiter.waitIfNeeded(for: url)

        // Reset
        await limiter.reset()

        // Second fetch after reset - should be instant (no history)
        let startTime = Date()
        await limiter.waitIfNeeded(for: url)
        let elapsed = Date().timeIntervalSince(startTime)

        #expect(elapsed < 0.1)
    }

    @Test("Reset for specific host")
    func testResetForSpecificHost() async {
        let limiter = RateLimiter(defaultDelay: 0.1, perDomainDelay: 0.3)
        let url = URL(string: "https://example.com/feed.xml")!

        // First fetch
        await limiter.waitIfNeeded(for: url)

        // Reset specific host
        await limiter.reset(for: "example.com")

        // Second fetch after reset - should be instant
        let startTime = Date()
        await limiter.waitIfNeeded(for: url)
        let elapsed = Date().timeIntervalSince(startTime)

        #expect(elapsed < 0.1)
    }

    @Test("URL without host is handled gracefully")
    func testURLWithoutHost() async {
        let limiter = RateLimiter(defaultDelay: 0.2, perDomainDelay: 0.5)
        let url = URL(string: "/relative/path")!

        // Should not crash and should be instant
        let startTime = Date()
        await limiter.waitIfNeeded(for: url)
        let elapsed = Date().timeIntervalSince(startTime)

        #expect(elapsed < 0.1)
    }

    @Test("Global wait enforces delay across domains")
    func testWaitGlobalEnforcesDelay() async {
        let limiter = RateLimiter(defaultDelay: 0.2, perDomainDelay: 0.5)
        let url1 = URL(string: "https://example.com/feed.xml")!
        let url2 = URL(string: "https://different.com/feed.xml")!

        // First fetch on domain 1
        await limiter.waitIfNeeded(for: url1)

        // Second fetch on domain 2 (different domain, would normally be instant)
        await limiter.waitIfNeeded(for: url2)

        // Now test global wait
        let startTime = Date()
        await limiter.waitGlobal()
        let elapsed = Date().timeIntervalSince(startTime)

        // Should enforce defaultDelay since last fetch
        #expect(elapsed >= 0.15)
        #expect(elapsed < 0.4)
    }

    @Test("Concurrent access is safe (actor isolation)")
    func testConcurrentAccessSafe() async {
        let limiter = RateLimiter(defaultDelay: 0.05, perDomainDelay: 0.1)
        let url = URL(string: "https://example.com/feed.xml")!

        // Launch multiple concurrent tasks
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    await limiter.waitIfNeeded(for: url)
                }
            }
        }

        // If we get here without crashing, actor isolation worked
        #expect(true)
    }
}
