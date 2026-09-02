import Foundation

protocol ClassificationRule {
    func matches(url: URL) -> Bool
    var category: StorageCategory { get }
}

protocol SafetyRule {
    func evaluate(url: URL, category: StorageCategory) -> (level: SafetyLevel, explanation: String)?
}
