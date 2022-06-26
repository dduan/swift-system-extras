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

    var current: (handle: UnsafeMutableRawPointer, path: FilePath, logicalPath: FilePath)?
    public func next() -> (FilePath, FileType)? {
        func process(_ data: WIN32_FIND_DATAW) -> (FilePath, FileType)? {
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

            let path = self.current!.path.appending(name)
            let type = FileType(data)
            if self.recursive {
                queue.append((path, self.current!.logicalPath.appending(name)))
            }

            return(path, type)
        }

        var data = WIN32_FIND_DATAW()
        if let (handle, _) = self.current {
            if FindNextFileW(handle, &data) {
                if let result = process(data) {
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

            let handle = (nextPath.appending("*")).withPlatformString { FindFirstFileW($0, &data) }
            let currentPath = queue.removeFirst()
            if let handle = handle, handle != INVALID_HANDLE_VALUE {
                self.current = (handle, currentPath)
                if let result = process(data) {
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
    var current: (handle: UnsafeMutablePointer<DIR>, path: FilePath, logicalPath: FilePath)?
#else
    var current: (handle: OpaquePointer, path: FilePath, logicalPath: FilePath)?
#endif
    public func next() -> (FilePath, FileType)? {
        if let (handle, currentPath, logicalPath) = self.current {
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
            let path = currentPath.appending(name)

            if recursive {
                if fileType.isDirectory {
                    queue.append((path, logicalPath.appending(name)))
                } else if
                    fileType.isSymlink,
                    self.followSymlink,
                    let link = try? path.readSymlink(),
                    case let realPath = currentPath.pushing(link),
                    (try? realPath.metadata().fileType.isDirectory) == true
                {
                    queue.append((realPath, path))
                }
            }

            return (logicalPath.appending(name), fileType)
        } else {
            guard let nextPath = queue.first else {
                return nil
            }

            let handle = nextPath.0.withPlatformString { opendir($0) }
            let currentPath = queue.removeFirst()
            if let handle = handle {
                self.current = (handle: handle, path: currentPath.0, logicalPath: currentPath.1)
            } else {
                self.current = nil
            }

            return next()
        }
    }
#endif
}
