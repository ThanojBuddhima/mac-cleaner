import Foundation
import SwiftUI

enum CleanupState {
    case planning
    case cleaning(Double) // progress 0-1
    case verifying
    case complete(CleanupResult, VerificationResult)
    case failed(String)
}

@MainActor
class CleanupViewModel: ObservableObject {
    @Published var state: CleanupState = .planning
    @Published var plan: CleanupPlan?
    
    // We'll hook this up to CleanupManager in Phase 6
    func createPlan(for items: [StorageItem]) {
        let size = items.reduce(0) { $0 + $1.effectiveSize }
        
        let hasDangerous = items.contains { $0.safetyLevel == .dangerous }
        let hasReview = items.contains { $0.safetyLevel == .review }
        
        let overallSafety: SafetyLevel
        if hasDangerous {
            overallSafety = .dangerous
        } else if hasReview {
            overallSafety = .review
        } else {
            overallSafety = .safe
        }
        
        self.plan = CleanupPlan(
            items: items,
            estimatedSize: size,
            overallSafety: overallSafety,
            operationType: .trash
        )
    }
    
    func executeCleanup() {
        guard let plan = plan else { return }
        
        state = .cleaning(0.0)
        
        Task {
            let (cResult, vResult) = await CleanupManager.shared.execute(plan: plan) { progress in
                Task { @MainActor in
                    self.state = .cleaning(progress)
                }
            }
            
            self.state = .complete(cResult, vResult)
        }
    }
}
