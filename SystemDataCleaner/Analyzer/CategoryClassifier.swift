import Foundation

class CategoryClassifier {
    static let rules: [ClassificationRule] = [
        GlobalCacheRule(),
        XcodeDerivedDataRule(),
        XcodeArchivesRule(),
        CoreSimulatorRule(),
        GlobalLogRule(),
        ApplicationSupportRule(),
        ContainersRule()
    ]
    
    static func classify(url: URL) -> StorageCategory {
        for rule in rules {
            if rule.matches(url: url) {
                return rule.category
            }
        }
        return .unknown
    }
}
