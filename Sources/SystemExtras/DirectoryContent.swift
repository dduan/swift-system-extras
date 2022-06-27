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

import SystemPackage

extension FilePath {
    public func directoryContent(recursive: Bool = false, followSymlink: Bool = false) -> DirectoryContent {
        DirectoryContent(of: self, recursive: recursive, followSymlink: followSymlink)
    }
}

public struct DirectoryContent: Sequence {
    let directory: FilePath
    let recursive: Bool
    let followSymlink: Bool

    public init(of directory: FilePath, recursive: Bool = false, followSymlink: Bool = false) {
        self.directory = directory
        self.recursive = recursive
        self.followSymlink = followSymlink
    }

    public func makeIterator() -> DirectoryContentIterator {
        DirectoryContentIterator(queue: [(directory, directory)], recursive: recursive, followSymlink: followSymlink)
    }
}

public final class DirectoryContentIterator: IteratorProtocol {
    var queue: [(FilePath, FilePath)] // (real, link)
    let recursive: Bool
    let followSymlink: Bool

    init(queue: [(FilePath, FilePath)], recursive: Bool, followSymlink: Bool) {
        self.queue = queue
        self.recursive = recursive
        self.followSymlink = followSymlink
    }

#if os(Windows)
    deinit {
        if let handle = self.current?.handle {
            CloseHandle(handle)
        }
    }

    var current: (handle: UnsafeMutableRawPointer, parent: FilePath, logicalParent: FilePath)?
    public func next() -> (FilePath, FileType)? {
        func process(_ data: WIN32_FIND_DATAW, _ currentParent: FilePath, _ logicalCurrentParent: FilePath) -> (FilePath, FileType)? {
            guard let name = withUnsafeBytes(of: data.cFileName, {
                $0.bindMemory(to: CInterop.PlatformChar.self)
                    .baseAddress
                    .map(String.init(platformString:))
            }),
                name != "..",
                name != ".",
                !name.isEmpty
            else {
                return nil
            }

            let path = currentParent.appending(name)
            let fileType = FileType(data)
            let logicalPath = logicalCurrentParent.appending(name)
            if self.recursive {
                if fileType.isSymlink,
                    fileType.isDirectory,
                    let link = try? path.readSymlink(),
                    case let realPath = currentParent.pushing(link),
                    (try? realPath.metadata().fileType.isDirectory) == true
                {
                    queue.append((realPath, path))
                } else if fileType.isDirectory {
                    queue.append((path, logicalPath))
                }
            }

            return (logicalPath, fileType)
        }

        var data = WIN32_FIND_DATAW()
        if let (handle, currentParent, logicalCurrentParent) = self.current {
            if FindNextFileW(handle, &data) {
                if let result = process(data, currentParent, logicalCurrentParent) {
                    return result
                }
            } else {
                CloseHandle(handle)
                self.current = nil
            }
        } else {
            guard let nextPath = queue.first else {
                return nil
            }

            let handle = (nextPath.0.appending("*")).withPlatformString { FindFirstFileW($0, &data) }
            let currentParent = queue.removeFirst()
            if let handle = handle, handle != INVALID_HANDLE_VALUE {
                self.current = (handle, currentParent.0, currentParent.1)
                if let result = process(data, currentParent.0, currentParent.1) {
                    return result
                }
            } else {
                self.current = nil
            }

        }
        return next()
    }
#else
    deinit {
        if let handle = self.current?.handle {
            closedir(handle)
        }
    }

#if os(macOS)
    var current: (handle: UnsafeMutablePointer<DIR>, parent: FilePath, logicalParent: FilePath)?
#else
    var current: (handle: OpaquePointer, parent: FilePath, logicalParent: FilePath)?
#endif
    public func next() -> (FilePath, FileType)? {
        if let (handle, currentParent, logicalCurrentParent) = self.current {
            guard let entry = readdir(handle)?.pointee else {
                closedir(handle)
                self.current = nil
                return next()
            }

            guard let name = withUnsafeBytes(of: entry.d_name, {
                $0.bindMemory(to: CInterop.PlatformChar.self)
                    .baseAddress
                    .map(String.init(platformString:))
            }),
                  name != "..",
                  name != "."
            else {
                return next()
            }

            let fileType = FileType(entry)
            let path = currentParent.appending(name)

            let logicalPath = logicalCurrentParent.appending(name)
            if recursive {
                if fileType.isDirectory {
                    queue.append((path, logicalPath))
                } else if
                    fileType.isSymlink,
                    self.followSymlink,
                    let link = try? path.readSymlink(),
                    case let realPath = currentParent.pushing(link),
                    (try? realPath.metadata().fileType.isDirectory) == true
                {
                    queue.append((realPath, path))
                }
            }

            return (logicalPath, fileType)
        } else {
            guard let nextPath = queue.first else {
                return nil
            }

            let handle = nextPath.0.withPlatformString { opendir($0) }
            let currentParent = queue.removeFirst()
            if let handle = handle {
                self.current = (handle, currentParent.0, currentParent.1)
            } else {
                self.current = nil
            }

            return next()
        }
    }
#endif
}
