import SystemExtras
import SystemPackage
import XCTest

final class PermissionsTests: XCTestCase {
    func testSettingPermissions() throws {
        try FilePath.withTemporaryDirectory { temp in
            let file = temp.pushing("a")
            try file.write(utf8: "hello")
            let oldPermissions = try file.metadata().permissions
            XCTAssert(oldPermissions.contains(.ownerWrite))
            try file.set(oldPermissions.subtracting([.ownerWrite]))
            let newPermissions = try file.metadata().permissions
            XCTAssertFalse(newPermissions.contains(.ownerWrite))
        }
    }
}
