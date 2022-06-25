#if os(Windows)
import SystemPackage
import WinSDK
extension FilePath {
    func withHandle<Output>(access: Int32, diposition: Int32, attributes: Int32, run action: (HANDLE?) throws -> Output) throws -> Output {
        try self.withPlatformString { cString in
            let handle = CreateFileW(
                cString,
                DWORD(access),
                0,
                nil,
                DWORD(diposition),
                DWORD(attributes),
                nil
            )

            if handle == INVALID_HANDLE_VALUE {
                throw Errno(rawValue: -1)
            }

            defer {
                CloseHandle(handle)
            }

            return try action(handle)
        }
    }

    func windowsFinalName() throws -> Self {
        try withHandle(
            access: 0,
            diposition: OPEN_EXISTING,
            attributes: FILE_FLAG_BACKUP_SEMANTICS
        ) { handle in
            let platformString = try Array<CInterop.PlatformChar>(
                unsafeUninitializedCapacity: Int(MAX_PATH)
            ) { buffer, count in
                let length = Int(
                    GetFinalPathNameByHandleW(
                        handle,
                        buffer.baseAddress,
                        DWORD(MAX_PATH),
                        DWORD(FILE_NAME_OPENED)
                    )
                )

                if length == 0 {
                    throw Errno(rawValue: -1)
                }

                buffer[length] = 0
                count = length + 1
            }

            return FilePath(platformString: platformString)
        }
    }
}
#endif
