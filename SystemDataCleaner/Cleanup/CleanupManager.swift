import Foundation

class CleanupManager {
    static let shared = CleanupManager()
    
    func execute(plan: CleanupPlan, onProgress: @escaping (Double) -> Void) async -> (CleanupResult, VerificationResult) {
        var processedSize: Int64 = 0
        var successfullyRemovedSize: Int64 = 0
        var skippedItems: [CleanupSkippedItem] = []
        
        let initialStorage = CleanupVerifier.getAvailableStorage() ?? 0
        
        let totalItems = plan.items.count
        
        for (index, item) in plan.items.enumerated() {
            // Validate
            let validation = PathValidator.validate(item: item)
            
            switch validation {
            case .success:
                do {
                    if plan.operationType == .trash {
                        _ = try await TrashManager.moveToTrash(url: item.path)
                    } else {
                        try await TrashManager.deletePermanently(url: item.path)
                    }
                    
                    if CleanupVerifier.verifyRemoval(of: item) {
                        successfullyRemovedSize += item.effectiveSize
                    } else {
                        skippedItems.append(CleanupSkippedItem(item: item, reason: "Item still exists after removal attempt"))
                    }
                    
                } catch {
                    skippedItems.append(CleanupSkippedItem(item: item, reason: error.localizedDescription))
                }
            case .failure(let error):
                let reason: String
                switch error {
                case .doesNotExist: reason = "File disappeared"
                case .fileChanged(let msg): reason = "File changed: \(msg)"
                case .protectedPath: reason = "Protected path"
                case .outsideApprovedScope: reason = "Outside scope"
                case .notSelected: reason = "Not selected"
                }
                skippedItems.append(CleanupSkippedItem(item: item, reason: reason))
            }
            
            processedSize += item.effectiveSize
            onProgress(Double(index + 1) / Double(totalItems))
        }
        
        let finalStorage = CleanupVerifier.getAvailableStorage() ?? 0
        let recovered = finalStorage - initialStorage
        
        let cResult = CleanupResult(
            processedSize: processedSize,
            successfullyRemovedSize: successfullyRemovedSize,
            skippedItems: skippedItems
        )
        let vResult = VerificationResult(
            beforeAvailableStorage: initialStorage,
            afterAvailableStorage: finalStorage,
            recoveredSize: recovered > 0 ? recovered : successfullyRemovedSize
        )
        
        return (cResult, vResult)
    }
}
