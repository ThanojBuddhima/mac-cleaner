import Foundation

struct XcodeDerivedDataRule: ClassificationRule {
    let category: StorageCategory = .developerData
    func matches(url: URL) -> Bool {
        return url.path.contains("/Library/Developer/Xcode/DerivedData")
    }
}

struct XcodeArchivesRule: ClassificationRule {
    let category: StorageCategory = .developerData
    func matches(url: URL) -> Bool {
        return url.path.contains("/Library/Developer/Xcode/Archives")
    }
}

struct CoreSimulatorRule: ClassificationRule {
    let category: StorageCategory = .developerData
    func matches(url: URL) -> Bool {
        return url.path.contains("/Library/Developer/CoreSimulator")
    }
}

struct DeveloperSafetyRule: SafetyRule {
    func evaluate(url: URL, category: StorageCategory) -> (level: SafetyLevel, explanation: String)? {
        guard category == .developerData else { return nil }
        
        let path = url.path
        if path.contains("/DerivedData") {
            return (.safe, "Generated Xcode build artifacts. Can be safely deleted and will be regenerated on the next build.")
        } else if path.contains("/CoreSimulator") {
            return (.review, "iOS Simulator data. Contains apps and settings installed on simulators. Deleting will reset simulators.")
        } else if path.contains("/Archives") {
            return (.review, "Xcode archives used for distribution. Verify you don't need these specific builds before deleting.")
        }
        
        return (.review, "Developer tools data. Review before deleting to ensure no active projects depend on it.")
    }
}
