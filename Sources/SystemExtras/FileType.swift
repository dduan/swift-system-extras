#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#elseif os(Windows)
import ucrt
import WinSDK
#else
#error("Unsupported Platform")
#endif

public struct FileType {
    public let isFile: Bool
    public let isDirectory: Bool
    public let isSymlink: Bool

#if os(Windows)
    init(data: WIN32_FIND_DATAW) {
        self.isDirectory = data.dwFileAttributes & UInt32(bitPattern: FILE_ATTRIBUTE_DIRECTORY) != 0
        self.isSymlink = data.dwFileAttributes & UInt32(bitPattern: FILE_ATTRIBUTE_REPARSE_POINT) != 0 && data.dwReserved0 & 0x2000_0000 != 0
        self.isFile = !isDirectory
    }
#else
    init(dirEntry: dirent) {
        let dType = dirEntry.d_type
        self.isFile = dType == DT_REG
        self.isDirectory = dType == DT_DIR
        self.isSymlink = dType == DT_LNK
    }
#endif
}
