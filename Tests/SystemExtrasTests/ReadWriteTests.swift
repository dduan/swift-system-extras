import SystemPackage
import SystemExtras
import XCTest

final class ReadWriteTests: XCTestCase {
    func testSimpleReadWriteBytes() throws {
        let bytes: [UInt8] = [1, 2, 3, 4, 1]
        try FilePath.withTemporaryDirectory { temp in
            let target = temp.appending("a")
            XCTAssertFalse(target.exists())
            try target.write(bytes)
            XCTAssert(target.exists())

            let readBytes = try target.readBytes()
            XCTAssertEqual(readBytes, bytes)
        }
    }

    func testSimpleReadWriteUTF8String() throws {
        let s = "Hello, System!"
        try FilePath.withTemporaryDirectory { temp in
            let target = temp.appending("a")
            XCTAssertFalse(target.exists())
            try target.write(utf8: s)
            XCTAssert(target.exists())

            let readString = try target.readUTF8String()
            XCTAssertEqual(readString, s)
        }
    }
}
