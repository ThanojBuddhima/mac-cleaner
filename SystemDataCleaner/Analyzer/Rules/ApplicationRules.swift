import Foundation

struct ApplicationSupportRule: ClassificationRule {
    let category: StorageCategory = .applicationSupport
    func matches(url: URL) -> Bool {
        return url.path.contains("/Library/Application Support")
    }
}

struct ContainersRule: ClassificationRule {
    let category: StorageCategory = .containerData
    func matches(url: URL) -> Bool {
        let path = url.path
        return path.contains("/Library/Containers") || path.contains("/Library/Group Containers")
    }
}

struct AppDataSafetyRule: SafetyRule {
    func evaluate(url: URL, category: StorageCategory) -> (level: SafetyLevel, explanation: String)? {
        if category == .applicationSupport {
            return (.review, "Application Support files may contain user settings, save games, or required app assets. Do not delete unless you have uninstalled the application.")
        } else if category == .containerData {
            return (.review, "Sandboxed application data. Contains all local data for a Mac App Store application. Deleting acts like a reset for the app.")
        }
        return nil
    }
}
