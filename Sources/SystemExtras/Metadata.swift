import SystemPackage

public struct FileMetadata {
  public let permissions: FilePermissions
  public let fileType: FileType
  public let size: Int
}

extension FilePath {
  public func metadata() throws -> FileMetadata {
    var status = system_stat_struct()
    try self.withPlatformString { cString in
        if system_stat(cString, &status) != 0 {
            throw Errno(rawValue: system_errno)
        }
    }

    let mode = CInterop.Mode(status.st_mode)
    let permissions = FilePermissions(rawValue: mode & 0o7777)
    let type = FileType(rawMode: mode)
    return FileMetadata(permissions: permissions, fileType: type, size: status.st_size)
  }

  /// Return `true` if path refers to an existing path.
  /// On some platforms, this function may return `false` if permission is not
  /// granted to retrieve metadata on the requested file, even if the path physically exists.
  ///
  /// - Returns: whether path refers to an existing path or an open file descriptor.
  public func exists() -> Bool {
    (try? self.metadata()) != nil
  }
}
