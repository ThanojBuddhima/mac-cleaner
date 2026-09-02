import Foundation

class DirectoryScanner {
    
    // Scan a single root location and populate an aggregator
    static func scan(url: URL, aggregator: ScanAggregator, onProgress: @escaping (Int, Int64) -> Void) async throws {
        let fileManager = FileManager.default
        
        let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(FileMetadataReader.resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants], // We don't want to dive into .app or .xcodeproj bundles
            errorHandler: { url, error in
                // Spec §22, §71: handle permission errors gracefully without crashing
                // We just log and skip
                return true // Return true to continue enumerating
            }
        )
        
        guard let enumerator = enumerator else { return }
        
        var filesAnalyzed = 0
        var storageAnalyzed: Int64 = 0
        var batchCount = 0
        
        for case let fileURL as URL in enumerator {
            // Spec §28: Support cancellation
            try Task.checkCancellation()
            
            guard let metadata = FileMetadataReader.metadata(for: fileURL) else { continue }
            
            // Spec §27: Skip symlinks recursively
            if metadata.isSymbolicLink {
                enumerator.skipDescendants()
                continue
            }
            
            aggregator.add(file: fileURL, metadata: metadata)
            
            filesAnalyzed += 1
            storageAnalyzed += metadata.size
            batchCount += 1
            
            if batchCount >= 1000 {
                onProgress(filesAnalyzed, storageAnalyzed)
                batchCount = 0
                // Yield to prevent blocking
                await Task.yield()
            }
        }
        
        onProgress(filesAnalyzed, storageAnalyzed)
    }
}
