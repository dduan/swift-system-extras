import SystemPackage
#if os(Windows)
import WinSDK
#endif

public struct FileMetadata {
    public let permissions: Permissions
    public let fileType: FileType
    public let size: Int64

#if os(Windows)
    init(_ data: WIN32_FIND_DATAW) {
        self.permissions = WindowsAttributes(rawValue: data.dwFileAttributes)
        self.fileType = FileType(data)
        self.size = Int64(UInt64(data.nFileSizeHigh) << 32 | UInt64(data.nFileSizeLow))
    }
#else
    init(_ status: system_stat_struct) {
        let mode = CInterop.Mode(status.st_mode)
        self.permissions = FilePermissions(rawValue: mode & 0o7777)
        self.fileType = FileType(mode)
#if os(Linux)
        self.size = Int64(status.st_size)
#else
        self.size = Int64(status.st_size)
#endif
    }
#endif
}

extension FilePath {
#if os(Windows)
    public func metadata(followSymlink: Bool = false) throws -> FileMetadata {
        let path = try followSymlink ? self.windowsFinalName() : self
        var data = WIN32_FIND_DATAW()
        try path.withPlatformString { cString in
            let handle = FindFirstFileW(cString, &data)
            if handle == INVALID_HANDLE_VALUE {
                // TODO: Map windows error to errno
                throw Errno(rawValue: -1)
            }

            CloseHandle(handle)
        }

        return FileMetadata(data)
    }
#else
    public func metadata(followSymlink: Bool = false) throws -> FileMetadata {
        var status = system_stat_struct()
        let anyStat = followSymlink ? system_stat : system_lstat
        try self.withPlatformString { cString in
            if anyStat(cString, &status) != 0 {
                throw Errno(rawValue: system_errno)
            }
        }

        return FileMetadata(status)
    }
#endif // os(Windows)

    /// Return `true` if path refers to an existing path.
    /// On some platforms, this function may return `false` if permission is not
    /// granted to retrieve metadata on the requested file, even if the path physically exists.
    ///
    /// - Parameter followSymlink: whether to follow symbolic links. If `true`, return `false` for
    ///                            broken symbolic links.
    ///
    /// - Returns: whether path refers to an existing path or an open file descriptor.
    public func exists(followSymlink: Bool = false) -> Bool {
        (try? self.metadata(followSymlink: followSymlink)) != nil
    }

#if os(Windows)
    /// Set new permissions for a file path.
    ///
    /// - Parameter permissions: The new file permission.
    public func set(_ permissions: Permissions) throws {
        guard let permissions = permissions as? WindowsAttributes else {
            fatalError("Attempting to set unix FilePermissions on Windows")
        }

        try self.withPlatformString { cString in
            if !SetFileAttributesW(cString, permissions.rawValue) {
                // TODO: Map windows error to errno
                throw Errno(rawValue: -1)
            }
        }
    }
#else
    /// Set new permissions for a file path.
    ///
    /// - Parameter permissions: The new file permission.
    public func set(_ permissions: Permissions) throws {
        guard let permissions = permissions as? FilePermissions else {
            fatalError("Attempting to set Windows Attributes on Unix")
        }

        try self.withPlatformString { cString in
            if system_chmod(cString, permissions.rawValue) != 0 {
                throw Errno(rawValue: system_errno)
            }
        }
    }
#endif // os(Windows)
}
