import SystemPackage
import SystemExtras

func mkdir(_ args: [String]) {
    var args = Set(args)
    let makeParents: Bool
    if args.contains("-p") {
        makeParents = true
        args.remove("-p")
    } else {
        makeParents = false
    }

    do {
        try FilePath(args.first!).makeDirectory(withParents: makeParents)
    } catch {
        print(error)
    }
}

mkdir(Array(CommandLine.arguments.dropFirst()))
