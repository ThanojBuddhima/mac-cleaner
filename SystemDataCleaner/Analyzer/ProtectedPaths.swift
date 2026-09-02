import Foundation

struct ProtectedPaths {
    static let protectedPrefixes = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/etc",
        "/var/run",
        "/private/etc",
        "/private/var/run",
        "/Library/Apple",
        "/Library/StagedExtensions"
    ]
    
    static func isProtected(_ url: URL) -> Bool {
        let path = url.path
        for prefix in protectedPrefixes {
            if path == prefix || path.hasPrefix(prefix + "/") {
                return true
            }
        }
        return false
    }
}
