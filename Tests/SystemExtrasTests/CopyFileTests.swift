import SystemExtras
import SystemPackage
import XCTest

final class CopyFileTests: XCTestCase {
    func testCopyingNormalFileToNewLocation() throws {
        try FilePath.withTemporaryDirectory { _ in
            let content = "xyyyzz"
            let sourceFile = FilePath("a")
            try sourceFile.write(utf8: content)
            let destinationFile = FilePath("b")
            try sourceFile.copyFile(to: destinationFile)
            XCTAssertEqual(try destinationFile.readUTF8String(), content)
        }
    }

    func testCopyingNormalFileToNewLocationFollowingSymlink() throws {
        try FilePath.withTemporaryDirectory { _ in
            let content = "aoesubaoesurcaoheu"
            let sourceFile = FilePath("a")
            try sourceFile.write(utf8: content)
            let link = FilePath("b")
            try sourceFile.makeSymlink(at: link)
            let destinationFile = FilePath("c")
            try link.copyFile(to: destinationFile)
            XCTAssertEqual(try destinationFile.readUTF8String(), content)
        }
    }

    func testCopyingSymlinkToNewLocation() throws {
        try FilePath.withTemporaryDirectory { _ in
            let content = "aoesubaoesurcaoheu"
            let sourceFile = FilePath("a")
            try sourceFile.write(utf8: content)
            let link = FilePath("b")
            try sourceFile.makeSymlink(at: link)
            let destinationFile = FilePath("c")
            try link.copyFile(to: destinationFile, followSymlink: false)
            XCTAssertEqual(try destinationFile.readSymlink(), sourceFile)
        }
    }

    func testCopyingToExistingLocationNotFailingExisting() throws {
        try FilePath.withTemporaryDirectory { _ in
            let sourceContent = "aaa"
            let sourceFile = FilePath("a")
            let destinationFile = FilePath("b")

            try sourceFile.write(utf8: sourceContent)
            try destinationFile.write(utf8: "bbb")

            try sourceFile.copyFile(to: destinationFile)
            XCTAssertEqual(try destinationFile.readUTF8String(), sourceContent)
        }
    }
}
