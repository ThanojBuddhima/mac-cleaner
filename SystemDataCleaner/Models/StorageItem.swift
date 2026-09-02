import Foundation

struct StorageItem: Identifiable, Equatable {
    let id: UUID = UUID()
    let name: String
    let path: URL
    let isDirectory: Bool
    
    // File size information
    let logicalSize: Int64
    let physicalSize: Int64?
    
    // Size to show in UI (use physical if available, else logical)
    var effectiveSize: Int64 {
        return physicalSize ?? logicalSize
    }
    
    let modifiedDate: Date?
    
    // Classification
    let category: StorageCategory
    let safetyLevel: SafetyLevel
    let isDeletable: Bool
    let explanation: String?
    
    // Children if this is a directory
    var children: [StorageItem]?
    var fileCount: Int
    
    static func == (lhs: StorageItem, rhs: StorageItem) -> Bool {
        lhs.id == rhs.id
    }
}
