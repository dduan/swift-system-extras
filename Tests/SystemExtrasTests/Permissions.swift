import SystemExtras
import SystemPackage
import XCTest

final class PermissionsTests: XCTestCase {
    @available(macOS 12, *)
    func testSettingPermissions() throws {
        try FilePath.withTemporaryDirectory { temp in
            let file = temp.pushing("a")
            try file.write(utf8: "hello")
            let oldPermissions = try file.metadata().permissions
            XCTAssert(oldPermissions.contains(.ownerWrite))
            try file.set(posix: oldPermissions.subtracting([.ownerWrite]))
            let newPermissions = try file.metadata().permissions
            XCTAssertFalse(newPermissions.contains(.ownerWrite))
        }
    }
}
