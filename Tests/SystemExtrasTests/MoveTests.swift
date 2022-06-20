import SystemPackage
import XCTest

final class MoveTests: XCTestCase {
    func testMoveFile() throws {
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

    func testMoveEmptyDirectory() throws {
        try FilePath.withTemporaryDirectory { temp in
            let aPath = temp.appending("a")
            let bPath = temp.appending("b")
            try aPath.makeDirectory()

            XCTAssert(aPath.exists())
            XCTAssertFalse(bPath.exists())

            try aPath.move(to: bPath)

            XCTAssertFalse(aPath.exists())
            XCTAssert(bPath.exists())

            XCTAssert(try bPath.metadata().fileType.isDirectory)
        }
    }

    func testMoveDirectory() throws {
        let expectedContent = "Hello"
        try FilePath.withTemporaryDirectory { temp in
            let aDirectoryPath = temp.appending("a")
            let bDirectoryPath = temp.appending("b")
            let cInAPath = aDirectoryPath.appending("c")
            let cInBPath = bDirectoryPath.appending("c")

            try aDirectoryPath.makeDirectory()
            try cInAPath.write(utf8: expectedContent)

            XCTAssert(aDirectoryPath.exists())
            XCTAssert(cInAPath.exists())
            XCTAssertFalse(bDirectoryPath.exists())

            try aDirectoryPath.move(to: bDirectoryPath)

            XCTAssertFalse(aDirectoryPath.exists())
            XCTAssertFalse(cInAPath.exists())
            XCTAssert(bDirectoryPath.exists())
            XCTAssert(cInBPath.exists())

            XCTAssert(try bDirectoryPath.metadata().fileType.isDirectory)
            let content = try cInBPath.readUTF8String()
            XCTAssertEqual(content, expectedContent)
        }
    }
}
