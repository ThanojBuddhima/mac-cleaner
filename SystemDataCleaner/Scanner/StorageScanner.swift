import Foundation

class StorageScanner {
    private var currentTask: Task<Void, Error>?
    
    // We can use a callback or AsyncStream for progress. Let's use a callback for simplicity.
    func scan(mode: ScanMode,
              onProgress: @escaping (ScanProgress) -> Void,
              onComplete: @escaping ([StorageItem]) -> Void,
              onError: @escaping (Error) -> Void) {
        
        cancel()
        
        currentTask = Task {
            do {
                let locations = ScanLocations.locations(for: mode)
                var allItems: [StorageItem] = []
                
                var totalFiles = 0
                var totalStorage: Int64 = 0
                
                for location in locations {
                    try Task.checkCancellation()
                    
                    onProgress(ScanProgress(location: location.path, filesAnalyzed: totalFiles, storageAnalyzed: totalStorage, progressRatio: nil))
                    
                    let aggregator = ScanAggregator(rootURL: location)
                    
                    try await DirectoryScanner.scan(url: location, aggregator: aggregator) { files, storage in
                        // We update the overall progress
                        onProgress(ScanProgress(location: location.path, filesAnalyzed: totalFiles + files, storageAnalyzed: totalStorage + storage, progressRatio: nil))
                    }
                    
                    totalFiles += aggregator.rootNode.fileCount
                    totalStorage += aggregator.rootNode.size
                    
                    // Convert Node to StorageItem (Classification will be added in Phase 3)
                    if let item = convert(node: aggregator.rootNode) {
                        allItems.append(item)
                    }
                }
                
                try Task.checkCancellation()
                onComplete(allItems)
                
            } catch is CancellationError {
                // Expected when cancelled
            } catch {
                onError(error)
            }
        }
    }
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    private func convert(node: ScanAggregator.Node) -> StorageItem? {
        // We skip empty directories at the root to avoid clutter
        if node.size == 0 && node.fileCount == 0 { return nil }
        
        var children: [StorageItem] = []
        for (_, childNode) in node.children {
            if let childItem = convert(node: childNode) {
                children.append(childItem)
            }
        }
        
        let category = CategoryClassifier.classify(url: node.url)
        let safetyInfo = SafetyAnalyzer.evaluate(url: node.url, category: category)
        
        return StorageItem(
            name: node.name,
            path: node.url,
            isDirectory: node.isDirectory,
            logicalSize: node.size,
            physicalSize: node.physicalSize,
            modifiedDate: node.modifiedDate,
            category: category,
            safetyLevel: safetyInfo.level,
            isDeletable: !ProtectedPaths.isProtected(node.url),
            explanation: safetyInfo.explanation,
            children: children.isEmpty ? nil : children.sorted { $0.effectiveSize > $1.effectiveSize },
            fileCount: node.fileCount
        )
    }
}
