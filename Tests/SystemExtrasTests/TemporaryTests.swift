import SystemPackage
import SystemExtras
import XCTest

final class DirectoryTests: XCTestCase {
    func testAsTemporaryDirectory() throws {
        try FilePath.withTemporaryDirectory { temp in
            XCTAssert(temp.exists())
            XCTAssert(try temp.metadata().fileType.isDirectory)
        }
    }

    func testTemporaryIsWritable() throws {
        try FilePath.withTemporaryDirectory { temp in
            let target = temp.appending("a")
            let fd = try FileDescriptor.open(target, .writeOnly, options: [.create], permissions: [.ownerWrite, .ownerRead])
            _ = try fd.closeAfter {
                try withUnsafeBytes(of: "hello") { content in
                    try fd.write(content)
                }
            }
            try XCTAssert(target.metadata().fileType.isFile)
        }
    }
}
