import Foundation

enum CleanupOperationType {
    case trash
    case delete
}

struct CleanupPlan {
    let items: [StorageItem]
    let estimatedSize: Int64
    let overallSafety: SafetyLevel
    let operationType: CleanupOperationType
}

struct CleanupSkippedItem {
    let item: StorageItem
    let reason: String
}

struct CleanupResult {
    let processedSize: Int64
    let successfullyRemovedSize: Int64
    let skippedItems: [CleanupSkippedItem]
}

struct VerificationResult {
    let beforeAvailableStorage: Int64
    let afterAvailableStorage: Int64
    let recoveredSize: Int64
}
