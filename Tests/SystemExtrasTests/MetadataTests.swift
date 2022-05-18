@testable import SystemExtras
import SystemPackage
import XCTest

final class MetadataTests: XCTestCase {
    func testPermissions() throws {
        let path: FilePath = #file
        XCTAssert(try path.metadata().permissions.contains(.ownerRead))
    }

    func testType() throws {
        let path: FilePath = #file
        XCTAssertTrue(try path.metadata().fileType.isFile)
        XCTAssertTrue(try path.removingLastComponent().metadata().fileType.isDirectory)
    }
}
