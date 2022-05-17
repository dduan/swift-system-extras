import SystemPackage

extension FilePath {
    /// Return `true` if path refers to an existing path.
    /// On some platforms, this function may return `false` if permission is not
    /// granted to retrieve metadata on the requested file, even if the path physically exists.
    ///
    /// - Returns: whether path refers to an existing path or an open file descriptor.
    public func exists() -> Bool {
        (try? self.metadata()) != nil
    }

    /// Create a directory, and, optionally, any intermediate directories that leads to it, if they don't
    /// exist yet.
    ///
    /// - Parameters:
    ///   - withParents: Create intermediate directories as required. If this option is not specified,
    ///                          the full path prefix of each operand must already exist.
    ///                          On the other hand, with this option specified, no error will be reported if a
    ///                          directory given as an operand already exists.
    ///   - permissions: Permissions for the new directories. Has no effect on Windows.
    public func makeDirectory(
        withParents: Bool = false,
        permissions: FilePermissions = FilePermissions(rawValue: 0o755)
    ) throws {
        func _makeDirectory() throws {
            let outcome = self.withPlatformString { cString in
                system_mkdir(cString, permissions.rawValue)
            }

            if outcome != 0 {
                let error = Errno(rawValue: system_errno)
                if !exists() || error == .fileExists && !withParents {
                    throw error
                }
            }
        }

        if withParents && !self.exists() {
            try self.removingLastComponent().makeDirectory(withParents: true, permissions: permissions)
        }

        try _makeDirectory()
    }
}
