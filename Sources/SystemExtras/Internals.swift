#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#elseif os(Windows)
import ucrt
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
    // TODO(compnerd) handle the error?
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
typealias system_stat_struct = _stat64i32
func system_stat(_ path: UnsafePointer<CInterop.PlatformChar>, _ result: inout _stat64i32) -> CInt {
  _wstat64i32(path, &result)
} 
#else
typealias system_stat_struct = stat
func system_stat(_ path: UnsafePointer<CInterop.PlatformChar>, _ result: inout stat) -> CInt {
  stat(path, &result)
}
#endif
