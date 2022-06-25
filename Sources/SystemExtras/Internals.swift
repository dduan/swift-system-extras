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

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
internal var system_errno: CInt {
  get { Darwin.errno }
  set { Darwin.errno = newValue }
}
#elseif os(Windows)
internal var system_errno: CInt {
  get {
    var value: CInt = 0
    _ = ucrt._get_errno(&value)
    return value
  }
  set {
    _ = ucrt._set_errno(newValue)
  }
}
#else
internal var system_errno: CInt {
  get { Glibc.errno }
  set { Glibc.errno = newValue }
}
#endif

#if os(Windows)
#else
typealias system_stat_struct = stat
func system_stat(_ path: UnsafePointer<CInterop.PlatformChar>, _ result: inout stat) -> CInt {
  stat(path, &result)
}
func system_lstat(_ path: UnsafePointer<CInterop.PlatformChar>, _ result: inout stat) -> CInt {
  lstat(path, &result)
}
#endif

#if os(Windows)
func system_getcwd() -> UnsafeMutablePointer<CInterop.PlatformChar>? {
    _wgetcwd(nil, 0)
}

func system_chdir(_ path: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    _wchdir(path)
}
#else
func system_getcwd() -> UnsafeMutablePointer<CInterop.PlatformChar>? {
    getcwd(nil, 0)
}
func system_chdir(_ path: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    chdir(path)
}
#endif

#if os(Windows)
func system_mkdir(_ path: UnsafePointer<CInterop.PlatformChar>, _ mode: CInterop.Mode) -> CInt {
    _wmkdir(path)
}
#else
func system_mkdir(_ path: UnsafePointer<CInterop.PlatformChar>, _ mode: CInterop.Mode) -> CInt {
    mkdir(path, mode)
}
#endif

#if os(Windows)
func system_getenv(_ name: UnsafePointer<CInterop.PlatformChar>) -> UnsafeMutablePointer<CInterop.PlatformChar>? {
    _wgetenv(name)
}
#else
func system_getenv(_ name: UnsafePointer<CInterop.PlatformChar>) -> UnsafeMutablePointer<CInterop.PlatformChar>? {
    getenv(name)
}
#endif

#if os(Windows)
func system_rmdir(_ path: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    _wrmdir(path)
}
#else
func system_rmdir(_ path: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    rmdir(path)
}
#endif

#if os(Windows)
func system_unlink(_ path: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    _wunlink(path)
}
#else
func system_unlink(_ path: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    unlink(path)
}
#endif

#if os(Windows)
#else
func system_chmod(_ path: UnsafePointer<CInterop.PlatformChar>, _ mode: CInterop.Mode) -> CInt {
    chmod(path, mode)
}
#endif

#if os(Windows)
#else
enum Constants {
    static let maxPathLength = Int(PATH_MAX)
}

func system_readlink(_ path: UnsafePointer<CInterop.PlatformChar>, _ buffer: UnsafeMutablePointer<CInterop.PlatformChar>, _ size: Int) -> Int {
    readlink(path, buffer, size)
}

func system_symlink(_ source: UnsafePointer<CInterop.PlatformChar>, _ target: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    symlink(source, target)
}
#endif

#if os(Windows)
func system_rename(_ source: UnsafePointer<CInterop.PlatformChar>, _ target: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    if !MoveFileW(source, target) {
        let _ = GetLastError()
        // TODO: map WinAPI error to errno when Swift Systems does
        return -1
    }

    return 0
}
#else
func system_rename(_ source: UnsafePointer<CInterop.PlatformChar>, _ target: UnsafePointer<CInterop.PlatformChar>) -> CInt {
    rename(source, target)
}
#endif
