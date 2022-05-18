import SystemPackage
import SystemExtras
import XCTest

final class DirectoryContentTests: XCTestCase {
    func testDirectoryContentSequence() throws {
        let thisFile: FilePath = #file
        XCTAssert(
            Set(
                DirectoryContent(of: thisFile.removingLastComponent(), recursive: true)
                    .map { $0.0 }
            ).contains(thisFile)
        )
    }

    func testDirectoryContentLooping() throws {
        let thisFile: FilePath = #file
        var foundThis = false

        for (path, type) in thisFile.removingLastComponent().directoryContent() {
            if path == thisFile, type.isFile {
                foundThis = true
            }
        }

        XCTAssertTrue(foundThis)
    }
}
