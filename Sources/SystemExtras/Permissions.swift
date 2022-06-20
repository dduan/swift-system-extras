import SystemPackage

extension FilePath {
    @available(macOS 12, *)
    public func set(posix permissions: FilePermissions) throws {
        try self.withPlatformString { cString in
            if system_chmod(cString, permissions.rawValue) != 0 {
                throw Errno(rawValue: system_errno)
            }
        }
    }
}
