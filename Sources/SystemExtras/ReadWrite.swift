import SystemPackage

extension FilePath {
    @discardableResult
    func whileOpen<Result>(
        _ mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        retryOnInterrupt: Bool = true,
        run action: (FileDescriptor) throws -> Result) throws -> Result
    {
        let fd = try FileDescriptor.open(
            self,
            mode,
            options: options,
            permissions: permissions,
            retryOnInterrupt: retryOnInterrupt
        )
        let result = try action(fd)
        try fd.close()
        return result
    }
}

extension FilePath {
    /// Read from a normal file.
    ///
    /// - Returns: binary content of the normal file.
    public func readBytes(
        fromAbsoluteOffset offset: Int64 = 0
    ) throws -> [UInt8]
    {
        let meta = try self.metadata()
        guard meta.fileType.isFile else { // TODO: Deal with symlink?
            return []
        }

        let requestSize = meta.size - Int(offset)
        return try self.whileOpen(.readOnly) { fd in
            try Array(unsafeUninitializedCapacity: requestSize) { buffer, count in
                count = try fd.read(fromAbsoluteOffset: offset, into: UnsafeMutableRawBufferPointer(buffer))
            }
        }
    }

    /// Read string from a normal file.
    ///
    /// - Parameter encoding: The encoding to use to decode the file's content.
    ///
    /// - Returns: The file's content decoded using `encoding`.
    public func readString<Encoding>(as encoding: Encoding.Type) throws -> String
        where Encoding: _UnicodeEncoding
    {
        try readBytes().withUnsafeBytes { rawBytes in
            String(decoding: rawBytes.bindMemory(to: Encoding.CodeUnit.self), as: Encoding.self)
        }
    }

    /// Read string from a normal file decoded using UTF-8.
    ///
    /// - Returns: The file's content as a String.
    public func readUTF8String() throws -> String {
        try self.readString(as: UTF8.self)
    }


    public func write<Bytes>(
        _ bytes: Bytes,
        options: FileDescriptor.OpenOptions = [.create, .truncate],
        permissions: FilePermissions = [.ownerWrite, .ownerRead, .groupRead, .groupWrite, .otherRead]
    ) throws where Bytes: Sequence, Bytes.Element == UInt8 {
        try self.whileOpen(.writeOnly, options: options, permissions: permissions) { fd in
            try fd.writeAll(bytes)
        }
    }

    public func write(
        utf8 string: String,
        options: FileDescriptor.OpenOptions = [.create, .truncate],
        permissions: FilePermissions = [.ownerWrite, .ownerRead, .groupRead, .groupWrite, .otherRead]
    ) throws
    {
        try string.withCString { signedPtr in
            try signedPtr.withMemoryRebound(to: UInt8.self, capacity: 1) { unsignedPtr in
                let buffer: UnsafeBufferPointer<UInt8> = UnsafeBufferPointer(start: unsignedPtr, count: string.utf8.count)
                try self.write(buffer, options: options, permissions: permissions)
            }
        }
    }
}
