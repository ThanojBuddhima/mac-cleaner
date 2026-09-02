import Foundation
import AppKit

class TrashManager {
    static let fileManager = FileManager.default
    
    static func moveToTrash(url: URL) async throws -> URL? {
        var resultingURL: NSURL?
        do {
            try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
            return resultingURL as URL?
        } catch {
            // Some system folders (like ~/Library/Caches) cannot be moved to trash.
            // Try to move their contents instead.
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                var hasErrors = false
                for itemURL in contents {
                    var itemResultingURL: NSURL?
                    do {
                        try fileManager.trashItem(at: itemURL, resultingItemURL: &itemResultingURL)
                    } catch {
                        hasErrors = true
                        print("Failed to trash child item \(itemURL): \(error)")
                    }
                }
                
                // If we managed to process it without failing completely, return the url
                // We consider it a success even with partial errors (e.g. active cache files)
                return url
            }
            throw error
        }
    }
    
    static func deletePermanently(url: URL) async throws {
        do {
            try fileManager.removeItem(at: url)
        } catch {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                for itemURL in contents {
                    do {
                        try fileManager.removeItem(at: itemURL)
                    } catch {
                        print("Failed to permanently delete child item \(itemURL): \(error)")
                    }
                }
                return
            }
            throw error
        }
    }
}
