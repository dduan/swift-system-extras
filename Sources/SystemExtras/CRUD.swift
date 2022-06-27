import SystemPackage

let kCopyChunkSize = 16 * 1024

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

            // On Windows, we can't rely on the OS to think all children have been deleted at this point.
            // The only way to convince the os is to move the directory to another location first.
            let randomName = "\(UInt64.random(in: 0 ... .max))"
            let tempLocation = FilePath.defaultTemporaryDirectory.appending(randomName)
            try self.move(to: tempLocation)

            try tempLocation.withPlatformString { tempCString in
                if system_rmdir(tempCString) != 0 {
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
                if system_rename(sourceCString, targetCString) != 0 {
                    throw Errno(rawValue: system_errno)
                }
            }
        }
    }

    /// Copy a file or symlink from `self` to `destination`.
    ///
    /// - Parameters
    ///   - destination: The path to destination.
    ///   - followSymlink: If `self` is a symlink, `true` to copy the content it links to, `false` to copy the
    ///                    link itself.
    public func copyFile(to destination: FilePath, followSymlink: Bool = true) throws {
        let sourceMeta = try metadata()

        if !sourceMeta.fileType.isFile && !sourceMeta.fileType.isSymlink {
            throw Errno(rawValue: -1)
        }

        let isLink = sourceMeta.fileType.isSymlink
        if !followSymlink && isLink {
            try self.readSymlink().makeSymlink(at: destination)
            return
        }

        let source = isLink ? try self.readSymlink() : self
#if os(Windows)
        let attributes = try source.metadata().permissions as! WindowsAttributes

        source.withPlatformString { sourcePath in
            destination.withPlatformString { destinationPath in
                if !CopyFileW(
                    sourcePath,
                    destinationPath,
                    false
                ) {
                    throw Errno(rawValue: -1)
                }

                if !SetFileAttributesW(
                    destinationPath,
                    attributes.rawValue
                ) {
                    throw Errno(rawValue: -1)
                }

            }
        }
#else //os(Windows)
        let permissions = try source.metadata().permissions as! FilePermissions
        let sourceFD = try FileDescriptor.open(source, .readOnly)
        defer { try? sourceFD.close() }
        let destinationFD = try FileDescriptor.open(destination, .writeOnly, options: .create, permissions: permissions)
        defer { try? destinationFD.close() }
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: kCopyChunkSize, alignment: MemoryLayout<UInt8>.alignment)
        defer { buffer.deallocate() }
        defer {
            try? destination.set(permissions)
        }

        var position: Int64 = 0
        while true {
            let length = try sourceFD.read(fromAbsoluteOffset: position, into: buffer)
            if length == 0 {
                break
            }
            _ = try destinationFD.write(toAbsoluteOffset: position, .init(start: buffer.baseAddress, count: length))
            position = position + Int64(length)
        }
#endif //os(Windows)
    }
}
