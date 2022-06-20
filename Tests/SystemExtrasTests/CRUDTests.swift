import SystemPackage
import XCTest

final class CRUDTests: XCTestCase {
    func testSimpleMove() throws {
        try FilePath.withTemporaryDirectory { temp in
            let expectedContent = "Hello"
            let aPath = temp.appending("a")
            let bPath = temp.appending("b")
            try aPath.write(utf8: expectedContent)

            XCTAssert(aPath.exists())
            XCTAssertFalse(bPath.exists())

            try aPath.move(to: bPath)

            XCTAssertFalse(aPath.exists())
            XCTAssert(bPath.exists())

            let content = try bPath.readUTF8String()
            XCTAssertEqual(content, expectedContent)
        }
    }
}
