import Foundation

struct ScanProgress {
    let location: String
    let filesAnalyzed: Int
    let storageAnalyzed: Int64
    let progressRatio: Double? // 0.0 to 1.0 if known
}

enum ScanState: Equatable {
    case idle
    case preparing
    case scanning(ScanProgress)
    case completed
    case cancelled
    case failed(String)
    case permissionRequired([URL])
    
    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.preparing, .preparing), (.completed, .completed), (.cancelled, .cancelled):
            return true
        case (.scanning(let a), .scanning(let b)):
            return a.filesAnalyzed == b.filesAnalyzed && a.storageAnalyzed == b.storageAnalyzed
        case (.failed(let a), .failed(let b)):
            return a == b
        case (.permissionRequired(let a), .permissionRequired(let b)):
            return a == b
        default:
            return false
        }
    }
}
