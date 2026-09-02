import Foundation

class CleanupVerifier {
    static let fileManager = FileManager.default
    
    static func verifyRemoval(of item: StorageItem) -> Bool {
        return !fileManager.fileExists(atPath: item.path.path)
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
