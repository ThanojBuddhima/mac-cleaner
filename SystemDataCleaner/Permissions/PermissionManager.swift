import Foundation
import AppKit

class PermissionManager {
    static let shared = PermissionManager()
    
    // We can use an environment value or shared object in SwiftUI to show the FDA prompt
    @Published var showsFDAPrompt = false
    @Published var permissionDeniedPaths: [URL] = []
    
    func recordPermissionDenied(url: URL) {
        if !permissionDeniedPaths.contains(url) {
            permissionDeniedPaths.append(url)
        }
        
        // If we hit enough permission errors or critical ones, we might prompt for FDA.
        if permissionDeniedPaths.count > 5 {
            DispatchQueue.main.async {
                self.showsFDAPrompt = true
            }
        }
    }
    
    func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}
