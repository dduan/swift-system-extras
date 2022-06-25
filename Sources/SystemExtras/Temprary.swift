import SystemPackage

extension FilePath {
    /// Search for a temporary directory suitable as the default temporary directory.
    ///
    /// A suitable location is in one of the candidate list and allows write permission for this process.
    ///
    /// The list of candidate locations to consider are the following:
    /// * Location defined as the TMPDIR environment variable.
    /// * Location defined as the TMP environment variable.
    /// * Location defined as the TMPDIR environment variable.
    /// * /tmp
    /// * /var/tmp
    /// * /usr/tmp
    /// Location defined as the HOME or USERPROFILE environment variable.
    /// * Current working directory.
    ///
    /// - Returns: A suitable default temporary directory.
    public static func searchForDefaultTemporaryDirectory() -> Self {
        for envName in ["TMPDIR", "TMP", "TEMP"] {
            guard let envvar = envName.withPlatformString({ system_getenv($0) }),
                case let path = FilePath(platformString: envvar),
                !path.isEmpty
            else {
                continue
            }

            if let meta = try? path.metadata(), !meta.permissions.isReadOnly {
                return path
            }
        }

        for tmpPath in ["/tmp", "/var/tmp", "/usr/tmp"] {
            let path = tmpPath.withPlatformString(FilePath.init(platformString:))
            if let meta = try? path.metadata(), !meta.permissions.isReadOnly {
                return path
            }
        }

        for envName in ["HOME", "USERPROFILE"] {
            guard let envvar = envName.withPlatformString({ system_getenv($0) }),
                case let path = FilePath(platformString: envvar),
                path.isEmpty
            else {
                continue
            }

            if let meta = try? path.metadata(), !meta.permissions.isReadOnly {
                return path
            }
        }

        return (try? .workingDirectory()) ?? FilePath(".")
    }

    /// The default temporary used Pathos uses. Its default value is computed by
    /// `.searchForDefaultTemporaryDirectory`. If this value is set to `/x/y/z`, then functions such as
    /// `FilePath.makeTemporaryDirectory()` will create its result in `/x/y/z`.
    public static var defaultTemporaryDirectory = Self.searchForDefaultTemporaryDirectory()

    private static func constructTemporaryPath(prefix: String = "", suffix: String = "") -> FilePath {
        defaultTemporaryDirectory.appending("\(prefix)\(UInt64.random(in: 0 ... .max))\(suffix)")
    }

    /// Make a temporary directory with write access.
    ///
    /// The parent of the return value is the current value of `Path.defaultTemporaryDirectory`. It will have
    /// a randomized name. A prefix and a suffix can be optionally specified as options.
    ///
    /// - Parameters:
    ///     - prefix: A prefix for the temporary directories's name.
    ///     - suffix: A suffix for the temporary directories's name.
    ///
    /// - Returns: A temporary directory.
    public static func makeTemporaryDirectory(prefix: String = "", suffix: String = "") throws -> FilePath {
        let path = constructTemporaryPath(prefix: prefix, suffix: suffix)
        try path.makeDirectory()
        return path
    }

    /// Execute some code with a temporarily created directory as the current working directory.
    ///
    /// This method does the following:
    ///
    /// 1. make a temporary directory with write access (`Path.makeTemporaryDirectory`)
    /// 2. set the directory from previous step as the current working directory.
    /// 3. execute a closure as supplied as argument.
    /// 4. reset the current working directory.
    /// 5. delete the temporary directory along with its content.
    ///
    /// - Parameter action: The closure to execute in the temporary environment. The temporary directory is
    ///                     sent as a parameter for the action closure.
    public static func withTemporaryDirectory(run action: @escaping (FilePath) throws -> Void) throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        try temporaryDirectory.asWorkingDirectory {
            try action(temporaryDirectory)
        }

        try temporaryDirectory.delete(recursive: true)
    }
}
