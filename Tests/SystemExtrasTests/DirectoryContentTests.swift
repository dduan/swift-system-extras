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

    func testRecursiveFollowingSymlink() throws {
        try FilePath.withTemporaryDirectory { _ in
            try FilePath("a").write(utf8: "")
            let b = FilePath("b")
            try b.makeDirectory()
            let be = b.appending("e")
            try be.makeDirectory()
            try be.appending("f").write(utf8: "")
            try b.appending("c").write(utf8: "")
            try b.makeSymlink(at: "d")
            let names = Set(FilePath(".").directoryContent(recursive: true, followSymlink: true).map(\.0))
            XCTAssertEqual(
                names,
                [
                    FilePath(".").appending("a"),
                    FilePath(".").appending("b"),
                    FilePath(".").appending("b").appending("c"),
                    FilePath(".").appending("b").appending("e"),
                    FilePath(".").appending("b").appending("e").appending("f"),
                    FilePath(".").appending("d"),
                    FilePath(".").appending("d").appending("c"),
                    FilePath(".").appending("d").appending("e"),
                    FilePath(".").appending("d").appending("e").appending("f"),
                ]
            )

        }
    }
}
