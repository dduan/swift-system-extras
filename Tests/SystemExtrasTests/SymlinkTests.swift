import SystemExtras
import SystemPackage
import XCTest

final class SymlinkTests: XCTestCase {
    func testMakingAndReadingSymlinksOfFile() throws {
        try FilePath.withTemporaryDirectory { temp in
            let aPath = temp.appending("a")
            let bPath = temp.appending("b")
            try aPath.write(utf8: "hello")

            XCTAssert(aPath.exists())
            XCTAssertFalse(bPath.exists())

            try aPath.makeSymlink(at: bPath)

            XCTAssert(try bPath.metadata().fileType.isSymlink)

            let bLink = try bPath.readSymlink()
            XCTAssertEqual(bLink, aPath)
        }
    }
}
