import Foundation

class SafetyAnalyzer {
    static let rules: [SafetyRule] = [
        CacheSafetyRule(),
        DeveloperSafetyRule(),
        LogSafetyRule(),
        AppDataSafetyRule()
    ]
    
    static func evaluate(url: URL, category: StorageCategory) -> (level: SafetyLevel, explanation: String?) {
        if ProtectedPaths.isProtected(url) {
            return (.dangerous, "This is a protected system location. Deleting files here can damage macOS and is strongly discouraged.")
        }
        
        for rule in rules {
            if let result = rule.evaluate(url: url, category: category) {
                return (result.level, result.explanation)
            }
        }
        
        if category == .unknown {
            return (.unknown, "We could not confidently determine whether this item is safe to remove.")
        }
        
        // Default for known category but no specific rule
        return (.review, "Review this item to ensure it is not needed before deleting.")
    }
}
