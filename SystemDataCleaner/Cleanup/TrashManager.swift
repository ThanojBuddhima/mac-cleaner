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
            // If trash item fails on a different volume, NSWorkspace might be used, 
            // but FileManager.trashItem is preferred for macOS 10.8+
            throw error
        }
    }
    
    static func deletePermanently(url: URL) async throws {
        try fileManager.removeItem(at: url)
    }
}
