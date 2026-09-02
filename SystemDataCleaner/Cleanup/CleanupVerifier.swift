import Foundation

class CleanupVerifier {
    static let fileManager = FileManager.default
    
    static func verifyRemoval(of item: StorageItem) -> Bool {
        return !fileManager.fileExists(atPath: item.path.path)
    }
    
    static func getAvailableStorage(for volumeURL: URL = URL(fileURLWithPath: "/")) -> Int64? {
        do {
            let values = try volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
            return Int64(values.volumeAvailableCapacityForImportantUsage ?? values.volumeAvailableCapacity ?? 0)
        } catch {
            return nil
        }
    }
}
