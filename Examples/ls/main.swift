import SystemExtras
import SystemPackage

extension String {
    func withLeftPad(_ n: Int) -> String {
        String(repeating: " ", count: max(0, n - count)) + self
    }
}

do {
    for child in FilePath(CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".").directoryContent() {
        var typeString: String = ""
        let meta = try child.0.metadata()

        typeString += meta.fileType.isDirectory ? "d" : "-"
        typeString += meta.fileType.isFile ? "f" : "-"
        typeString += meta.fileType.isSymlink ? "l" : "-"
        typeString += meta.permissions.isReadOnly ? "-" : "w"
        let sizeString = "\(meta.size)".withLeftPad(10)
        print("\(typeString) \(sizeString) \(child.0)")
    }
} catch {
    print(error)
}
