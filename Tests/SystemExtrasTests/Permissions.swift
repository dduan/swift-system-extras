import SystemExtras
import SystemPackage
import XCTest

final class PermissionsTests: XCTestCase {
#if os(Windows)
    func testSettingPermissions() throws {
        try FilePath.withTemporaryDirectory { temp in
            let file = temp.pushing("a")
            try file.write(utf8: "hello")
            let oldPermissions = try file.metadata().permissions as! WindowsAttributes
            XCTAssertFalse(oldPermissions.contains(.readOnly))
            try file.set(oldPermissions.union([.readOnly]))
            let newPermissions = try file.metadata().permissions as! WindowsAttributes
            XCTAssert(newPermissions.contains(.readOnly))
        }
    }
#else
    func testSettingPermissions() throws {
        try FilePath.withTemporaryDirectory { temp in
            let file = temp.pushing("a")
            try file.write(utf8: "hello")
            let oldPermissions = try file.metadata().permissions as! FilePermissions
            XCTAssert(oldPermissions.contains(.ownerWrite))
            try file.set(oldPermissions.subtracting([.ownerWrite]))
            let newPermissions = try file.metadata().permissions as! FilePermissions
            XCTAssertFalse(newPermissions.contains(.ownerWrite))
        }
    }
#endif // !os(Windows)
}
