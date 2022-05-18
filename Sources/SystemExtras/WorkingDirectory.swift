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

    /// Set `self` as the current working directory (cwd), run `action`, and
    /// restore the original current working directory after `action` finishes.
    ///
    /// - Parameter action: A closure that runs with `self` being the current
    ///                     working directory.
    public func asWorkingDirectory(running action: @escaping () throws -> Void) throws {
        let currentDirectory = try FilePath.workingDirectory()
        try FilePath.setWorkingDirectory(self)
        try action()
        try FilePath.setWorkingDirectory(currentDirectory)
    }
}
