import Foundation

enum ScanMode {
    case quick
    case deep
}

struct ScanLocations {
    static let fileManager = FileManager.default
    static let homeURL = fileManager.homeDirectoryForCurrentUser
    
    static func locations(for mode: ScanMode) -> [URL] {
        var urls: [URL] = []
        
        let libraryURL = homeURL.appendingPathComponent("Library")
        
        // Quick scan targets high-yield developer/cache directories
        urls.append(libraryURL.appendingPathComponent("Caches"))
        urls.append(libraryURL.appendingPathComponent("Logs"))
        urls.append(libraryURL.appendingPathComponent("Developer"))
        urls.append(libraryURL.appendingPathComponent("Application Support"))
        urls.append(libraryURL.appendingPathComponent("Containers"))
        urls.append(libraryURL.appendingPathComponent("Group Containers"))
        urls.append(URL(fileURLWithPath: "/Library/Caches"))
        urls.append(URL(fileURLWithPath: "/Library/Logs"))
        urls.append(URL(fileURLWithPath: "/Library/Application Support"))
        
        if mode == .deep {
            urls.append(homeURL.appendingPathComponent("Downloads"))
            urls.append(homeURL.appendingPathComponent("Documents"))
            urls.append(URL(fileURLWithPath: "/System/Library/Caches"))
            urls.append(URL(fileURLWithPath: "/private/var/folders"))
            urls.append(URL(fileURLWithPath: "/private/var/log"))
        }
        
        return urls
    }
}
