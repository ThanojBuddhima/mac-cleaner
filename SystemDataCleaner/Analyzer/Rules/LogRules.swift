import Foundation

struct GlobalLogRule: ClassificationRule {
    let category: StorageCategory = .logs
    func matches(url: URL) -> Bool {
        return url.path.contains("/Library/Logs")
    }
}

struct LogSafetyRule: SafetyRule {
    func evaluate(url: URL, category: StorageCategory) -> (level: SafetyLevel, explanation: String)? {
        guard category == .logs else { return nil }
        
        if url.path.hasPrefix("/Library/Logs") {
            return (.review, "System-wide logs. Deleting these is generally safe but may remove troubleshooting information for all users.")
        } else {
            return (.safe, "Application logs. These can generally be safely removed to reclaim space.")
        }
    }
}
