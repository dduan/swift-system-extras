#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#elseif os(Windows)
import ucrt
#else
#error("Unsupported Platform")
#endif

import System

public struct FileMetadata {
  public let permissions: FilePermissions
}

extension FilePath {
  public func metadata() throws -> FileMetadata {
    var status = stat()
    try self.withPlatformString { cString in
        if stat(cString, &status) != 0 {
            throw Errno(rawValue: errno)
        }
    }
    return FileMetadata(permissions: FilePermissions(rawValue: status.st_mode & 0o7777))
  }
}
