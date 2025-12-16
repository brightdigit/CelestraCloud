import Testing

@testable import CelestraKit

@Test("CelestraKit version is set")
func testVersion() async throws {
  #expect(CelestraKit.version == "1.0.0")
}

@Test("CelestraKit can be initialized")
func testInitialization() async throws {
  let kit = CelestraKit()
  #expect(kit != nil)
}
