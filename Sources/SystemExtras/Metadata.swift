import SystemPackage

public struct FileMetadata {
  public let permissions: FilePermissions
}

extension FilePath {
  public func metadata() throws -> FileMetadata {
    var status = system_stat_struct()
    try self.withPlatformString { cString in
        if system_stat(cString, &status) != 0 {
            throw Errno(rawValue: system_errno)
        }
    }

    let permissions = FilePermissions(rawValue: CInterop.Mode(status.st_mode) & 0o7777)
    return FileMetadata(permissions: permissions)
  }
}
