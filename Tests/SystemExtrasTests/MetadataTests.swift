@testable import SystemExtras
import SystemPackage
import XCTest

final class MetadataTests: XCTestCase {
    func testPermissions() throws {
        let path: FilePath = #file
        XCTAssert(try path.metadata().permissions.contains(.ownerRead))
    }
}
