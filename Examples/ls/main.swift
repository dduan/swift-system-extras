import SystemExtras
import SystemPackage

extension String {
    func withLeftPad(_ n: Int) -> String {
        String(repeating: " ", count: max(0, n - count)) + self
    }
}

do {
    for child in FilePath(CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".").directoryContent() {
        var permissionString = ""
        let meta = try child.0.metadata()
        let permissions = meta.permissions
        permissionString += meta.fileType.isDirectory ? "d" : "-"
        permissionString += permissions.contains(.ownerRead) ? "r" : "-"
        permissionString += permissions.contains(.ownerWrite) ? "w" : "-"
        permissionString += permissions.contains(.ownerExecute) ? "x" : "-"
        permissionString += permissions.contains(.groupRead) ? "r" : "-"
        permissionString += permissions.contains(.groupWrite) ? "w" : "-"
        permissionString += permissions.contains(.groupExecute) ? "x" : "-"
        permissionString += permissions.contains(.otherRead) ? "r" : "-"
        permissionString += permissions.contains(.otherWrite) ? "w" : "-"
        permissionString += permissions.contains(.otherExecute) ? "x" : "-"
        let sizeString = "\(meta.size)".withLeftPad(10)
        print("\(permissionString) \(sizeString) \(child.0)")
    }
} catch {
    print(error)
}
