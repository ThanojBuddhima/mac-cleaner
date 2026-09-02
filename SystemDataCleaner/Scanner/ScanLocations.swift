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
        
        if mode == .deep {
            urls.append(homeURL.appendingPathComponent("Downloads"))
            urls.append(homeURL.appendingPathComponent("Documents"))
            urls.append(URL(fileURLWithPath: "/Library/Caches"))
            // We avoid entire /private/var/folders to prevent excessive scanning and permission issues without FDA,
            // but can include safe subpaths if needed later.
        }
        
        return urls
    }
}
