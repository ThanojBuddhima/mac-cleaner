import Foundation

enum ValidationError: Error {
    case doesNotExist
    case outsideApprovedScope
    case fileChanged(String)
    case protectedPath
    case notSelected
}

class PathValidator {
    static let fileManager = FileManager.default
    
    static func validate(item: StorageItem) -> Result<Void, ValidationError> {
        let url = item.path
        
        // 1. Path still exists
        if !fileManager.fileExists(atPath: url.path) {
            return .failure(.doesNotExist)
        }
        
        // 2. Not a protected path
        if ProtectedPaths.isProtected(url) {
            return .failure(.protectedPath)
        }
        
        // 3. TOCTOU: Check if file has changed significantly
        if let metadata = FileMetadataReader.metadata(for: url) {
            // Check size difference
            let sizeDiff = abs(metadata.size - item.logicalSize)
            // Allow small differences for directories that might have tiny state changes,
            // but for files or large changes, it's safer to flag
            if sizeDiff > 10 * 1024 * 1024 { // 10 MB tolerance for directories
                return .failure(.fileChanged("Size changed by \(sizeDiff) bytes"))
            }
        }
        
        // 4. Outside approved scope (optional strict check)
        // For MVP, we trust the scanner roots, but can add explicit containment checks here.
        
        return .success(())
    }
}
