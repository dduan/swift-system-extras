import SystemPackage

extension FilePath {
    /// Return `true` if path refers to an existing path.
    /// On some platforms, this function may return `false` if permission is not
    /// granted to retrieve metadata on the requested file, even if the path physically exists.
    ///
    /// - Returns: whether path refers to an existing path or an open file descriptor.
    public func exists() -> Bool {
        (try? self.metadata()) != nil
    }
}
