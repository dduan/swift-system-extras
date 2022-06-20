import SystemPackage

extension FilePath {
#if !os(Windows)
    public func set(posix permissions: FilePermissions) throws {
        try self.withPlatformString { cString in
            if system_chmod(cString, permissions.rawValue) != 0 {
                throw Errno(rawValue: system_errno)
            }
        }
    }
#endif // !os(Windows)
}
