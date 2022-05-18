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
    public func directoryContent(recursive: Bool = false) -> DirectoryContent {
        DirectoryContent(of: self, recursive: recursive)
    }
}

public struct DirectoryContent: Sequence {
    let directory: FilePath
    let recursive: Bool

    public init(of directory: FilePath, recursive: Bool = false) {
        self.directory = directory
        self.recursive = recursive
    }

    public func makeIterator() -> DirectoryContentIterator {
        DirectoryContentIterator(queue: [directory], recursive: recursive)
    }
}

#if os(Windows)
public final class DirectoryContentIterator: IteratorProtocol {
    var queue: [FilePath]
    let recursive: Bool
    init(queue: [FilePath], recursive: Bool) {
        self.queue = queue
        self.recursive = recursive
    }

    deinit {
        if let handle = self.current?.handle {
            CloseHandle(handle)
        }
    }

    var current: (handle: UnsafeMutableRawPointer, path: FilePath)?
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
            if self.recursive {
                queue.append(path)
            }

            return(path, FileType(data: data))
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
}
#else
public final class DirectoryContentIterator: IteratorProtocol {
    var queue: [FilePath]
    let recursive: Bool

    init(queue: [FilePath], recursive: Bool) {
        self.queue = queue
        self.recursive = recursive
    }

    deinit {
        if let handle = self.current?.handle {
            closedir(handle)
        }
    }

#if os(macOS)
    var current: (handle: UnsafeMutablePointer<DIR>, path: FilePath)?
#else
    var current: (handle: OpaquePointer, path: FilePath)?
#endif
    public func next() -> (FilePath, FileType)? {
        if let (handle, currentPath) = self.current {
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

            let fileType = FileType(dirEntry: entry)
            let path = currentPath.appending(name)

            if recursive && fileType.isDirectory {
                queue.append(path)
            }

            return (path, fileType)
        } else {
            guard let nextPath = queue.first else {
                return nil
            }

            let handle = nextPath.withPlatformString { opendir($0) }
            let currentPath = queue.removeFirst()
            if let handle = handle {
                self.current = (handle: handle, path: currentPath)
            } else {
                self.current = nil
            }

            return next()
        }
    }
}
#endif
