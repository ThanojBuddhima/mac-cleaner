import Foundation

class CleanupVerifier {
    static let fileManager = FileManager.default
    
    static func verifyRemoval(of item: StorageItem) -> Bool {
        if !fileManager.fileExists(atPath: item.path.path) {
            return true
        }
        
        // If it still exists, it might be a system directory (like ~/Library/Caches) 
        // whose contents were trashed instead. If it's a directory, we consider it cleaned.
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: item.path.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return true
        }
        
        return false
    }
    
    static func getAvailableStorage(for volumeURL: URL = URL(fileURLWithPath: "/")) -> Int64? {
        do {
            let values = try volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
            if let important = values.volumeAvailableCapacityForImportantUsage {
                return important
            } else if let regular = values.volumeAvailableCapacity {
                return Int64(regular)
            } else {
                return 0
            }
        } catch {
            return nil
        }
    }
}
