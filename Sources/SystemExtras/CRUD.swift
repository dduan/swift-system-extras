import SystemPackage

extension FilePath {
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

    /// Delete content at `self`.
    /// Content of directory is deleted alongside the directory itself, unless specified otherwise.
    ///
    /// - Parameter recursive: `true` means content of non-empty directory will be deleted along
    ///                        with the directory itself.
    public func delete(recursive: Bool = false) throws {
        guard let meta = try? self.metadata() else {
            return // file doesn't exist
        }

        if meta.fileType.isDirectory {
            if recursive {
                for child in self.directoryContent() {
                    try child.0.delete(recursive: true)
                }
            }

            try self.withPlatformString { cString in
                if system_rmdir(cString) != 0 {
                    throw Errno(rawValue: system_errno)
                }
            }
        } else {
            try self.withPlatformString { cString in
                if system_unlink(cString) != 0 {
                    throw Errno(rawValue: system_errno)
                }
            }
        }
    }

    /// Move a file or direcotry to a new path. If the destination already exist, write over it.
    ///
    /// - Parameter newPath: New path for the content at the current path.
    public func move(to newPath: FilePath) throws {
        try self.withPlatformString { sourceCString in
            try newPath.withPlatformString { targetCString in
#if os(Windows)
                if !MoveFileW(sourceCString, targetCString) {
                    let _ = GetLastError()
                    // TODO: map WinAPI error to errno when Swift Systems does
                    throw Errno(rawValue: -1)
                }
#else
                if rename(sourceCString, targetCString) != 0 {
                    throw Errno(rawValue: system_errno)
                }
#endif
            }
        }
    }
}
