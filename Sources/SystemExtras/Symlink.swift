import CSystemExtras
import SystemPackage

#if os(Windows)
import WinSDK
extension FilePath {
    public func readSymlink() throws -> FilePath {
        // Warning: intense Windows/C wacky-ness ahead.
        //
        // DeviceIoControl returns multiple type of structs, depending on which one you ask for via one of
        // its parameters. Here, we ask for a FSCTL_GET_REPARSE_POINT. This returns an REPARSE_DATA_BUFFER:
        // https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/ns-ntifs-_reparse_data_buffer
        //
        // Because this guy is from a exotic place (NT kernel), we include a copy* of it as part of this
        // porject.
        //
        // REPARSE_DATA_BUFFER is a C struct that uses a few C features that Swift does not directly support.
        //
        // First of all, it has a union member with each option being structs with different content. We
        // include a copy of a struct with the union member flattened as direct members for each.
        //
        // Two of these options each has a "flexible array member". The last member of these structs is a
        // storage for the first element in an array.
        //
        // `DeviceIoControl` tells us the size of REPARSE_DATA_BUFFER, including the flexible array member.
        // To read data from this flexible array, we first skip the fixed potion of `REPARSE_DATA_BUFFER` from
        // the raw buffer returned by `DeviceIoControl`. Then, we cast the raw buffer to array whos element is
        // the same as the flexible array member's element (wchar_t). Since we know the first element is in
        // the fixed potion of `REPARSE_DATA_BUFFER`, we substract 1 step from the newly casted buffer, and
        // read its content from there.
        //
        // Each of the union member in `REPARSE_DATA_BUFFER` also contains content size of the flexible array.
        // We use that information as well when reading from it.
        try withHandle(
            access: 0,
            diposition: OPEN_EXISTING,
            attributes: FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS
        ) { handle in
            let data = try ContiguousArray<CChar>(unsafeUninitializedCapacity: 16 * 1024) { buffer, count in
                var size: DWORD = 0
                if !DeviceIoControl(
                    handle,
                    FSCTL_GET_REPARSE_POINT,
                    nil,
                    0,
                    buffer.baseAddress,
                    DWORD(buffer.count),
                    &size,
                    nil
                ) {
                    throw Errno(rawValue: -1)
                }
                count = Int(size)
            }

            return try withUnsafePointer(to: data) {
                try $0.withMemoryRebound(to: [ReparseDataBuffer].self, capacity: 1) { reparseDataBuffer -> Path in
                    guard let reparseData = reparseDataBuffer.pointee.first else {
                        throw Errno(rawValue: -1)
                    }

                    let nameStartingPoint: Int
                    let nameLength = Int(reparseData.substituteNameLength) / MemoryLayout<WindowsEncodingUnit>.stride
                    if reparseData.reparseTag == IO_REPARSE_TAG_SYMLINK {
                        nameStartingPoint = (MemoryLayout<SymbolicLinkReparseBuffer>.stride - 4) / 2
                    } else if reparseData.reparseTag == IO_REPARSE_TAG_MOUNT_POINT {
                        nameStartingPoint = (MemoryLayout<MountPointReparseBuffer>.stride - 4) / 2
                    } else {
                        throw Errno(rawValue: -1)
                    }

                    return withUnsafePointer(to: data) {
                        $0.withMemoryRebound(to: [UInt16].self, capacity: data.count / 2) { wideData in
                            FilePath(platfromString: Array(wideData.pointee[nameStartingPoint ..< (nameStartingPoint + nameLength)]) + [0])
                        }
                    }
                }
            }
        }
    }
}
#else // os(Windows)
#endif // os(Windows)
