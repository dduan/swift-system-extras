import SystemPackage
import SystemExtras
import XCTest

final class ExistsTests: XCTestCase {
    func testFileAndDirectoryExists() throws {
        let file: FilePath = #file
        XCTAssertTrue(file.exists())
        XCTAssertTrue(file.removingLastComponent().exists())
        XCTAssertFalse(file.appending("IDontExist").exists())
    }
}
