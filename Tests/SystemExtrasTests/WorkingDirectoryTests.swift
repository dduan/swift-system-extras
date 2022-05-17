import SystemExtras
import SystemPackage
import XCTest

final class WorkingDirectoryTests: XCTestCase {
    func testWorkingDirectory() throws {
        XCTAssert(!(try FilePath.workingDirectory()).isEmpty)
    }
}
