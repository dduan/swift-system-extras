import SystemPackage

extension FilePath {
    public static func workingDirectory() throws -> Self {
        if let buffer = system_getcwd() {
            return FilePath(platformString: buffer)
        }

        throw Errno(rawValue: system_errno)
    }

    public static func setWorkingDirectory(_ path: FilePath) throws {
        try path.withPlatformString { cString in
            if system_chdir(cString) != 0 {
                throw Errno(rawValue: system_errno)
            }
        }
    }
}
