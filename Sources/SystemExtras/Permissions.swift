import SystemPackage

extension FilePath {
    public func set(_ permissions: FilePermissions) throws {
        try self.withPlatformString { cString in
            if system_chmod(cString, permissions.rawValue) != 0 {
                throw Errno(rawValue: system_errno)
            }
        }
    }
}
