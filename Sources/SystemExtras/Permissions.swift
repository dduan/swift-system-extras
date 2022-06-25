import SystemPackage

/// OS agnostic permissions for a file path.
public protocol Permissions {
    /// Whether the file is read only. NOTE: setting this value does not change the permission of
    /// the path on file system. Use `Path.set(_:)` with the updated value to achieve that.
    var isReadOnly: Bool { get set }
}

extension FilePermissions: Permissions {
    public var isReadOnly: Bool {
        get {
            !contains(.ownerWrite)
        }

        set {
            if newValue {
                remove(.ownerWrite)
            } else {
                insert(.ownerWrite)
            }
        }
    }
}

